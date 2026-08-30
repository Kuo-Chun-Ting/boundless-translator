import AppKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_canBecomeKey_when_panel_isPresented_then_returns_true() {
    // Arrange
    let panel = TranslationPanel()

    // Act
    let canBecomeKey = panel.canBecomeKey

    // Assert
    #expect(canBecomeKey)
}

@Test @MainActor
func test_cancelOperation_when_handlerIsConfigured_thenForwardsRequest() {
    // Arrange
    let panel = TranslationPanel()
    var forwardedSender: String?
    panel.cancelOperationHandler = { sender in
        forwardedSender = sender as? String
    }

    // Act
    panel.cancelOperation("escape")

    // Assert
    #expect(forwardedSender == "escape")
}

@Test @MainActor
func test_configureChrome_when_translation_is_presented_then_keeps_resizable_native_title_bar() {
    // Arrange
    let panel = TranslationPanel()
    let toolbar = NSToolbar(identifier: "TranslationPanelTests")
    panel.toolbar = toolbar

    // Act
    panel.configureChrome(for: .translation)

    // Assert
    #expect(panel.styleMask.contains(.titled))
    #expect(panel.styleMask.contains(.closable))
    #expect(panel.styleMask.contains(.miniaturizable))
    #expect(panel.styleMask.contains(.resizable))
    #expect(panel.isOpaque)
    #expect(panel.backgroundColor == .windowBackgroundColor)
    #expect(toolbar.isVisible)
    #expect(panel.toolbarStyle == .unifiedCompact)
    #expect(panel.titlebarSeparatorStyle == .none)
}

@Test @MainActor
func test_configureChrome_when_auxiliary_content_follows_translation_then_restores_title_bar() {
    // Arrange
    let panel = TranslationPanel()
    let toolbar = NSToolbar(identifier: "TranslationPanelTests")
    panel.toolbar = toolbar
    panel.configureChrome(for: .translation)

    // Act
    panel.configureChrome(for: .error)

    // Assert
    #expect(panel.styleMask.contains(.titled))
    #expect(panel.styleMask.contains(.closable))
    #expect(panel.isOpaque)
    #expect(panel.backgroundColor == .windowBackgroundColor)
    #expect(!toolbar.isVisible)
}

@Test @MainActor
func test_pinItem_when_action_is_sent_then_toggles_panel_pin_state() throws {
    // Arrange
    let state = TranslationPanelState()
    let controller = TranslationPanelToolbarController(panelState: state)
    let item = try #require(
        controller.toolbar(
            controller.toolbar,
            itemForItemIdentifier: .pinPanel,
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
func test_init_when_panelIsUnpinned_then_usesDiagonalOutlinePin() {
    // Arrange & Act
    let presentation = PinButtonPresentation(isPinned: false)

    // Assert
    #expect(presentation.symbolName == "pin")
    #expect(presentation.clockwiseRotationDegrees == 45)
    #expect(presentation.tint == .secondary)
}

@Test
func test_init_when_panelIsPinned_then_usesUprightFilledPin() {
    // Arrange & Act
    let presentation = PinButtonPresentation(isPinned: true)

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
    let layout = TranslationPanelLayout()
    let metrics = layout.metrics(
        sourceText: "train",
        status: coordinator.status
    )
    let hostingView = NSHostingView(
        rootView: TranslationPanelView(
            coordinator: coordinator,
            supportedLanguages: [],
            layout: layout
        )
    )

    // Act
    hostingView.layoutSubtreeIfNeeded()

    // Assert
    #expect(abs(hostingView.fittingSize.height - metrics.size.height) < 0.5)
}

@Test @MainActor
func test_body_when_rendering_translation_then_source_card_is_visible() throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("coding"),
        sourceLanguageIdentifier: "en",
        targetLanguageIdentifier: "zh-Hant"
    )
    let layout = TranslationPanelLayout()
    let metrics = layout.metrics(
        sourceText: "coding",
        status: coordinator.status
    )
    let hostingView = NSHostingView(
        rootView: TranslationPanelView(
            coordinator: coordinator,
            supportedLanguages: [],
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
func test_body_when_rendering_equal_card_roles_then_uses_matching_fill_luminance() throws {
    // Arrange
    let fixture = try makeRenderedTranslationPanel()
    let leftCard = fixture.cardRect(column: 0).insetBy(dx: 24, dy: 24)
    let rightCard = fixture.cardRect(column: 1).insetBy(dx: 24, dy: 24)

    // Act
    let leftLuminance = averageLuminance(in: leftCard, image: fixture.image)
    let rightLuminance = averageLuminance(in: rightCard, image: fixture.image)

    // Assert
    #expect(abs(leftLuminance - rightLuminance) < 0.01)
}

@Test @MainActor
func test_body_when_rendering_equal_card_roles_then_uses_matching_border_luminance() throws {
    // Arrange
    let fixture = try makeRenderedTranslationPanel()
    let leftCard = fixture.cardRect(column: 0)
    let rightCard = fixture.cardRect(column: 1)
    let leftBorder = NSRect(
        x: leftCard.minX,
        y: leftCard.minY + 24,
        width: 2,
        height: leftCard.height - 48
    )
    let rightBorder = NSRect(
        x: rightCard.minX,
        y: rightCard.minY + 24,
        width: 2,
        height: rightCard.height - 48
    )

    // Act
    let leftLuminance = averageLuminance(in: leftBorder, image: fixture.image)
    let rightLuminance = averageLuminance(in: rightBorder, image: fixture.image)

    // Assert
    #expect(abs(leftLuminance - rightLuminance) < 0.01)
}

@Test @MainActor
func test_body_when_rendering_cards_then_uses_subtle_edges() throws {
    // Arrange
    let fixture = try makeRenderedTranslationPanel()
    let edgeAndInteriorLuminance = [0, 1].map { column in
        let card = fixture.cardRect(column: column)
        let edge = NSRect(
            x: card.minX,
            y: card.minY + 24,
            width: 2,
            height: card.height - 48
        )
        let interior = NSRect(
            x: card.minX + 4,
            y: card.minY + 24,
            width: 2,
            height: card.height - 48
        )
        return (
            averageLuminance(in: edge, image: fixture.image),
            averageLuminance(in: interior, image: fixture.image)
        )
    }

    // Act
    let edgeContrasts = edgeAndInteriorLuminance.map { edge, interior in
        abs(edge - interior)
    }

    // Assert
    #expect(edgeContrasts.allSatisfy { $0 < 0.04 })
}

@Test @MainActor
func test_body_when_rendering_cards_then_uses_lighter_fill_than_window() throws {
    // Arrange
    let fixture = try makeRenderedTranslationPanel()
    let card = fixture.cardRect(column: 0)
    let fill = card.insetBy(dx: 24, dy: 24)
    let windowBackground = NSRect(
        x: card.maxX + 3,
        y: card.midY - 20,
        width: TranslationPanelStyle.columnSpacing - 6,
        height: 40
    )

    // Act
    let fillLuminance = averageLuminance(in: fill, image: fixture.image)
    let windowLuminance = averageLuminance(
        in: windowBackground,
        image: fixture.image
    )

    // Assert
    #expect(fillLuminance - windowLuminance > 0.01)
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
    let stub_runner = PanelTranslationRunner(
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
    coordinator: TranslationCoordinator
) -> NSHostingView<TranslationPanelView> {
    let layout = TranslationPanelLayout()
    let metrics = layout.metrics(
        sourceText: coordinator.request?.text ?? "",
        status: coordinator.status
    )
    let hostingView = NSHostingView(
        rootView: TranslationPanelView(
            coordinator: coordinator,
            supportedLanguages: [],
            layout: layout
        )
    )
    hostingView.frame = NSRect(origin: .zero, size: metrics.size)
    hostingView.appearance = NSAppearance(named: .darkAqua)
    return hostingView
}

@MainActor
private func makeRenderedTranslationPanel() throws -> TranslationPanelRenderFixture {
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
    return TranslationPanelRenderFixture(image: image, size: hostingView.bounds.size)
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

private struct TranslationPanelRenderFixture {
    let image: NSBitmapImageRep
    let size: CGSize

    func cardRect(column: Int) -> NSRect {
        let width = (
            size.width
                - TranslationPanelStyle.horizontalPadding * 2
                - TranslationPanelStyle.columnSpacing
        ) / 2
        let height = size.height
            - TranslationPanelStyle.languageRowHeight
            - TranslationPanelStyle.contentSpacing
            - TranslationPanelStyle.bottomPadding
        return NSRect(
            x: TranslationPanelStyle.horizontalPadding
                + CGFloat(column) * (width + TranslationPanelStyle.columnSpacing),
            y: TranslationPanelStyle.bottomPadding,
            width: width,
            height: height
        )
    }
}

private struct PanelTranslationRunner: TranslationRunning {
    let output: TranslationOutput

    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        output
    }
}
