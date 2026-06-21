import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Pencereyi mevcut ekranın görünür alanına (menü çubuğu/Dock hariç)
    // sığacak şekilde boyutlandır ve ortala — varsayılan/storyboard boyutu
    // bazı ekranlarda görünür alanın üstüne taşabiliyordu.
    if let screen = NSScreen.main {
      let visible = screen.visibleFrame
      let width = min(1280, visible.width - 80)
      let height = min(860, visible.height - 80)
      let x = visible.origin.x + (visible.width - width) / 2
      let y = visible.origin.y + (visible.height - height) / 2
      self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
