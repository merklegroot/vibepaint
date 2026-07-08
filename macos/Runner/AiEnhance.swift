import Cocoa
import FlutterMacOS

#if canImport(ImagePlayground)
import ImagePlayground
#endif

/// Presents Apple Image Playground (macOS 15.1+ / Apple Intelligence) seeded with
/// the user's sketch, then returns the generated PNG to Flutter.
final class AiEnhancePlugin: NSObject, FlutterPlugin {
  private var pendingResult: FlutterResult?
  private var presenter: NSViewController?

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
      result(Self.isImagePlaygroundAvailable)
    case "present":
      present(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static var isImagePlaygroundAvailable: Bool {
    #if canImport(ImagePlayground)
    if #available(macOS 15.1, *) {
      return ImagePlaygroundViewController.isAvailable
    }
    #endif
    return false
  }

  private func present(call: FlutterMethodCall, result: @escaping FlutterResult) {
    #if canImport(ImagePlayground)
    if #available(macOS 15.1, *) {
      guard Self.isImagePlaygroundAvailable else {
        result(
          FlutterError(
            code: "unavailable",
            message:
              "Image Playground is not available. Requires Apple Intelligence on a supported Mac, with image generation enabled.",
            details: nil
          )
        )
        return
      }

      if pendingResult != nil {
        result(
          FlutterError(
            code: "busy",
            message: "An AI Enhance session is already in progress.",
            details: nil
          )
        )
        return
      }

      let args = call.arguments as? [String: Any] ?? [:]
      let flutterData = args["pngBytes"] as? FlutterStandardTypedData
      let prompt =
        (args["prompt"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        ?? "Polish and color this sketch into a clean finished illustration"

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

      guard let nsImage = NSImage(data: flutterData.data), nsImage.isValid else {
        result(
          FlutterError(
            code: "invalid_image",
            message: "Could not decode source sketch PNG",
            details: nil
          )
        )
        return
      }

      guard let host = Self.keyWindowViewController() else {
        result(
          FlutterError(
            code: "no_window",
            message: "No key window available to present Image Playground",
            details: nil
          )
        )
        return
      }

      let playground = ImagePlaygroundViewController()
      playground.concepts = [.text(prompt)]
      playground.sourceImage = nsImage
      playground.delegate = self

      pendingResult = result
      presenter = host
      host.presentAsSheet(playground)
      return
    }
    #endif

    result(
      FlutterError(
        code: "unsupported",
        message: "AI Enhance requires macOS 15.1 or later with Image Playground.",
        details: nil
      )
    )
  }

  private static func keyWindowViewController() -> NSViewController? {
    if let key = NSApp.keyWindow?.contentViewController {
      return key
    }
    return NSApp.windows.first(where: { $0.isVisible })?.contentViewController
  }

  private func finish(with payload: [String: Any]?) {
    let callback = pendingResult
    pendingResult = nil
    if let presenter, let sheet = presenter.presentedViewControllers?.last {
      presenter.dismiss(sheet)
    }
    presenter = nil
    callback?(payload)
  }

  private func finishError(code: String, message: String) {
    let callback = pendingResult
    pendingResult = nil
    if let presenter, let sheet = presenter.presentedViewControllers?.last {
      presenter.dismiss(sheet)
    }
    presenter = nil
    callback?(
      FlutterError(code: code, message: message, details: nil)
    )
  }
}

#if canImport(ImagePlayground)
@available(macOS 15.1, *)
extension AiEnhancePlugin: ImagePlaygroundViewController.Delegate {
  func imagePlaygroundViewController(
    _ imagePlaygroundViewController: ImagePlaygroundViewController,
    didCreateImageAt imageURL: URL
  ) {
    defer {
      // Image Playground writes a temporary file — copy bytes then clean up.
      try? FileManager.default.removeItem(at: imageURL)
    }

    guard let nsImage = NSImage(contentsOf: imageURL),
      let tiff = nsImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:])
    else {
      finishError(code: "read_failed", message: "Could not read the generated image")
      return
    }

    finish(
      with: [
        "pngBytes": FlutterStandardTypedData(bytes: png),
        "width": bitmap.pixelsWide,
        "height": bitmap.pixelsHigh,
      ]
    )
  }

  func imagePlaygroundViewControllerDidCancel(
    _ imagePlaygroundViewController: ImagePlaygroundViewController
  ) {
    finish(with: nil)
  }
}
#endif
