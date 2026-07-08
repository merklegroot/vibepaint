import Cocoa
import FlutterMacOS

/// AI Enhance via local MLX (mflux Python subprocess). No Apple Intelligence required.
final class AiEnhancePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var isBusy = false
  private var progressSink: FlutterEventSink?

  private static var userHome: URL {
    FileManager.default.homeDirectoryForCurrentUser
  }

  private static var vibePaintDir: URL {
    userHome.appendingPathComponent(".vibepaint", isDirectory: true)
  }

  private static var userScript: URL {
    vibePaintDir.appendingPathComponent("mlx/enhance_sketch.py")
  }

  private static func pythonURL() -> URL? {
    let bin = vibePaintDir.appendingPathComponent("mlx-venv/bin")
    for name in ["python3", "python"] {
      let url = bin.appendingPathComponent(name)
      if FileManager.default.isExecutableFile(atPath: url.path) {
        return url
      }
    }
    return nil
  }

  private static let defaultPrompt =
    "colorful finished illustration, polished digital art, vivid colors"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "vibepaint/ai_enhance",
      binaryMessenger: registrar.messenger
    )
    let instance = AiEnhancePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let events = FlutterEventChannel(
      name: "vibepaint/ai_enhance_progress",
      binaryMessenger: registrar.messenger
    )
    events.setStreamHandler(instance)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    progressSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    progressSink = nil
    return nil
  }

  private func emitProgress(
    _ message: String,
    phase: String = "working",
    bytesDone: Int? = nil,
    bytesTotal: Int? = nil,
    elapsedSeconds: Int? = nil
  ) {
    guard let sink = progressSink else { return }
    var payload: [String: Any] = [
      "message": message,
      "phase": phase,
    ]
    if let bytesDone {
      payload["bytes_done"] = bytesDone
    }
    if let bytesTotal {
      payload["bytes_total"] = bytesTotal
    }
    if let elapsedSeconds {
      payload["elapsed_seconds"] = elapsedSeconds
    }
    DispatchQueue.main.async {
      sink(payload)
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(Self.isMlxReady())
    case "prepare":
      result(["ok": true])
    case "enhance", "present":
      enhance(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func isMlxReady() -> Bool {
    guard let python = pythonURL(),
          resolveScriptURL() != nil else {
      return false
    }

    let process = Process()
    process.executableURL = python
    process.arguments = ["-c", "import mflux"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
      try process.run()
      process.waitUntilExit()
      return process.terminationStatus == 0
    } catch {
      return false
    }
  }

  private static func resolveScriptURL() -> URL? {
    let candidates: [URL?] = [
      Bundle.main.url(forResource: "enhance_sketch", withExtension: "py", subdirectory: "mlx"),
      Bundle.main.url(forResource: "enhance_sketch", withExtension: "py"),
      userScript,
    ]
    return candidates.compactMap { $0 }.first {
      FileManager.default.isReadableFile(atPath: $0.path)
    }
  }

  private func enhance(call: FlutterMethodCall, result: @escaping FlutterResult) {
    if isBusy {
      result(
        FlutterError(
          code: "busy",
          message: "An AI Enhance request is already in progress.",
          details: nil
        )
      )
      return
    }

    guard let python = Self.pythonURL() else {
      result(
        FlutterError(
          code: "mlx_not_ready",
          message:
            "MLX is not set up. Run scripts/mlx/setup.sh in the VibePaint repo (Apple Silicon, Python 3.10+).",
          details: nil
        )
      )
      return
    }

    guard Self.isMlxReady() else {
      result(
        FlutterError(
          code: "mlx_not_ready",
          message:
            "MLX is not set up. Run scripts/mlx/setup.sh in the VibePaint repo (Apple Silicon, Python 3.10+).",
          details: nil
        )
      )
      return
    }

    let args = call.arguments as? [String: Any] ?? [:]
    let flutterData = args["pngBytes"] as? FlutterStandardTypedData
    let prompt = (args["prompt"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

    guard let flutterData else {
      result(
        FlutterError(
          code: "invalid_args",
          message: "pngBytes is required",
          details: nil
        )
      )
      return
    }

    guard let scriptURL = Self.resolveScriptURL() else {
      result(
        FlutterError(
          code: "missing_script",
          message: "Could not find enhance_sketch.py. Run scripts/mlx/setup.sh.",
          details: nil
        )
      )
      return
    }

    isBusy = true
    emitProgress("Starting local MLX enhance…", phase: "start")

    DispatchQueue.global(qos: .userInitiated).async {
      defer { DispatchQueue.main.async { self.isBusy = false } }

      let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("vibepaint-mlx-\(UUID().uuidString)", isDirectory: true)
      let inputURL = tempDir.appendingPathComponent("input.png")
      let outputURL = tempDir.appendingPathComponent("output.png")

      do {
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try flutterData.data.write(to: inputURL)

        let process = Process()
        process.executableURL = python
        process.arguments = [
          scriptURL.path,
          "--input", inputURL.path,
          "--output", outputURL.path,
          "--prompt", prompt?.isEmpty == false ? prompt! : Self.defaultPrompt,
        ]
        // Force line-buffered progress JSON to reach us promptly.
        var env = ProcessInfo.processInfo.environment
        env["PYTHONUNBUFFERED"] = "1"
        env["HF_HOME"] = Self.userHome.appendingPathComponent(".vibepaint/huggingface").path
        process.environment = env

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        var logLines: [String] = []
        var finalPayload: [String: Any]?

        stdout.fileHandleForReading.readabilityHandler = { handle in
          let data = handle.availableData
          guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
          for rawLine in chunk.split(whereSeparator: \.isNewline) {
            let line = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            logLines.append(line)
            guard let payload = Self.parseJSONObject(line) else { continue }
            if payload["progress"] as? Bool == true,
               let message = payload["message"] as? String {
              let phase = payload["phase"] as? String ?? "working"
              let bytesDone = payload["bytes_done"] as? Int
              let bytesTotal = payload["bytes_total"] as? Int
              let elapsed = payload["elapsed_seconds"] as? Int
              self.emitProgress(
                message,
                phase: phase,
                bytesDone: bytesDone,
                bytesTotal: bytesTotal,
                elapsedSeconds: elapsed
              )
            } else if payload["ok"] != nil {
              finalPayload = payload
            }
          }
        }

        stderr.fileHandleForReading.readabilityHandler = { handle in
          let data = handle.availableData
          guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
          for rawLine in chunk.split(whereSeparator: \.isNewline) {
            let line = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            logLines.append(line)
            // Hugging Face / tqdm sometimes spam stderr; surface useful bits.
            if line.localizedCaseInsensitiveContains("download")
              || line.localizedCaseInsensitiveContains("fetching")
              || line.localizedCaseInsensitiveContains("loading") {
              self.emitProgress(line, phase: "download")
            }
          }
        }

        try process.run()
        process.waitUntilExit()

        stdout.fileHandleForReading.readabilityHandler = nil
        stderr.fileHandleForReading.readabilityHandler = nil

        // Drain any leftover bytes.
        if let leftover = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) {
          for rawLine in leftover.split(whereSeparator: \.isNewline) {
            let line = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            logLines.append(line)
            if let payload = Self.parseJSONObject(line), payload["ok"] != nil {
              finalPayload = payload
            }
          }
        }
        if let leftoverErr = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8),
           !leftoverErr.isEmpty {
          logLines.append(leftoverErr)
        }

        let outText = logLines.joined(separator: "\n")

        if process.terminationStatus != 0 {
          let message =
            (finalPayload?["message"] as? String)
            ?? Self.errorMessage(from: outText)
            ?? "MLX enhancement failed (exit \(process.terminationStatus))."
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "generation_failed",
                message: message,
                details: outText
              )
            )
          }
          try? FileManager.default.removeItem(at: tempDir)
          return
        }

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "missing_output",
                message: "MLX did not produce an output image.",
                details: outText
              )
            )
          }
          try? FileManager.default.removeItem(at: tempDir)
          return
        }

        self.emitProgress("Applying result…", phase: "done")
        let png = try Data(contentsOf: outputURL)
        let size = Self.pngDimensions(url: outputURL) ?? (width: 0, height: 0)

        DispatchQueue.main.async {
          result([
            "pngBytes": FlutterStandardTypedData(bytes: png),
            "width": size.width,
            "height": size.height,
          ] as [String: Any])
        }
        try? FileManager.default.removeItem(at: tempDir)
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "generation_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
        try? FileManager.default.removeItem(at: tempDir)
      }
    }
  }

  private static func parseJSONObject(_ line: String) -> [String: Any]? {
    guard let data = line.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return nil
    }
    return object
  }

  private static func errorMessage(from output: String) -> String? {
    for line in output.split(separator: "\n").reversed() {
      guard let payload = parseJSONObject(String(line)),
            let message = payload["message"] as? String,
            !message.isEmpty else {
        continue
      }
      return message
    }
    return nil
  }

  private static func pngDimensions(url: URL) -> (width: Int, height: Int)? {
    guard let image = NSImage(contentsOf: url) else { return nil }
    let size = image.size
    return (width: Int(size.width.rounded()), height: Int(size.height.rounded()))
  }
}
