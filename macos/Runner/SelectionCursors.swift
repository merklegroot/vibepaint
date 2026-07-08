import Cocoa
import FlutterMacOS

class SelectionCursorPlugin: NSObject, FlutterPlugin {
  private static var nwseCursor: NSCursor?
  private static var neswCursor: NSCursor?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "vibepaint/selection_cursor",
      binaryMessenger: registrar.messenger
    )
    let instance = SelectionCursorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "setCursor" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard let kind = call.arguments as? String else {
      result(
        FlutterError(
          code: "bad_args",
          message: "Expected cursor kind string",
          details: nil
        )
      )
      return
    }

    switch kind {
    case "nwse":
      Self.cachedNwseCursor().set()
    case "nesw":
      Self.cachedNeswCursor().set()
    default:
      NSCursor.arrow.set()
    }

    result(nil)
  }

  private static func cachedNwseCursor() -> NSCursor {
    if let cursor = nwseCursor {
      return cursor
    }
    let cursor = makeDiagonalCursor(nesw: false)
    nwseCursor = cursor
    return cursor
  }

  private static func cachedNeswCursor() -> NSCursor {
    if let cursor = neswCursor {
      return cursor
    }
    let cursor = makeDiagonalCursor(nesw: true)
    neswCursor = cursor
    return cursor
  }

  private static func makeDiagonalCursor(nesw: Bool) -> NSCursor {
    let size: CGFloat = 16
    let image = NSImage(size: NSSize(width: size, height: size), flipped: true) { _ in
      let shaft = NSBezierPath()
      shaft.lineCapStyle = .round
      shaft.lineJoinStyle = .round

      if nesw {
        shaft.move(to: NSPoint(x: 3, y: 13))
        shaft.line(to: NSPoint(x: 13, y: 3))
        addArrowHead(to: shaft, tip: NSPoint(x: 3, y: 13), awayFrom: NSPoint(x: 13, y: 3))
        addArrowHead(to: shaft, tip: NSPoint(x: 13, y: 3), awayFrom: NSPoint(x: 3, y: 13))
      } else {
        shaft.move(to: NSPoint(x: 3, y: 3))
        shaft.line(to: NSPoint(x: 13, y: 13))
        addArrowHead(to: shaft, tip: NSPoint(x: 3, y: 3), awayFrom: NSPoint(x: 13, y: 13))
        addArrowHead(to: shaft, tip: NSPoint(x: 13, y: 13), awayFrom: NSPoint(x: 3, y: 3))
      }

      NSColor.white.setStroke()
      shaft.lineWidth = 3
      shaft.stroke()

      NSColor.black.setStroke()
      shaft.lineWidth = 1
      shaft.stroke()

      return true
    }

    return NSCursor(image: image, hotSpot: NSPoint(x: 8, y: 8))
  }

  private static func addArrowHead(
    to path: NSBezierPath,
    tip: NSPoint,
    awayFrom other: NSPoint
  ) {
    let dx = tip.x - other.x
    let dy = tip.y - other.y
    let length = max(sqrt(dx * dx + dy * dy), 0.001)
    let ux = dx / length
    let uy = dy / length
    let wing = CGFloat(3.5)

    path.move(to: tip)
    path.line(to: NSPoint(x: tip.x - ux * wing - uy * wing * 0.65, y: tip.y - uy * wing + ux * wing * 0.65))
    path.move(to: tip)
    path.line(to: NSPoint(x: tip.x - ux * wing + uy * wing * 0.65, y: tip.y - uy * wing - ux * wing * 0.65))
  }
}
