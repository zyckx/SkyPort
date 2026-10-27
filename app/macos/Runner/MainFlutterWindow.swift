import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var hostChannel: FlutterMethodChannel?
  private var windowChannel: FlutterMethodChannel?
  private var closePending = false
  private var closeApproved = false
  private var lastState: [String: AnyHashable]?

  override func awakeFromNib() {
    // Forward process arguments (e.g. --kernel-smoke) like the other runners.
    let project = FlutterDartProject()
    project.dartEntrypointArguments = Array(CommandLine.arguments.dropFirst())
    let flutterViewController = FlutterViewController(project: project)
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 320, height: 480)

    // Flutter draws the title bar below the native traffic lights.
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    styleMask.insert(.fullSizeContentView)
    delegate = self

    let messenger = flutterViewController.engine.binaryMessenger
    hostChannel = FlutterMethodChannel(name: "skyport/host", binaryMessenger: messenger)
    let channel = FlutterMethodChannel(name: "skyport/window", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.handleWindowCall(call, result: result)
    }
    windowChannel = channel

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  private func handleWindowCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "configure":
      guard let arguments = call.arguments as? [String: Any],
            let title = arguments["title"] as? String,
            let dark = arguments["dark"] as? Bool else {
        result(FlutterError(code: "invalid_arguments",
                            message: "Expected a dark boolean and a title string.",
                            details: nil))
        return
      }
      self.title = title
      appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
      let state = windowState()
      lastState = state
      result(state)
    case "minimize":
      miniaturize(nil)
      result(nil)
    case "toggleMaximize":
      zoom(nil)
      result(nil)
    case "close":
      // Acceptance only: windowShouldClose still awaits skyport/host approval.
      performClose(nil)
      result(nil)
    case "startDrag":
      if let event = NSApp.currentEvent {
        performDrag(with: event)
      }
      result(nil)
    case "titlebarDoubleClick":
      // Honour System Settings > Desktop & Dock > double-click a title bar.
      switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
      case "Minimize":
        miniaturize(nil)
      case "None":
        break
      default:
        zoom(nil)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func windowState() -> [String: AnyHashable] {
    let fullScreen = styleMask.contains(.fullScreen)
    let titlebarHeight = fullScreen ? 0 : frame.height - contentLayoutRect.height
    let zoomButton = standardWindowButton(.zoomButton)
    let leadingInset = fullScreen ? 0 : (zoomButton?.frame.maxX ?? 0) + 12
    return [
      "maximized": isZoomed || fullScreen,
      "active": isKeyWindow,
      "maximizeHovered": false,
      "titlebarHeight": Double(titlebarHeight),
      "leadingInset": Double(leadingInset),
    ]
  }

  private func publishWindowState() {
    let state = windowState()
    guard state != lastState, let channel = windowChannel else { return }
    lastState = state
    channel.invokeMethod("windowState", arguments: state)
  }

  func windowDidBecomeKey(_ notification: Notification) { publishWindowState() }
  func windowDidResignKey(_ notification: Notification) { publishWindowState() }
  func windowDidResize(_ notification: Notification) { publishWindowState() }
  func windowDidEnterFullScreen(_ notification: Notification) { publishWindowState() }
  func windowDidExitFullScreen(_ notification: Notification) { publishWindowState() }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    if closeApproved { return true }
    guard let channel = hostChannel else { return true }
    if closePending { return false }
    closePending = true
    channel.invokeMethod("requestClose", arguments: nil) { [weak self] reply in
      guard let self = self else { return }
      self.closePending = false
      guard (reply as? Bool) == true else {
        NSLog("Core shutdown not completed; keeping window open")
        return
      }
      self.closeApproved = true
      // Let the engine's reply dispatch unwind before the window goes away.
      DispatchQueue.main.async { self.close() }
    }
    return false
  }
}
