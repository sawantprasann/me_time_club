import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var saveChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "me_time_club/save_file",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    saveChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "saveFile" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.saveFile(call: call, result: result)
    }
  }

  private func saveFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let path = args["path"] as? String,
          let name = args["name"] as? String,
          !name.isEmpty,
          !name.contains("/") else {
      result(FlutterError(code: "bad_args", message: "Missing file", details: nil))
      return
    }

    do {
      let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let destination = documents.appendingPathComponent(name)
      if FileManager.default.fileExists(atPath: destination.path) {
        try FileManager.default.removeItem(at: destination)
      }
      try FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: destination)
      result(true)
    } catch {
      result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
    }
  }
}
