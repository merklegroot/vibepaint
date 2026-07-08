import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationWillFinishLaunching(_ notification: Notification) {
    MenuSanitizer.disableSystemInjectedMenuItems()
    super.applicationWillFinishLaunching(notification)
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    MenuSanitizer.install()
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
