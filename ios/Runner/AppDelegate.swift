import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var shareChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "me_time_club/share_file",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    shareChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "shareFile" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.shareFile(call: call, result: result)
    }
  }

  private func shareFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let path = args["path"] as? String else {
      result(FlutterError(code: "bad_args", message: "Missing file path", details: nil))
      return
    }

    let url = URL(fileURLWithPath: path)
    DispatchQueue.main.async {
      guard let presenter = self.topViewController() else {
        result(FlutterError(code: "no_ui", message: "Could not open the share sheet", details: nil))
        return
      }

      let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
      if let popover = controller.popoverPresentationController {
        popover.sourceView = presenter.view
        popover.sourceRect = self.sourceRect(from: args, in: presenter.view)
      }

      var replied = false
      controller.completionWithItemsHandler = { _, completed, _, error in
        if replied { return }
        replied = true
        if let error = error {
          result(FlutterError(code: "share_failed", message: error.localizedDescription, details: nil))
        } else {
          result(completed)
        }
      }
      presenter.present(controller, animated: true)
    }
  }

  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }

  private func sourceRect(from args: [String: Any], in view: UIView) -> CGRect {
    guard let origin = args["origin"] as? [String: Any] else {
      return CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
    }
    func number(_ key: String) -> CGFloat {
      guard let value = origin[key] as? NSNumber else { return 0 }
      return CGFloat(truncating: value)
    }
    return CGRect(
      x: number("x"),
      y: number("y"),
      width: max(number("w"), 1),
      height: max(number("h"), 1)
    )
  }
}
