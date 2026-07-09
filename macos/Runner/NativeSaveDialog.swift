import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

private struct ImageFormatOption {
  let label: String
  let ext: String
}

private final class FormatAccessoryHandler: NSObject {
  weak var panel: NSSavePanel?
  let formats: [ImageFormatOption]

  init(panel: NSSavePanel, formats: [ImageFormatOption]) {
    self.panel = panel
    self.formats = formats
    super.init()
  }

  @objc func formatDidChange(_ sender: NSPopUpButton) {
    guard let p = panel else { return }
    let idx = sender.indexOfSelectedItem
    if idx < 0 || idx >= formats.count { return }
    let chosenExt = formats[idx].ext

    var name = p.nameFieldStringValue
    let known: Set<String> = ["png", "jpg", "jpeg", "bmp", "gif", "webp", "ora"]
    if let dot = name.lastIndex(of: ".") {
      let after = name[name.index(after: dot)...].lowercased()
      if known.contains(after) {
        name = String(name[..<dot])
      }
    }
    p.nameFieldStringValue = name.hasSuffix("." + chosenExt) ? name : name + "." + chosenExt
  }
}

private func stem(from name: String) -> String {
  if let dot = name.lastIndex(of: ".") {
    return String(name[..<dot])
  }
  return name
}

private func initialFormatIndex(for suggested: String, formats: [ImageFormatOption]) -> Int {
  let lower = suggested.lowercased()
  if let dot = lower.lastIndex(of: ".") {
    let e = String(lower[lower.index(after: dot)...])
    for (i, f) in formats.enumerated() {
      if f.ext == e || (e == "jpeg" && f.ext == "jpg") {
        return i
      }
    }
  }
  return 0 // default to PNG
}

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
    let suggestedName = args["fileName"] as? String ?? "Untitled.png"
    let initialDirectory = args["initialDirectory"] as? String
    let dialogTitle = args["dialogTitle"] as? String ?? "Save As"

    let formats: [ImageFormatOption] = [
      ImageFormatOption(label: "PNG (*.png)", ext: "png"),
      ImageFormatOption(label: "JPEG (*.jpg)", ext: "jpg"),
      ImageFormatOption(label: "BMP (*.bmp)", ext: "bmp"),
      ImageFormatOption(label: "GIF (*.gif)", ext: "gif"),
      ImageFormatOption(label: "WebP (*.webp)", ext: "webp"),
      ImageFormatOption(label: "OpenRaster (*.ora)", ext: "ora"),
    ]

    let selectedIndex = initialFormatIndex(for: suggestedName, formats: formats)
    let selected = formats[selectedIndex]

    let panel = NSSavePanel()
    panel.title = dialogTitle
    panel.canCreateDirectories = true
    panel.isExtensionHidden = false
    panel.showsTagField = false
    panel.allowsOtherFileTypes = false

    if let initialDirectory, !initialDirectory.isEmpty {
      panel.directoryURL = URL(fileURLWithPath: initialDirectory)
    }

    // Prefill with the suggested name (includes preferred extension)
    let displayName = stem(from: suggestedName) + "." + selected.ext
    panel.nameFieldStringValue = displayName

    if #available(macOS 11.0, *) {
      panel.allowedContentTypes = formats.compactMap { format in
        UTType(filenameExtension: format.ext)
      }
    } else {
      panel.allowedFileTypes = formats.map { $0.ext == "jpg" ? "jpeg" : $0.ext }
    }

    // Build accessory view with explicit Format popup so user can select inside the dialog.
    let container = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 32))

    let label = NSTextField(labelWithString: "Format:")
    label.frame = NSRect(x: 8, y: 6, width: 58, height: 20)
    label.isEditable = false
    label.isBordered = false
    label.drawsBackground = false
    container.addSubview(label)

    let popup = NSPopUpButton(frame: NSRect(x: 68, y: 2, width: 260, height: 26), pullsDown: false)
    popup.addItems(withTitles: formats.map { $0.label })
    popup.selectItem(at: selectedIndex)

    let handler = FormatAccessoryHandler(panel: panel, formats: formats)
    popup.target = handler
    popup.action = #selector(FormatAccessoryHandler.formatDidChange(_:))

    container.addSubview(popup)

    panel.accessoryView = container

    if panel.runModal() == .OK, let url = panel.url {
      // The popup selection is authoritative for the format.
      let finalIndex = popup.indexOfSelectedItem
      let finalExt = (finalIndex >= 0 && finalIndex < formats.count)
        ? formats[finalIndex].ext
        : selected.ext

      let directory = url.deletingLastPathComponent().path
      var baseName = url.lastPathComponent
      let knownExts = ["png", "jpg", "jpeg", "bmp", "gif", "webp", "ora"]
      for e in knownExts {
        let suffix = "." + e
        if baseName.lowercased().hasSuffix(suffix) {
          baseName = String(baseName.dropLast(suffix.count))
          break
        }
      }
      let finalName = baseName.hasSuffix("." + finalExt) ? baseName : baseName + "." + finalExt
      let finalPath = (directory as NSString).appendingPathComponent(finalName)
      result(finalPath)
    } else {
      result(nil)
    }
  }
}
