import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerNativeThemeChannel()
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// Lets the Dart side ask iOS to override the app's interface style, so
  /// system-presented UI (the document picker, share sheet, keyboard)
  /// matches the in-app theme override instead of only ever following the
  /// device's actual system Dark/Light Mode setting.
  private func registerNativeThemeChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(
      name: "purapdf/native_theme",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setInterfaceStyle", let style = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch style {
      case "dark":
        self?.window?.overrideUserInterfaceStyle = .dark
      case "light":
        self?.window?.overrideUserInterfaceStyle = .light
      default:
        self?.window?.overrideUserInterfaceStyle = .unspecified
      }
      result(nil)
    }
  }
}
