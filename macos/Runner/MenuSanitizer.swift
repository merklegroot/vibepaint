import Cocoa

private final class MenuSanitizerDelegate: NSObject, NSMenuDelegate {
  static let shared = MenuSanitizerDelegate()

  func menuWillOpen(_ menu: NSMenu) {
    MenuSanitizer.stripInjectedItems()
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    MenuSanitizer.stripInjectedItems()
  }
}

enum MenuSanitizer {
  private static var mainMenuObservation: NSKeyValueObservation?

  private static let unwantedTitlePrefixes = [
    "AutoFill",
    "Start Dictation",
    "Emoji & Symbols",
    "Emoji &amp; Symbols",
    "Writing Tools",
  ]

  private static let unwantedExactActionNames: Set<String> = [
    "startDictation:",
    "orderFrontCharacterPalette:",
    "insertCompletion:",
  ]

  /// Call before the nib loads so macOS never registers the injected items.
  static func disableSystemInjectedMenuItems() {
    let defaults = UserDefaults.standard
    defaults.set(true, forKey: "NSDisabledDictationMenuItem")
    defaults.set(true, forKey: "NSDisabledCharacterPaletteMenuItem")
    defaults.set(true, forKey: "NSDisabledAutoFillMenuItem")
  }

  static func install() {
    disableSystemInjectedMenuItems()

    NotificationCenter.default.addObserver(
      forName: NSMenu.didAddItemNotification,
      object: nil,
      queue: .main
    ) { _ in
      stripInjectedItems()
    }

    mainMenuObservation = NSApplication.shared.observe(
      \.mainMenu,
      options: [.new, .initial]
    ) { _, _ in
      stripInjectedItems()
    }

    stripInjectedItems()
  }

  static func stripInjectedItems() {
    guard let mainMenu = NSApplication.shared.mainMenu else {
      return
    }

    for topLevel in mainMenu.items {
      strip(menu: topLevel.submenu)
    }
  }

  private static func strip(menu: NSMenu?) {
    guard let menu else {
      return
    }

    menu.delegate = MenuSanitizerDelegate.shared
    menu.autoenablesItems = false

    for item in menu.items.reversed() {
      if shouldBlock(item) {
        menu.removeItem(item)
        continue
      }
      strip(menu: item.submenu)
    }
  }

  static func shouldBlock(_ item: NSMenuItem) -> Bool {
    if unwantedTitlePrefixes.contains(where: { item.title.hasPrefix($0) }) {
      return true
    }

    if let action = item.action {
      let name = NSStringFromSelector(action)
      if unwantedExactActionNames.contains(name) {
        return true
      }
      if name == "submenuAction:" &&
          unwantedTitlePrefixes.contains(where: { item.title.hasPrefix($0) }) {
        return true
      }
    }

    // macOS injects hidden service items into menus at runtime.
    if item.isHidden {
      if let action = item.action {
        let name = NSStringFromSelector(action)
        if name.contains("Dictation") ||
            name.contains("CharacterPalette") ||
            name.contains("insertCompletion") {
          return true
        }
      }
    }

    return false
  }
}
