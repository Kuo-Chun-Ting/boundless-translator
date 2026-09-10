import AppKit

@main
enum StoreKitTestHost {
    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.prohibited)
        application.run()
    }
}
