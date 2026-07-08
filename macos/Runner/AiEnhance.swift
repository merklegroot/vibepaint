import Cocoa
import FlutterMacOS

#if canImport(ImagePlayground)
import ImagePlayground
#endif

/// Silently enhances a sketch via Apple's ImageCreator (no Playground sheet).
final class AiEnhancePlugin: NSObject, FlutterPlugin {
  private var isBusy = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "vibepaint/ai_enhance",
      binaryMessenger: registrar.messenger
    )
    let instance = AiEnhancePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      Task { @MainActor in
        result(await Self.canCreateImages())
      }
    case "enhance", "present":
      enhance(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func canCreateImages() async -> Bool {
    #if canImport(ImagePlayground)
    if #available(macOS 15.4, *) {
      do {
        let creator = try await ImageCreator()
        return !creator.availableStyles.isEmpty
      } catch {
        return false
      }
    }
    #endif
    return false
  }

  private func enhance(call: FlutterMethodCall, result: @escaping FlutterResult) {
    #if canImport(ImagePlayground)
    if #available(macOS 15.4, *) {
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

      let args = call.arguments as? [String: Any] ?? [:]
      let flutterData = args["pngBytes"] as? FlutterStandardTypedData
      let prompt =
        (args["prompt"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        ?? "colorful finished illustration based on this drawing"

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

      guard let sketch = Self.prepareSketchCGImage(pngData: flutterData.data) else {
        result(
          FlutterError(
            code: "invalid_image",
            message: "Could not prepare the sketch for enhancement",
            details: nil
          )
        )
        return
      }

      isBusy = true
      Task { @MainActor in
        defer { self.isBusy = false }

        // ImageCreator refuses background / inactive apps.
        Self.bringAppToForeground()

        do {
          let created = try await Self.generate(sketch: sketch, prompt: prompt)
          guard let png = Self.pngData(from: created) else {
            result(
              FlutterError(
                code: "encode_failed",
                message: "Could not encode the generated image.",
                details: nil
              )
            )
            return
          }
          result(
            [
              "pngBytes": FlutterStandardTypedData(bytes: png),
              "width": created.width,
              "height": created.height,
            ] as [String: Any]
          )
        } catch {
          NSLog("VibePaint AI Enhance failed: \(error)")
          result(
            FlutterError(
              code: "creation_failed",
              message: Self.message(for: error),
              details: String(describing: error)
            )
          )
        }
      }
      return
    }
    #endif

    result(
      FlutterError(
        code: "unsupported",
        message: "AI Enhance requires macOS 15.4 or later with Apple Intelligence.",
        details: nil
      )
    )
  }

  private static func bringAppToForeground() {
    NSApp.activate(ignoringOtherApps: true)
    if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: \.isVisible) {
      window.makeKeyAndOrderFront(nil)
    }
  }

  #if canImport(ImagePlayground)
  @available(macOS 15.4, *)
  private static func generate(sketch: CGImage, prompt: String) async throws -> CGImage {
    let creator = try await ImageCreator()
    let styles = preferredStyles(from: creator.availableStyles)
    guard !styles.isEmpty else {
      throw ImageCreator.Error.unavailable
    }

    let imageConcept = ImagePlaygroundConcept.image(sketch)
    let shortPrompt = String(prompt.prefix(80))

    // Prefer conditioning on the sketch; fall back to text-only if needed.
    let conceptSets: [[ImagePlaygroundConcept]] = [
      [imageConcept, .text(shortPrompt)],
      [imageConcept, .text("illustration")],
      [imageConcept],
      [.text(shortPrompt)],
      [.text("cute colorful illustration")],
    ]

    var lastError: Error = ImageCreator.Error.creationFailed
    for style in styles {
      for concepts in conceptSets {
        do {
          NSLog(
            "VibePaint AI Enhance trying style=\(style.id) concepts=\(concepts.count)"
          )
          for try await image in creator.images(for: concepts, style: style, limit: 1) {
            return image.cgImage
          }
        } catch {
          lastError = error
          NSLog("VibePaint AI Enhance attempt failed: \(error)")
          if let creatorError = error as? ImageCreator.Error,
            creatorError == .backgroundCreationForbidden
              || creatorError == .unavailable
              || creatorError == .notSupported
          {
            throw error
          }
          continue
        }
      }
    }
    throw lastError
  }

  @available(macOS 15.4, *)
  private static func preferredStyles(
    from available: [ImagePlaygroundStyle]
  ) -> [ImagePlaygroundStyle] {
    // Animation is the most commonly documented reliable style.
    let preferred: [ImagePlaygroundStyle] = [.animation, .illustration, .sketch]
    let ordered = preferred.filter { available.contains($0) }
    return ordered.isEmpty ? available : ordered
  }
  #endif

  /// Flatten transparency onto white and pad to a size Image Playground accepts well.
  private static func prepareSketchCGImage(pngData: Data) -> CGImage? {
    guard let source = NSImage(data: pngData) else {
      return nil
    }

    let minSide: CGFloat = 512
    let maxSide: CGFloat = 1024
    let sourceSize = source.size
    guard sourceSize.width > 0, sourceSize.height > 0 else {
      return nil
    }

    let longest = max(sourceSize.width, sourceSize.height)
    let shortest = min(sourceSize.width, sourceSize.height)
    let scaleUp = shortest < minSide ? (minSide / shortest) : 1
    let scaleDown = longest > maxSide ? (maxSide / longest) : 1
    let scale = min(scaleUp, scaleDown)
    let drawSize = NSSize(
      width: max(1, (sourceSize.width * scale).rounded()),
      height: max(1, (sourceSize.height * scale).rounded())
    )
    let canvasSide = max(minSide, max(drawSize.width, drawSize.height))
    let canvasSize = NSSize(width: canvasSide, height: canvasSide)

    let canvas = NSImage(size: canvasSize)
    canvas.lockFocus()
    NSColor.white.setFill()
    NSRect(origin: .zero, size: canvasSize).fill()
    let origin = NSPoint(
      x: ((canvasSide - drawSize.width) / 2).rounded(.down),
      y: ((canvasSide - drawSize.height) / 2).rounded(.down)
    )
    source.draw(
      in: NSRect(origin: origin, size: drawSize),
      from: NSRect(origin: .zero, size: sourceSize),
      operation: .sourceOver,
      fraction: 1.0,
      respectFlipped: true,
      hints: [.interpolation: NSImageInterpolation.high]
    )
    canvas.unlockFocus()

    var proposed = CGRect(origin: .zero, size: canvasSize)
    return canvas.cgImage(forProposedRect: &proposed, context: nil, hints: nil)
  }

  private static func pngData(from image: CGImage) -> Data? {
    let rep = NSBitmapImageRep(cgImage: image)
    return rep.representation(using: .png, properties: [:])
  }

  private static func message(for error: Error) -> String {
    #if canImport(ImagePlayground)
    if #available(macOS 15.4, *), let creatorError = error as? ImageCreator.Error {
      switch creatorError {
      case .notSupported:
        return "AI Enhance isn’t supported on this Mac."
      case .unavailable:
        return
          "Apple Intelligence image generation isn’t available. Turn it on in System Settings → Apple Intelligence & Siri."
      case .creationCancelled:
        return "AI Enhance was cancelled."
      case .backgroundCreationForbidden:
        return "Keep VibePaint in the front and try AI Enhance again."
      case .unsupportedLanguage:
        return "AI Enhance needs a supported system language (match Siri and macOS language)."
      case .unsupportedInputImage:
        return "That sketch couldn’t be used as input. Try a larger or clearer drawing."
      case .creationFailed:
        return
          "Image generation failed. Keep VibePaint frontmost, confirm Apple Intelligence finished downloading, and try a clearer sketch."
      default:
        return creatorError.localizedDescription
      }
    }
    #endif
    return error.localizedDescription
  }
}
