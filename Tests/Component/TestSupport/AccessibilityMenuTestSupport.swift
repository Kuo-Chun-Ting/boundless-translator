import AppKit
import ApplicationServices
import SwiftUI
import Testing
@testable import BoundlessTranslator

@MainActor
struct AccessibilityMenu {
    let element: AnyObject

    var identifier: String? { element.accessibilityIdentifier?() }
    var value: String { element.accessibilityValue?() ?? "" }
    var screenFrame: NSRect { element.accessibilityFrame?() ?? .zero }

    func frame(in view: NSView) throws -> NSRect {
        let window = try #require(view.window)
        return view.convert(window.convertFromScreen(screenFrame), from: nil)
    }

    func selectItem(titled title: String) async throws -> String? {
        try await AccessibilityTestApplication.runForMenu()
        let selection = AccessibilityMenuSelection(title: title)
        NotificationCenter.default.addObserver(
            selection, selector: #selector(AccessibilityMenuSelection.menuStarted(_:)),
            name: NSMenu.didBeginTrackingNotification, object: nil)
        defer { NotificationCenter.default.removeObserver(selection) }
        #expect(element.accessibilityPerformPress?() == true)
        let deadline = ContinuousClock.now.advanced(by: .seconds(3))
        while !selection.completed && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(selection.selected, "Menu item '\(title)' was not selected")
        return selection.previousSelection
    }
}

@MainActor
func findAccessibilityMenus(in view: NSView) async throws -> [AccessibilityMenu] {
    _ = AccessibilityTestApplication.application
    try #require(view.window != nil)
    view.layoutSubtreeIfNeeded()
    try await AccessibilityTestApplication.enableAccessibility()
    view.layoutSubtreeIfNeeded()
    return accessibilityDescendants(view).filter { $0.accessibilityRole?() == .popUpButton }
        .map { AccessibilityMenu(element: $0) }
}

@MainActor
func menuFittingWidth(for value: String, language: InterfaceLanguageSettings) async throws -> CGFloat {
    let reference = NSHostingView(rootView:
        Picker("", selection: .constant(value)) { Text(verbatim: value).tag(value) }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()
            .interfaceLanguage(language))
    let window = NSWindow(contentRect: NSRect(origin: .zero, size: reference.fittingSize),
                          styleMask: [.borderless], backing: .buffered, defer: false)
    window.contentView = reference
    defer { window.orderOut(nil) }
    let menu = try #require(try await findAccessibilityMenus(in: reference).first)
    try #require(menu.screenFrame.width > 0)
    return menu.screenFrame.width
}

@MainActor
private enum AccessibilityTestApplication {
    static let application: NSApplication = {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        application.finishLaunching()
        return application
    }()

    static func runForMenu() async throws {
        let application = self.application
        guard !application.isRunning else { return }
        // AppKit must own the outer loop before opening a native menu on macOS 27.
        await withCheckedContinuation { continuation in
            RunLoop.main.perform(inModes: [.common]) {
                MainActor.assumeIsolated {
                    let started = Timer(timeInterval: 0, repeats: false) { _ in continuation.resume() }
                    RunLoop.main.add(started, forMode: .common)
                    application.run()
                }
            }
        }
        try #require(application.isRunning)
    }

    // One client request enables SwiftUI accessibility for this process.
    private static let accessibilityRequest = Task.detached {
        let application = AXUIElementCreateApplication(ProcessInfo.processInfo.processIdentifier)
        var role: CFTypeRef?
        return AXUIElementCopyAttributeValue(application, kAXRoleAttribute as CFString, &role).rawValue
    }

    static func enableAccessibility() async throws {
        let result = await accessibilityRequest.value
        try #require(result == AXError.success.rawValue)
    }
}

@MainActor
private func accessibilityDescendants(_ element: AnyObject) -> [AnyObject] {
    [element] + (element.accessibilityChildren?() ?? []).flatMap { accessibilityDescendants($0 as AnyObject) }
}

@MainActor
private final class AccessibilityMenuSelection: NSObject {
    let title: String
    var completed = false
    var selected = false
    var previousSelection: String?
    private var menu: NSMenu?

    init(title: String) { self.title = title }

    @objc func menuStarted(_ notification: Notification) {
        menu = notification.object as? NSMenu
        RunLoop.main.perform(inModes: [.common]) {
            MainActor.assumeIsolated { self.selectItem() }
        }
    }

    private func selectItem() {
        guard let menu else { return }
        previousSelection = menu.items.first { $0.state == .on }?.title
        menu.cancelTracking()
        defer { completed = true }
        guard let index = menu.items.firstIndex(where: { $0.title == title }) else { return }
        menu.performActionForItem(at: index)
        selected = true
    }
}
