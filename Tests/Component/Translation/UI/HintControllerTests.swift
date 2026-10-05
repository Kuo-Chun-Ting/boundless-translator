import AppKit
import SwiftUI
import Testing
import TipKit
@testable import BoundlessTranslator

// TipKit has process-wide state. This suite uses one temporary store and distinct tip IDs.
@Suite(.serialized) @MainActor
struct HintControllerTests {
    private static let configure: Void = {
        try! Tips.configure([.datastoreLocation(.url(
            FileManager.default.temporaryDirectory.appendingPathComponent("boundless-component-tips-\(UUID())")))])
    }()

    @Test
    func test_screenshotHint_when_closed_then_releasesSpaceWithoutChangingImageOrSelection() async throws {
        // Arrange
        _ = Self.configure
        let (originalWindow, view) = await selectionFixture()
        originalWindow.contentView = nil
        originalWindow.close()
        let controller = ImageViewerWindowController(
            content: view, windowPresenter: ForegroundWindowPresenterSpy(),
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings())
        controller.translationShortcutName = { "⇧⌘1" }
        let window = try #require(controller.window)
        defer { controller.close() }
        controller.present(image: NSImage(size: CGSize(width: 200, height: 200)), pointerLocation: .zero)
        await viewAnalysis(view)
        #expect(window.isVisible)
        let container = try #require(window.contentView)
        let hint = try await waitForHint(in: container)
        view.selectAll(nil)
        let image = view.image
        let originalBounds = view.imageRect
        let originalSize = view.frame.size
        let originalHeight = window.frame.height
        #expect(!hint.frame.intersects(view.frame))
        // Act
        hint.rootView.onClose(false)
        // Assert
        #expect(hint.superview == nil)
        #expect(window.frame.height < originalHeight)
        #expect(view.frame.size == originalSize)
        #expect(view.image === image)
        #expect(view.imageRect == originalBounds)
        #expect(view.selectedText == "A B")
        #expect(ScreenshotTip(localization: testEnglishLocalization, shortcut: "⇧⌘1").status == .available)
    }

    @Test
    func test_settingsHint_when_parentMoves_then_followsHelpButtonOnRight() async throws {
        // Arrange
        _ = Self.configure
        let (window, _) = await selectionFixture()
        let button = NSButton(frame: CGRect(x: 140, y: 20, width: 24, height: 24))
        window.contentView!.addSubview(button)
        window.orderFront(nil)
        defer { window.close() }
        let controller = SettingsTipController()
        controller.setAnchor(button, localization: testEnglishLocalization)
        controller.present(in: window)
        let panel = try await waitForSettingsPanel(in: window)
        let before = panel.frame
        // Act
        window.setFrameOrigin(CGPoint(x: window.frame.minX + 50, y: window.frame.minY - 20))
        // Assert
        #expect(abs(panel.frame.minX - before.minX - 50) < 1)
        #expect(abs(panel.frame.minY - before.minY + 20) < 1)
        #expect(abs(panel.frame.minX - window.frame.maxX - 8) < 1)
        controller.close()
    }

    @Test
    func test_settingsHint_when_closed_then_removesChildPanelWithoutInvalidation() async throws {
        // Arrange
        _ = Self.configure
        let (window, _) = await selectionFixture()
        let button = NSButton(frame: CGRect(x: 140, y: 20, width: 24, height: 24))
        window.contentView!.addSubview(button)
        window.orderFront(nil)
        defer { window.close() }
        let controller = SettingsTipController()
        controller.setAnchor(button, localization: testEnglishLocalization)
        controller.present(in: window)
        let panel = try await waitForSettingsPanel(in: window)
        let hint = try #require(panel.contentView as? NSHostingView<HintView>)
        // Act
        hint.rootView.onClose(false)
        // Assert
        #expect(!panel.isVisible)
        #expect(window.childWindows?.isEmpty != false)
        #expect(SettingsTip(localization: testEnglishLocalization).status == .available)
    }
}

@MainActor private func waitForHint(in view: NSView) async throws -> NSHostingView<HintView> {
    for _ in 0..<100 {
        if let hint = view.subviews.compactMap({ $0 as? NSHostingView<HintView> }).first { return hint }
        try await Task.sleep(for: .milliseconds(10))
    }
    throw HintTestError.notPresented
}

@MainActor private func waitForSettingsPanel(in window: NSWindow) async throws -> NSWindow {
    for _ in 0..<100 {
        if let panel = window.childWindows?.first { return panel }
        try await Task.sleep(for: .milliseconds(10))
    }
    throw HintTestError.notPresented
}

private enum HintTestError: Error { case notPresented }
