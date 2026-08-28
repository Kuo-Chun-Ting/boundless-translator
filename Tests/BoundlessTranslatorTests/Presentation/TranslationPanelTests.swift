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
func test_modeControl_when_dictionary_segment_is_selected_then_forwards_dictionary_mode() throws {
    // Arrange
    let state = TranslationPanelState()
    var selectedModes: [TranslationPanelMode] = []
    let controller = TranslationPanelToolbarController(
        panelState: state,
        onSelectMode: { selectedModes.append($0) }
    )
    let item = try #require(
        controller.toolbar(
            controller.toolbar,
            itemForItemIdentifier: .translationMode,
            willBeInsertedIntoToolbar: true
        )
    )
    let control = try #require(item.view as? NSSegmentedControl)

    // Act
    control.selectedSegment = TranslationPanelMode.dictionary.rawValue
    control.sendAction(control.action, to: control.target)

    // Assert
    #expect(selectedModes == [.dictionary])
}

@Test @MainActor
func test_pinItem_when_activated_then_toggles_panel_pin_state() throws {
    // Arrange
    let state = TranslationPanelState()
    let controller = TranslationPanelToolbarController(
        panelState: state,
        onSelectMode: { _ in }
    )
    let item = try #require(
        controller.toolbar(
            controller.toolbar,
            itemForItemIdentifier: .pinPanel,
            willBeInsertedIntoToolbar: true
        )
    )
    let button = try #require(item.view as? NSButton)

    // Act
    button.performClick(nil)

    // Assert
    #expect(state.isPinned)
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
    let dictionaryCoordinator = DictionaryLookupCoordinator(
        service: DictionaryLookupServiceStub()
    )
    let panelState = TranslationPanelState()
    let layout = TranslationPanelLayout()
    let metrics = layout.metrics(
        sourceText: "train",
        status: coordinator.status
    )
    let hostingView = NSHostingView(
        rootView: TranslationPanelView(
            coordinator: coordinator,
            dictionaryCoordinator: dictionaryCoordinator,
            panelState: panelState,
            supportedLanguages: [],
            layout: layout
        )
    )

    // Act
    hostingView.layoutSubtreeIfNeeded()

    // Assert
    #expect(abs(hostingView.fittingSize.height - metrics.size.height) < 0.5)
}

private struct DictionaryLookupServiceStub: DictionaryLookupServicing {
    func lookUp(_ term: String) -> String? {
        nil
    }
}
