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
        let suite = "ScreenshotHeaderTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = TranslationSettings(defaults: defaults)
        settings.sourceLanguageIdentifier = "en"
        settings.targetLanguageIdentifier = "ja"
        controller.enableQuickTranslation(settings: settings,
                                         engine: makeStubTranslationEngine())
        let window = try #require(controller.window)
        defer { controller.close() }
        controller.present(image: NSImage(size: CGSize(width: 200, height: 200)), pointerLocation: .zero)
        await viewAnalysis(view)
        #expect(window.isVisible)
        let container = try #require(window.contentView)
        let hint = try await waitForHintList(in: container, count: 2)
        let menus = try await findAccessibilityMenus(in: container)
        let sourceMenu = try #require(menus.first { $0.identifier == "sourceLanguageMenu" })
        let targetMenu = try #require(menus.first { $0.identifier == "targetLanguageMenu" })
        let sourceFrame = try sourceMenu.frame(in: container)
        #expect(sourceFrame.minY >= hint.frame.maxY)
        #expect(abs(sourceFrame.midY - (try targetMenu.frame(in: container)).midY) < 1)
        #expect(hint.frame.minY >= view.frame.maxY)
        let menuTopInset = container.bounds.maxY - sourceFrame.maxY
        view.selectAll(nil)
        let image = view.image
        let originalBounds = view.imageRect
        let originalSize = view.frame.size
        let originalHeight = window.frame.height
        #expect(!hint.frame.intersects(view.frame))
        // Act
        hint.rootView.items.first { $0.id == "hint.translationLanguages" }?.onClose(false)
        #expect(hint.rootView.items.map(\.id) == ["hint.screenshot"])
        hint.rootView.items[0].onClose(false)
        // Assert
        #expect(hint.superview == nil)
        #expect(window.frame.height < originalHeight)
        #expect(view.frame.size == originalSize)
        #expect(view.image === image)
        #expect(view.imageRect == originalBounds)
        #expect(view.selectedText == "A B")
        #expect(abs(container.bounds.maxY - (try sourceMenu.frame(in: container)).maxY - menuTopInset) < 1)
        #expect(ScreenshotTip(localization: testEnglishLocalization).status == .available)
    }

    @Test
    func test_translationHints_when_languageHintIsClosed_then_preservesDictionaryAndReappearsNextWindow() async throws {
        // Arrange
        _ = Self.configure
        let coordinator = TranslationCoordinator()
        let content = TranslationWindowView(
            coordinator: coordinator,
            speechController: TranslationSpeechController(player: AppleSpeechPlayer()),
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            supportedLanguages: [], engine: makeStubTranslationEngine()
        )
        let host = NSHostingView(rootView: content)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        defer { window.close() }
        _ = try await findAccessibilityMenus(in: host)
        let languageHint = try await waitForHintElement(in: host, identifier: "hint.translationLanguages")
        _ = try await waitForHintElement(in: host, identifier: "hint.dictionary")
        let close = try #require(hintDescendants(languageHint).first {
            $0.accessibilityRole?() == .button
        })

        // Act
        #expect(close.accessibilityPerformPress?() == true)
        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while hintDescendants(host).contains(where: {
            $0.accessibilityIdentifier?() == "hint.translationLanguages"
        }) && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }

        // Assert
        #expect(!hintDescendants(host).contains {
            $0.accessibilityIdentifier?() == "hint.translationLanguages"
        })
        _ = try await waitForHintElement(in: host, identifier: "hint.dictionary")
        #expect(TranslationLanguageTip(localization: testEnglishLocalization).status == .available)
        let reopened = NSHostingView(rootView: content)
        window.contentView = reopened
        _ = try await waitForHintElement(in: reopened, identifier: "hint.translationLanguages")
    }

    @Test
    func test_settingsHints_when_languages_are_unset_then_help_hint_remains_independent() async throws {
        // Arrange
        _ = Self.configure
        let suite = "IndependentSettingsHints.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = TranslationSettings(defaults: defaults)
        let controller = PreferencesWindowController(
            settings: settings,
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            translationShortcutController: makeTestTranslationShortcutController(),
            supportedLanguageCatalog: makeStubLanguageCatalog(),
            windowPresenter: ForegroundWindowPresenterSpy()
        )
        let window = try #require(controller.window)
        defer { controller.close() }

        // Act
        controller.present()
        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while (window.childWindows?.count ?? 0) < 2 && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }

        // Assert
        let helpPanel = try #require(window.childWindows?.first {
            $0.contentView is NSHostingView<HintView>
        })
        #expect(window.childWindows?.contains { $0.identifier?.rawValue == "languageSetupHint" } == true)
        let helpView = try #require(helpPanel.contentView as? NSHostingView<HintView>)
        helpView.rootView.onClose(false)
        settings.sourceLanguageIdentifier = "en"
        settings.targetLanguageIdentifier = "ja"
        let completionDeadline = ContinuousClock.now.advanced(by: .seconds(2))
        while window.childWindows?.isEmpty == false && ContinuousClock.now < completionDeadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(window.childWindows?.isEmpty != false)
        #expect(SettingsTip(localization: testEnglishLocalization).status == .available)
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

    @Test
    func test_screenshotHints_when_sourceIsUnsupported_then_placesLimitationAboveTutorial() async throws {
        // Arrange
        _ = Self.configure
        let (originalWindow, view) = await selectionFixture()
        originalWindow.contentView = nil
        originalWindow.close()
        let controller = ImageViewerWindowController(
            content: view, windowPresenter: ForegroundWindowPresenterSpy(),
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            recognitionLanguages: { ["en-US"] })
        controller.sourceLanguageIdentifier = { "hi" }
        let window = try #require(controller.window)
        defer { controller.close() }

        // Act
        controller.present(image: NSImage(size: CGSize(width: 200, height: 200)), pointerLocation: .zero)
        let list = try await waitForHintList(in: window.contentView!, count: 3)

        // Assert
        #expect(list.rootView.items.map(\.id) == ["hint.screenshotLanguage", "hint.translationLanguages", "hint.screenshot"])
        #expect(!list.frame.intersects(view.frame))
    }

    @Test
    func test_screenshotHints_when_oneIsClosed_then_preservesOtherHintAndImageSelection() async throws {
        // Arrange
        _ = Self.configure
        let (originalWindow, view) = await selectionFixture()
        originalWindow.contentView = nil
        originalWindow.close()
        let controller = ImageViewerWindowController(
            content: view, windowPresenter: ForegroundWindowPresenterSpy(),
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            recognitionLanguages: { ["en-US"] })
        controller.sourceLanguageIdentifier = { "hi" }
        let window = try #require(controller.window)
        defer { controller.close() }
        controller.present(image: NSImage(size: CGSize(width: 200, height: 200)), pointerLocation: .zero)
        await viewAnalysis(view)
        let list = try await waitForHintList(in: window.contentView!, count: 3)
        view.selectAll(nil)
        let imageSize = view.frame.size
        let imageRect = view.imageRect
        let windowHeight = window.frame.height

        // Act
        list.rootView.items[0].onClose(false)

        // Assert
        #expect(list.rootView.items.map(\.id) == ["hint.translationLanguages", "hint.screenshot"])
        #expect(window.frame.height < windowHeight)
        #expect(view.frame.size == imageSize)
        #expect(view.imageRect == imageRect)
        #expect(view.selectedText == "A B")
        #expect(!list.frame.intersects(view.frame))
    }

    @Test
    func test_hintList_when_temporarilyDismissed_then_staysClosedUntilNextPresentation() async throws {
        // Arrange
        _ = Self.configure
        let (window, _) = await selectionFixture()
        defer { window.close() }
        let controller = ScreenshotTipController()
        defer { controller.close() }
        let hints = makeHintPair()
        controller.present(in: window, localization: testEnglishLocalization, hints: hints)
        let list = try await waitForHintList(in: window.contentView!, count: 2)

        // Act
        list.rootView.items[0].onClose(false)
        controller.update(localization: AppLocalization(languageIdentifier: "de"), hints: hints)
        let remaining = try await waitForHintList(in: window.contentView!, count: 1)

        // Assert
        #expect(remaining.rootView.items.map(\.id) == [hints[1].id])
        #expect(hints[0].tip.status == .available)
        controller.present(in: window, localization: testEnglishLocalization, hints: hints)
        let reopened = try await waitForHintList(in: window.contentView!, count: 2)
        #expect(reopened.rootView.items.map(\.id) == hints.map(\.id))
    }

    @Test
    func test_hintList_when_permanentlyDismissed_then_suppressesOnlyThatTip() async throws {
        // Arrange
        _ = Self.configure
        let (window, _) = await selectionFixture()
        defer { window.close() }
        let controller = ScreenshotTipController()
        defer { controller.close() }
        let hints = makeHintPair()
        controller.present(in: window, localization: testEnglishLocalization, hints: hints)
        let list = try await waitForHintList(in: window.contentView!, count: 2)

        // Act
        list.rootView.items[0].onClose(true)
        controller.close()
        let newHints = hints.map {
            ScreenshotHint(id: $0.id, tip: HintFixtureTip(id: $0.tip.id))
        }
        controller.present(in: window, localization: testEnglishLocalization, hints: newHints)
        let reopened = try await waitForHintList(in: window.contentView!, count: 1)

        // Assert
        #expect(reopened.rootView.items.map(\.id) == [hints[1].id])
        #expect(newHints[1].tip.status == .available)
    }
}

private struct HintFixtureTip: Tip {
    let id: String
    var title: Text { Text("Title") }
    var message: Text? { Text("Message") }
}

private func makeHintPair() -> [ScreenshotHint] {
    (0..<2).map { _ in
        let id = UUID().uuidString
        return ScreenshotHint(id: id, tip: HintFixtureTip(id: id))
    }
}

@MainActor private func waitForHintList(in view: NSView, count: Int) async throws -> NSHostingView<HintListView> {
    for _ in 0..<100 {
        if let list = view.subviews.compactMap({ $0 as? NSHostingView<HintListView> }).first,
           list.rootView.items.count == count { return list }
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

@MainActor private func hintDescendants(_ element: AnyObject) -> [AnyObject] {
    [element] + (element.accessibilityChildren?() ?? []).flatMap { hintDescendants($0 as AnyObject) }
}

@MainActor private func waitForHintElement(in view: NSView, identifier: String) async throws -> AnyObject {
    let deadline = ContinuousClock.now.advanced(by: .seconds(2))
    while ContinuousClock.now < deadline {
        view.layoutSubtreeIfNeeded()
        if let element = hintDescendants(view).first(where: { $0.accessibilityIdentifier?() == identifier }) {
            return element
        }
        try await Task.sleep(for: .milliseconds(10))
    }
    throw HintTestError.notPresented
}
