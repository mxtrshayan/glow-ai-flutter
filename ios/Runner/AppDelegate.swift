import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate {
  private var saveReply: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "glow_ai/media", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, reply in
        guard call.method == "saveImage" else { reply(FlutterMethodNotImplemented); return }
        guard let self = self else { reply(FlutterError(code: "unavailable", message: "App is unavailable", details: nil)); return }
        guard self.saveReply == nil else { reply(FlutterError(code: "busy", message: "A save is already in progress", details: nil)); return }
        guard let arguments = call.arguments as? [String: Any], let path = arguments["path"] as? String,
              FileManager.default.fileExists(atPath: path) else {
          reply(FlutterError(code: "missing_image", message: "The preview could not be opened", details: nil)); return
        }
        self.saveReply = reply
        let picker = UIDocumentPickerViewController(forExporting: [URL(fileURLWithPath: path)], asCopy: true)
        picker.delegate = self
        picker.view.tintColor = UIColor(red: 157.0/255, green: 63.0/255, blue: 96.0/255, alpha: 1)
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
          try? FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
          picker.directoryURL = documents
        }
        var presenter: UIViewController = controller
        while let presented = presenter.presentedViewController { presenter = presented }
        presenter.present(picker, animated: true)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let reply = saveReply; saveReply = nil; reply?(!urls.isEmpty)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let reply = saveReply; saveReply = nil; reply?(false)
  }
}
