import AppKit

@main
private enum CursorTestHost {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate: NSApplicationDelegate =
            ProcessInfo.processInfo.environment["BOUNDLESS_TRANSLATOR_HINT_KIND"] != nil
            ? HintFixtureDelegate() : ImageTextFixtureDelegate()
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        application.run()
    }
}
