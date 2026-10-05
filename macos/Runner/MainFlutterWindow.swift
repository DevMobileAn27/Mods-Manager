import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private static var activeScopedURLs: [URL] = []

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let channel = FlutterMethodChannel(
      name: "xxmi_manager/security_scope",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "createBookmark":
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
          result(FlutterError(code: "bad_args", message: "Missing path", details: nil)); return
        }
        do {
          let url = URL(fileURLWithPath: path)
          let data = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
          result(data.base64EncodedString())
        } catch {
          result(FlutterError(code: "bookmark_failed", message: error.localizedDescription, details: nil))
        }
      case "restoreBookmark":
        guard let args = call.arguments as? [String: Any],
              let encoded = args["bookmark"] as? String,
              let data = Data(base64Encoded: encoded) else {
          result(FlutterError(code: "bad_args", message: "Missing bookmark", details: nil)); return
        }
        do {
          var stale = false
          let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale)
          if url.startAccessingSecurityScopedResource() {
            MainFlutterWindow.activeScopedURLs.append(url)
          }
          result(["path": url.path, "stale": stale])
        } catch {
          result(FlutterError(code: "restore_failed", message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
