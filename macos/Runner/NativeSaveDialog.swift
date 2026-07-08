import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

class NativeSaveDialogPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "vibepaint/native_save_dialog",
      binaryMessenger: registrar.messenger
    )
    let instance = NativeSaveDialogPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "showSaveDialog" else {
      result(FlutterMethodNotImplemented)
      return
    }

    let args = call.arguments as? [String: Any] ?? [:]
    let fileName = args["fileName"] as? String ?? "Untitled"
    let initialDirectory = args["initialDirectory"] as? String
    let dialogTitle = args["dialogTitle"] as? String ?? "Save As"

    let panel = NSSavePanel()
    panel.title = dialogTitle
    panel.canCreateDirectories = true
    panel.isExtensionHidden = false
    panel.showsTagField = false
    panel.allowsOtherFileTypes = false
    panel.nameFieldStringValue = fileName

    if let initialDirectory, !initialDirectory.isEmpty {
      panel.directoryURL = URL(fileURLWithPath: initialDirectory)
    }

    if #available(macOS 11.0, *) {
      panel.allowedContentTypes = [
        .png,
        .jpeg,
        .bmp,
        .gif,
        .webP,
      ]
    } else {
      panel.allowedFileTypes = ["png", "jpg", "jpeg", "bmp", "gif", "webp"]
    }

    if panel.runModal() == .OK, let url = panel.url {
      result(url.path)
    } else {
      result(nil)
    }
  }
}
