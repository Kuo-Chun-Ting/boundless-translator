import AppKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_cancelOperation_when_handlerIsConfigured_thenForwardsRequest() {
    // Arrange
    let window = TranslationWindow()
    var forwardedSender: String?
    window.cancelOperationHandler = { sender in
        forwardedSender = sender as? String
    }

    // Act
    window.cancelOperation("escape")

    // Assert
    #expect(forwardedSender == "escape")
}

@Test @MainActor
func test_configureChrome_when_translation_is_presented_then_keeps_resizable_native_title_bar() {
    // Arrange
    let window = TranslationWindow()
    let toolbar = NSToolbar(identifier: "TranslationWindowTests")
    window.toolbar = toolbar

    // Act
    window.configureChrome(for: .translation)

    // Assert
    #expect(window.styleMask.contains(.titled))
    #expect(window.styleMask.contains(.closable))
    #expect(window.styleMask.contains(.miniaturizable))
    #expect(window.styleMask.contains(.resizable))
    #expect(!window.styleMask.contains(.nonactivatingPanel))
    #expect(window.isOpaque)
    #expect(window.backgroundColor == .windowBackgroundColor)
    #expect(toolbar.isVisible)
    #expect(window.toolbarStyle == .unifiedCompact)
    #expect(window.titlebarSeparatorStyle == .none)
}

@Test @MainActor
func test_configureChrome_when_auxiliary_content_follows_translation_then_restores_title_bar() {
    // Arrange
    let window = TranslationWindow()
    let toolbar = NSToolbar(identifier: "TranslationWindowTests")
    window.toolbar = toolbar
    window.configureChrome(for: .translation)

    // Act
    window.configureChrome(for: .error)

    // Assert
    #expect(window.styleMask.contains(.titled))
    #expect(window.styleMask.contains(.closable))
    #expect(!window.styleMask.contains(.nonactivatingPanel))
    #expect(window.isOpaque)
    #expect(window.backgroundColor == .windowBackgroundColor)
    #expect(!toolbar.isVisible)
}

@Test @MainActor
func test_pinItem_when_action_is_sent_then_toggles_window_pin_state() throws {
    // Arrange
    let state = TranslationWindowState()
    let controller = TranslationWindowToolbarController(
        windowState: state,
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings()
    )
    let item = try #require(
        controller.toolbar(
            controller.toolbar,
            itemForItemIdentifier: .pinWindow,
            willBeInsertedIntoToolbar: true
        )
    )
    let button = try #require(item.view as? NSButton)
    let action = try #require(button.action)

    // Act
    let didSendAction = NSApplication.shared.sendAction(
        action,
        to: button.target,
        from: button
    )

    // Assert
    #expect(didSendAction)
    #expect(state.isPinned)
}

@Test
func test_init_when_windowIsUnpinned_then_usesDiagonalOutlinePin() {
    // Arrange & Act
    let presentation = PinButtonPresentation(
        isPinned: false,
        localization: testEnglishLocalization
    )

    // Assert
    #expect(presentation.symbolName == "pin")
    #expect(presentation.clockwiseRotationDegrees == 45)
    #expect(presentation.tint == .secondary)
}

@Test
func test_init_when_windowIsPinned_then_usesUprightFilledPin() {
    // Arrange & Act
    let presentation = PinButtonPresentation(
        isPinned: true,
        localization: testEnglishLocalization
    )

    // Assert
    #expect(presentation.symbolName == "pin.fill")
    #expect(presentation.clockwiseRotationDegrees == 0)
    #expect(presentation.tint == .accent)
}

@Test @MainActor
func test_fittingSize_when_translation_is_compact_then_matches_layout_height() throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("train"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let layout = TranslationWindowLayout()
    let metrics = layout.metrics(
        sourceText: "train",
        status: coordinator.status,
        localization: testEnglishLocalization
    )
    let hostingView = NSHostingView(
        rootView: TranslationWindowView(
            coordinator: coordinator,
            speechController: TranslationSpeechController(
                player: WindowSpeechPlayerMock(supportedLanguageIdentifiers: [])
            ),
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            supportedLanguages: [],
            engine: makeStubTranslationEngine(),
            layout: layout
        )
    )

    // Act
    hostingView.layoutSubtreeIfNeeded()

    // Assert
    #expect(abs(hostingView.fittingSize.height - metrics.size.height) < 0.5)
}

@Test @MainActor
func test_body_when_rendering_translation_then_source_text_is_visible() throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("coding"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let layout = TranslationWindowLayout()
    let metrics = layout.metrics(
        sourceText: "coding",
        status: coordinator.status,
        localization: testEnglishLocalization
    )
    let hostingView = NSHostingView(
        rootView: TranslationWindowView(
            coordinator: coordinator,
            speechController: TranslationSpeechController(
                player: WindowSpeechPlayerMock(supportedLanguageIdentifiers: [])
            ),
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            supportedLanguages: [],
            engine: makeStubTranslationEngine(),
            layout: layout
        )
    )
    hostingView.frame = NSRect(origin: .zero, size: metrics.size)

    // Act
    hostingView.layoutSubtreeIfNeeded()
    let sourceView = try #require(
        descendants(of: SourceTextLookupView.self, in: hostingView).first
    )
    sourceView.layoutSubtreeIfNeeded()

    // Assert
    #expect(sourceView.frame.width > 0)
    #expect(sourceView.frame.height > 0)
}

@Test @MainActor
func test_body_when_rendering_text_columns_then_uses_matching_reading_backgrounds() throws {
    // Arrange
    let fixture = try makeRenderedTranslationWindow()
    let leftColumn = fixture.columnRect(column: 0).insetBy(dx: 24, dy: 48)
    let rightColumn = fixture.columnRect(column: 1).insetBy(dx: 24, dy: 48)

    // Act
    let leftLuminance = averageLuminance(in: leftColumn, image: fixture.image)
    let rightLuminance = averageLuminance(in: rightColumn, image: fixture.image)

    // Assert
    #expect(abs(leftLuminance - rightLuminance) < 0.01)
}

@Test @MainActor
func test_body_when_translation_is_available_then_exposes_two_selectable_text_views() async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("coding"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let request = try #require(coordinator.request)
    let stub_runner = WindowTranslationRunner(
        output: TranslationOutput(
            translatedText: "編碼",
            sourceLanguageIdentifier: "en",
            targetLanguageIdentifier: "zh-Hant"
        )
    )
    await coordinator.translate(request, using: stub_runner)
    let hostingView = makeTranslationHostingView(coordinator: coordinator)

    // Act
    hostingView.layoutSubtreeIfNeeded()
    let selectableTextViews = descendants(of: NSTextView.self, in: hostingView)
        .filter(\.isSelectable)

    // Assert
    #expect(selectableTextViews.count == 2)
    #expect(selectableTextViews.allSatisfy { !$0.isEditable })
}

@Test @MainActor
func test_sourceSpeechButton_when_clicked_then_readsSourceText() throws {
    // Arrange
    let speechPlayer = WindowSpeechPlayerMock(
        supportedLanguageIdentifiers: ["en"]
    )
    let speechController = TranslationSpeechController(player: speechPlayer)
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Read this"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let hostingView = makeTranslationHostingView(
        coordinator: coordinator,
        speechController: speechController
    )
    hostingView.layoutSubtreeIfNeeded()
    let button = try #require(
        view(
            in: hostingView,
            accessibilityIdentifier: "sourceSpeechButton"
        ) as? NSButton
    )

    // Act
    let action = try #require(button.action)
    #expect(NSApplication.shared.sendAction(action, to: button.target, from: button))

    // Assert
    #expect(
        speechPlayer.playRequests == [
            .init(text: "Read this", languageIdentifier: "en")
        ]
    )
}

@Test @MainActor
func test_translationSpeechButton_when_idle_then_usesSpeakerWaveTwoSymbol() throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Read this"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let hostingView = makeTranslationHostingView(coordinator: coordinator)

    // Act
    hostingView.layoutSubtreeIfNeeded()
    let button = try #require(
        view(
            in: hostingView,
            accessibilityIdentifier: "sourceSpeechButton"
        ) as? NSButton
    )

    // Assert
    let speaker = try #require(descendants(of: NSImageView.self, in: button).first)
    #expect(
        speaker.image?.tiffRepresentation
            == NSImage(
                systemSymbolName: "speaker.wave.2",
                accessibilityDescription: nil
            )?.tiffRepresentation
    )
    #expect(button.accessibilityLabel() == "Read Source Text Aloud")
}

@Test @MainActor
func test_translationSpeechButton_when_playing_then_keepsSpeakerAndAllowsStopping() throws {
    // Arrange
    let speechController = TranslationSpeechController(
        player: WindowSpeechPlayerMock(supportedLanguageIdentifiers: ["en"])
    )
    speechController.togglePlayback(
        role: .source,
        text: "Read this",
        languageIdentifier: "en"
    )
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Read this"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let hostingView = makeTranslationHostingView(
        coordinator: coordinator,
        speechController: speechController
    )

    // Act
    hostingView.layoutSubtreeIfNeeded()
    let button = try #require(
        view(
            in: hostingView,
            accessibilityIdentifier: "sourceSpeechButton"
        ) as? NSButton
    )

    // Assert
    let speaker = try #require(descendants(of: NSImageView.self, in: button).first)
    #expect(
        speaker.image?.tiffRepresentation
            == NSImage(
                systemSymbolName: "speaker.wave.2",
                accessibilityDescription: nil
            )?.tiffRepresentation
    )
    #expect(speaker.contentTintColor == .controlAccentColor)
    #expect(button.accessibilityLabel() == "Stop Reading Source Text")

    // Act
    button.sendAction(button.action, to: button.target)

    // Assert
    #expect(speechController.activeRole == nil)
}

@Test @MainActor
func test_targetSpeechButton_when_translationIsAvailable_then_readsTranslatedText() async throws {
    // Arrange
    let speechPlayer = WindowSpeechPlayerMock(
        supportedLanguageIdentifiers: ["zh-Hant"]
    )
    let speechController = TranslationSpeechController(player: speechPlayer)
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let request = try #require(coordinator.request)
    await coordinator.translate(
        request,
        using: WindowTranslationRunner(
            output: TranslationOutput(
                translatedText: "你好",
                sourceLanguageIdentifier: "en",
                targetLanguageIdentifier: "zh-Hant"
            )
        )
    )
    let hostingView = makeTranslationHostingView(
        coordinator: coordinator,
        speechController: speechController
    )
    hostingView.layoutSubtreeIfNeeded()
    let button = try #require(
        view(
            in: hostingView,
            accessibilityIdentifier: "targetSpeechButton"
        ) as? NSButton
    )

    // Act
    let action = try #require(button.action)
    #expect(NSApplication.shared.sendAction(action, to: button.target, from: button))

    // Assert
    #expect(
        speechPlayer.playRequests == [
            .init(text: "你好", languageIdentifier: "zh-Hant")
        ]
    )
}

@Test @MainActor
func test_targetSpeechButton_when_translationIsUnavailable_then_keepsHiddenSlot() throws {
    // Arrange
    let speechController = TranslationSpeechController(
        player: WindowSpeechPlayerMock(
            supportedLanguageIdentifiers: ["en", "zh-Hant"]
        )
    )
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let hostingView = makeTranslationHostingView(
        coordinator: coordinator,
        speechController: speechController
    )

    // Act
    hostingView.layoutSubtreeIfNeeded()
    let button = try #require(
        view(
            in: hostingView,
            accessibilityIdentifier: "targetSpeechButton"
        ) as? NSButton
    )

    // Assert
    #expect(button.isHidden)
    #expect(button.frame.width > 0)
}

@Test(arguments: [560.0, 900.0]) @MainActor
func test_languageControls_when_windowResizes_then_speechButtonsAlignWithTheirColumns(
    width: Double
) throws {
    // Arrange
    let speechPlayer = WindowSpeechPlayerMock(
        supportedLanguageIdentifiers: ["en", "zh-Hant"]
    )
    let speechController = TranslationSpeechController(player: speechPlayer)
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let hostingView = makeTranslationHostingView(
        coordinator: coordinator,
        speechController: speechController
    )
    hostingView.frame.size.width = width

    // Act
    hostingView.layoutSubtreeIfNeeded()
    let sourceButton = try #require(
        view(
            in: hostingView,
            accessibilityIdentifier: "sourceSpeechButton"
        )
    )
    let targetButton = try #require(
        view(
            in: hostingView,
            accessibilityIdentifier: "targetSpeechButton"
        )
    )
    let sourceFrame = sourceButton.convert(sourceButton.bounds, to: hostingView)
    let targetFrame = targetButton.convert(targetButton.bounds, to: hostingView)
    let languageMenus = descendants(of: NSPopUpButton.self, in: hostingView)
    let controlRowCenter = hostingView.isFlipped ? 26 : hostingView.bounds.height - 26

    // Assert
    // Each button is centered in a 32-point slot, 18 points from its column edge.
    #expect(abs(sourceFrame.midX - (width / 2 - 34)) < 1)
    #expect(abs(targetFrame.midX - (width - 34)) < 1)
    #expect(abs(sourceFrame.midY - targetFrame.midY) < 1)
    #expect(abs(sourceFrame.width - targetFrame.width) < 1)
    #expect(abs(sourceFrame.height - 28) < 1)
    #expect(abs(sourceFrame.width - 28) < 1)
    #expect(abs(sourceFrame.midY - controlRowCenter) < 1)
    #expect(languageMenus.count == 2)
    for menu in languageMenus {
        let frame = menu.convert(menu.bounds, to: hostingView)
        #expect(abs(frame.midY - controlRowCenter) < 1)
    }
}

@MainActor
private func descendants<ViewType: NSView>(
    of type: ViewType.Type,
    in rootView: NSView
) -> [ViewType] {
    rootView.subviews.flatMap { subview in
        let current = (subview as? ViewType).map { [$0] } ?? []
        return current + descendants(of: type, in: subview)
    }
}

@MainActor
private func makeTranslationHostingView(
    coordinator: TranslationCoordinator,
    speechController: TranslationSpeechController = TranslationSpeechController(
        player: WindowSpeechPlayerMock(
            supportedLanguageIdentifiers: ["en", "zh-Hant"]
        )
    )
) -> NSHostingView<TranslationWindowView> {
    let layout = TranslationWindowLayout()
    let metrics = layout.metrics(
        sourceText: coordinator.request?.text ?? "",
        status: coordinator.status,
        localization: testEnglishLocalization
    )
    let hostingView = NSHostingView(
        rootView: TranslationWindowView(
            coordinator: coordinator,
            speechController: speechController,
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            supportedLanguages: [],
            engine: makeStubTranslationEngine(),
            layout: layout
        )
    )
    hostingView.frame = NSRect(origin: .zero, size: metrics.size)
    hostingView.appearance = NSAppearance(named: .darkAqua)
    return hostingView
}

@MainActor
private func view(
    in rootView: NSView,
    accessibilityIdentifier: String
) -> NSView? {
    if rootView.accessibilityIdentifier() == accessibilityIdentifier {
        return rootView
    }
    return rootView.subviews.lazy.compactMap {
        view(in: $0, accessibilityIdentifier: accessibilityIdentifier)
    }.first
}

@MainActor
private func makeRenderedTranslationWindow() throws -> TranslationWindowRenderFixture {
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("coding"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let hostingView = makeTranslationHostingView(coordinator: coordinator)
    hostingView.layoutSubtreeIfNeeded()
    let image = try #require(
        hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)
    )
    hostingView.cacheDisplay(in: hostingView.bounds, to: image)
    try captureImageIfRequested(image)
    return TranslationWindowRenderFixture(image: image, size: hostingView.bounds.size)
}

private func captureImageIfRequested(_ image: NSBitmapImageRep) throws {
    guard
        let path = ProcessInfo.processInfo.environment["BOUNDLESS_UI_CAPTURE_PATH"],
        let data = image.representation(using: .png, properties: [:])
    else {
        return
    }

    try data.write(to: URL(fileURLWithPath: path))
}

private func averageLuminance(
    in rect: NSRect,
    image: NSBitmapImageRep
) -> CGFloat {
    let scaleX = CGFloat(image.pixelsWide) / CGFloat(image.size.width)
    let scaleY = CGFloat(image.pixelsHigh) / CGFloat(image.size.height)
    let pixelRect = NSRect(
        x: rect.minX * scaleX,
        y: rect.minY * scaleY,
        width: rect.width * scaleX,
        height: rect.height * scaleY
    ).integral
    var total: CGFloat = 0
    var count = 0

    for y in Int(pixelRect.minY)..<Int(pixelRect.maxY) {
        for x in Int(pixelRect.minX)..<Int(pixelRect.maxX) {
            guard let color = image.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else {
                continue
            }
            total += (color.redComponent + color.greenComponent + color.blueComponent) / 3
            count += 1
        }
    }

    return count == 0 ? 0 : total / CGFloat(count)
}

private struct TranslationWindowRenderFixture {
    let image: NSBitmapImageRep
    let size: CGSize

    func columnRect(column: Int) -> NSRect {
        let width = size.width / 2
        let height = size.height
            - TranslationWindowStyle.languageRowHeight
            - TranslationWindowStyle.controlsVerticalPadding * 2
        return NSRect(
            x: CGFloat(column) * width,
            y: size.height - height,
            width: width,
            height: height
        )
    }
}

private struct WindowTranslationRunner: TranslationRunning {
    let output: TranslationOutput

    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        output
    }
}

@MainActor
private final class WindowSpeechPlayerMock: SpeechPlaying {
    struct Request: Equatable {
        let text: String
        let languageIdentifier: String
    }

    private let supportedLanguageIdentifiers: Set<String>
    private(set) var playRequests: [Request] = []

    init(supportedLanguageIdentifiers: Set<String>) {
        self.supportedLanguageIdentifiers = supportedLanguageIdentifiers
    }

    func supports(languageIdentifier: String) -> Bool {
        supportedLanguageIdentifiers.contains(languageIdentifier)
    }

    func play(
        text: String,
        languageIdentifier: String,
        completion: @escaping @MainActor () -> Void
    ) {
        playRequests.append(
            Request(text: text, languageIdentifier: languageIdentifier)
        )
    }

    func stop() {}
}
