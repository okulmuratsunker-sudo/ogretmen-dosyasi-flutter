import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    // false: macOS önceki (bozuk/taşmış) pencere konum-boyutunu hatırlayıp
    // geri yüklemesin — MainFlutterWindow'da ayarlanan boyut her açılışta
    // geçerli olsun.
    return false
  }
}
