import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerNativeThemeChannel(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }

  /// Lets the Dart side ask macOS to override the app's appearance, so
  /// system-presented UI (the Open panel, share sheet) matches the in-app
  /// theme override instead of only ever following the Mac's actual
  /// system Dark/Light appearance setting.
  private func registerNativeThemeChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "purapdf/native_theme", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "setInterfaceStyle", let style = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch style {
      case "dark":
        NSApp.appearance = NSAppearance(named: .darkAqua)
      case "light":
        NSApp.appearance = NSAppearance(named: .aqua)
      default:
        NSApp.appearance = nil
      }
      result(nil)
    }
  }
}
