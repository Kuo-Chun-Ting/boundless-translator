import AppKit

@MainActor
private final class E2ETestHostDelegate: NSObject, NSApplicationDelegate {
    private let testEditor = NSTextView()
    private let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 760, height: 560),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMainMenu()
        configureTestEditor()
        window.title = "Boundless Translator E2E Fixture"
        window.contentView = makeContentView()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(
            withTitle: "Copy",
            action: #selector(NSText.copy(_:)),
            keyEquivalent: "c"
        )
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        NSApplication.shared.mainMenu = mainMenu
    }

    private func configureTestEditor() {
        testEditor.isEditable = false
        testEditor.isSelectable = true
        testEditor.font = .systemFont(ofSize: 20)
        testEditor.setAccessibilityIdentifier("fixture.testEditor")
    }

    private func makeContentView() -> NSView {
        let editorScrollView = testEditor.enclosingScrollView()
        let selectButton = NSButton(
            title: "Select Accessibility Text",
            target: self,
            action: #selector(selectAccessibilityText)
        )
        selectButton.setAccessibilityIdentifier("fixture.selectAccessibilityText")

        let copyButton = NSButton(
            title: "Select Copy-Only Text",
            target: self,
            action: #selector(selectCopyOnlyText)
        )
        copyButton.setAccessibilityIdentifier("fixture.selectCopyOnlyText")

        let screenshotSample = NSTextField(labelWithString: "SCREENSHOT SAMPLE")
        screenshotSample.alignment = .center
        screenshotSample.font = .boldSystemFont(ofSize: 42)
        screenshotSample.textColor = .black
        screenshotSample.drawsBackground = true
        screenshotSample.backgroundColor = .white
        screenshotSample.setAccessibilityIdentifier("fixture.screenshotSample")

        let stack = NSStackView(views: [
            selectButton,
            copyButton,
            editorScrollView,
            screenshotSample,
        ])
        stack.orientation = .vertical
        stack.spacing = 18
        stack.alignment = .centerX
        stack.edgeInsets = NSEdgeInsets(top: 28, left: 28, bottom: 28, right: 28)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            editorScrollView.widthAnchor.constraint(equalToConstant: 620),
            editorScrollView.heightAnchor.constraint(equalToConstant: 100),
            screenshotSample.widthAnchor.constraint(equalToConstant: 620),
            screenshotSample.heightAnchor.constraint(equalToConstant: 150),
        ])
        return contentView
    }

    @objc
    private func selectAccessibilityText() {
        selectText(
            "Accessibility selection sample",
            exposesAccessibilitySelectedText: true
        )
    }

    @objc
    private func selectCopyOnlyText() {
        selectText(
            "Clipboard fallback sample",
            exposesAccessibilitySelectedText: false
        )
    }

    private func selectText(
        _ text: String,
        exposesAccessibilitySelectedText: Bool
    ) {
        testEditor.setAccessibilityElement(exposesAccessibilitySelectedText)
        testEditor.string = text
        window.makeFirstResponder(testEditor)
        testEditor.setSelectedRange(NSRange(location: 0, length: text.utf16.count))
    }
}

private extension NSTextView {
    func enclosingScrollView() -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.documentView = self
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        return scrollView
    }
}

@main
private enum E2ETestHost {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = E2ETestHostDelegate()
        application.setActivationPolicy(.regular)
        application.delegate = delegate
        application.run()
    }
}
