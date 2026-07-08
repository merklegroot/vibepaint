import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.setContentSize(NSSize(width: 1280, height: 720))
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)
    NativeSaveDialogPlugin.register(
      with: flutterViewController.registrar(forPlugin: "NativeSaveDialogPlugin")
    )
    SelectionCursorPlugin.register(
      with: flutterViewController.registrar(forPlugin: "SelectionCursorPlugin")
    )

    super.awakeFromNib()

    DispatchQueue.main.async {
      MenuSanitizer.stripInjectedItems()
    }
  }
}
