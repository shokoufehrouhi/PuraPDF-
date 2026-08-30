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
    registerShareIntentChannel()
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

  /// Dart side of the Share Extension hand-off (see
  /// ShareExtension/ShareViewController.swift's doc comment for the other
  /// half): the extension already wrote the shared file into the App
  /// Group container and recorded which tool was picked in this suite's
  /// UserDefaults before foregrounding the app via the `purapdf://` URL
  /// scheme - this channel's only job is reading that back out, and
  /// removing it so a share is only ever consumed once (Dart calls
  /// `takePendingShare` on launch and every time the app resumes; without
  /// clearing, the same share would keep reappearing on every later
  /// resume).
  private func registerShareIntentChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(
      name: "purapdf/share_intent",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "takePendingShare" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let defaults = UserDefaults(suiteName: "group.com.purapdf.purapdf")
      guard
        let path = defaults?.string(forKey: "pendingSharePath"),
        let tool = defaults?.string(forKey: "pendingShareTool"),
        FileManager.default.fileExists(atPath: path)
      else {
        result(nil)
        return
      }
      defaults?.removeObject(forKey: "pendingSharePath")
      defaults?.removeObject(forKey: "pendingShareTool")
      result(["path": path, "tool": tool])
    }
  }
}
