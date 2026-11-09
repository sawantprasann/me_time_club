import Flutter
import QuickLook
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
      DispatchQueue.main.async {
        self.revealInFiles(documents: documents, file: destination)
      }
    } catch {
      result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
    }
  }

  /// Opens the Files app on this download. If that cannot open, shows the file itself.
  private var previewSource: FilePreviewSource?

  private func revealInFiles(documents: URL, file: URL) {
    guard let filesURL = URL(string: "shareddocuments://\(documents.path)") else {
      presentPreview(file)
      return
    }
    UIApplication.shared.open(filesURL, options: [:]) { [weak self] opened in
      if !opened {
        self?.presentPreview(file)
      }
    }
  }

  private func presentPreview(_ file: URL) {
    let source = FilePreviewSource(url: file)
    previewSource = source
    let preview = QLPreviewController()
    preview.dataSource = source
    guard let presenter = topViewController() else { return }
    presenter.present(preview, animated: true)
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
}

private final class FilePreviewSource: NSObject, QLPreviewControllerDataSource {
  let url: URL
  init(url: URL) { self.url = url }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    url as NSURL
  }
}
