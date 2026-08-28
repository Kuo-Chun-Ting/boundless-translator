import AppKit
@preconcurrency import Combine

extension NSToolbarItem.Identifier {
    static let translationMode = NSToolbarItem.Identifier(
        "com.boundlesstranslator.toolbar.translation-mode"
    )
    static let pinPanel = NSToolbarItem.Identifier(
        "com.boundlesstranslator.toolbar.pin-panel"
    )
}

@MainActor
final class TranslationPanelToolbarController: NSObject, NSToolbarDelegate {
    let toolbar = NSToolbar(identifier: "BoundlessTranslatorPanelToolbar")

    private let panelState: TranslationPanelState
    private let onSelectMode: @MainActor (TranslationPanelMode) -> Void
    private let modeControl = NSSegmentedControl(
        labels: ["Translate", "Dictionary"],
        trackingMode: .selectOne,
        target: nil,
        action: nil
    )
    private let pinButton = NSButton()
    private let modeItem = NSToolbarItem(itemIdentifier: .translationMode)
    private let pinItem = NSToolbarItem(itemIdentifier: .pinPanel)
    private var cancellables: Set<AnyCancellable> = []

    init(
        panelState: TranslationPanelState,
        onSelectMode: @escaping @MainActor (TranslationPanelMode) -> Void
    ) {
        self.panelState = panelState
        self.onSelectMode = onSelectMode
        super.init()

        configureToolbar()
        configureModeItem()
        configurePinItem()
        observePanelState()
        synchronize()
    }

    func synchronize() {
        updateModeControl(panelState.mode)
        updatePinButton(isPinned: panelState.isPinned)
    }

    func toolbarAllowedItemIdentifiers(
        _ toolbar: NSToolbar
    ) -> [NSToolbarItem.Identifier] {
        [.translationMode, .flexibleSpace, .pinPanel]
    }

    func toolbarDefaultItemIdentifiers(
        _ toolbar: NSToolbar
    ) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .translationMode, .flexibleSpace, .pinPanel]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case .translationMode:
            modeItem
        case .pinPanel:
            pinItem
        default:
            nil
        }
    }

    private func configureToolbar() {
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.centeredItemIdentifier = .translationMode
    }

    private func configureModeItem() {
        modeControl.segmentStyle = .automatic
        modeControl.controlSize = .small
        modeControl.target = self
        modeControl.action = #selector(selectMode(_:))
        modeControl.toolTip = "Choose Translate or Dictionary"
        modeControl.setAccessibilityLabel("Result Mode")

        modeItem.label = "Result Mode"
        modeItem.paletteLabel = "Result Mode"
        modeItem.view = modeControl
        modeItem.visibilityPriority = .high
    }

    private func configurePinItem() {
        pinButton.bezelStyle = .toolbar
        pinButton.isBordered = false
        pinButton.imagePosition = .imageOnly
        pinButton.target = self
        pinButton.action = #selector(togglePin(_:))

        pinItem.label = "Pin Window"
        pinItem.paletteLabel = "Pin Window"
        pinItem.view = pinButton
        pinItem.visibilityPriority = .high
    }

    private func observePanelState() {
        panelState.$mode
            .sink { [weak self] mode in
                Task { @MainActor [weak self] in
                    self?.updateModeControl(mode)
                }
            }
            .store(in: &cancellables)

        panelState.$isPinned
            .sink { [weak self] isPinned in
                Task { @MainActor [weak self] in
                    self?.updatePinButton(isPinned: isPinned)
                }
            }
            .store(in: &cancellables)
    }

    @objc
    private func selectMode(_ sender: NSSegmentedControl) {
        guard let mode = TranslationPanelMode(rawValue: sender.selectedSegment) else {
            return
        }

        onSelectMode(mode)
        synchronize()
    }

    @objc
    private func togglePin(_ sender: Any?) {
        panelState.togglePin()
        synchronize()
    }

    private func updateModeControl(_ mode: TranslationPanelMode) {
        modeControl.selectedSegment = mode.rawValue
    }

    private func updatePinButton(isPinned: Bool) {
        let label = isPinned ? "Unpin Window" : "Pin Window"
        let symbolName = isPinned ? "pin.fill" : "pin"

        pinButton.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: label
        )
        pinButton.contentTintColor = isPinned ? .controlAccentColor : .secondaryLabelColor
        pinButton.toolTip = label
        pinButton.setAccessibilityLabel(label)
        pinItem.label = label
    }
}
