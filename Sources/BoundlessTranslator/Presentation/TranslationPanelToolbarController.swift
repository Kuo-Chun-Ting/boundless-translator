import AppKit
@preconcurrency import Combine

extension NSToolbarItem.Identifier {
    static let pinPanel = NSToolbarItem.Identifier(
        "com.boundlesstranslator.toolbar.pin-panel"
    )
}

enum PinButtonTint {
    case secondary
    case accent
}

struct PinButtonPresentation {
    let label: String
    let symbolName: String
    let clockwiseRotationDegrees: CGFloat
    let tint: PinButtonTint

    init(isPinned: Bool) {
        label = isPinned ? "Unpin Window" : "Pin Window"
        symbolName = isPinned ? "pin.fill" : "pin"
        clockwiseRotationDegrees = isPinned ? 0 : 45
        tint = isPinned ? .accent : .secondary
    }
}

@MainActor
final class TranslationPanelToolbarController: NSObject, NSToolbarDelegate {
    let toolbar = NSToolbar(identifier: "BoundlessTranslatorPanelToolbar")

    private let panelState: TranslationPanelState
    private let pinButton = NSButton()
    private let pinItem = NSToolbarItem(itemIdentifier: .pinPanel)
    private var cancellables: Set<AnyCancellable> = []

    init(panelState: TranslationPanelState) {
        self.panelState = panelState
        super.init()

        configureToolbar()
        configurePinItem()
        observePanelState()
        synchronize()
    }

    func synchronize() {
        updatePinButton(isPinned: panelState.isPinned)
    }

    func toolbarAllowedItemIdentifiers(
        _ toolbar: NSToolbar
    ) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .pinPanel]
    }

    func toolbarDefaultItemIdentifiers(
        _ toolbar: NSToolbar
    ) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .pinPanel]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
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
    }

    private func configurePinItem() {
        pinButton.bezelStyle = .toolbar
        pinButton.isBordered = false
        pinButton.frame.size = CGSize(width: 28, height: 28)
        pinButton.imagePosition = .imageOnly
        pinButton.imageScaling = .scaleProportionallyDown
        pinButton.target = self
        pinButton.action = #selector(togglePin(_:))

        pinItem.label = "Pin Window"
        pinItem.paletteLabel = "Pin Window"
        pinItem.view = pinButton
        pinItem.visibilityPriority = .high
    }

    private func observePanelState() {
        panelState.$isPinned
            .sink { [weak self] isPinned in
                Task { @MainActor [weak self] in
                    self?.updatePinButton(isPinned: isPinned)
                }
            }
            .store(in: &cancellables)
    }

    @objc
    private func togglePin(_ sender: Any?) {
        panelState.togglePin()
        synchronize()
    }

    private func updatePinButton(isPinned: Bool) {
        let presentation = PinButtonPresentation(isPinned: isPinned)

        pinButton.image = makePinImage(for: presentation)
        pinButton.contentTintColor = color(for: presentation.tint)
        pinButton.toolTip = presentation.label
        pinButton.setAccessibilityLabel(presentation.label)
        pinItem.label = presentation.label
    }

    private func makePinImage(
        for presentation: PinButtonPresentation
    ) -> NSImage? {
        guard let image = NSImage(
            systemSymbolName: presentation.symbolName,
            accessibilityDescription: presentation.label
        ) else {
            return nil
        }

        return image.rotatedClockwise(
            byDegrees: presentation.clockwiseRotationDegrees
        )
    }

    private func color(for tint: PinButtonTint) -> NSColor {
        switch tint {
        case .secondary:
            .secondaryLabelColor
        case .accent:
            .controlAccentColor
        }
    }
}

private extension NSImage {
    func rotatedClockwise(byDegrees degrees: CGFloat) -> NSImage {
        guard degrees != 0 else {
            return self
        }

        let radians = degrees * .pi / 180
        let rotatedWidth = abs(size.width * cos(radians))
            + abs(size.height * sin(radians))
        let rotatedHeight = abs(size.width * sin(radians))
            + abs(size.height * cos(radians))
        let sourceSize = size
        let rotatedSize = CGSize(width: rotatedWidth, height: rotatedHeight)
        let rotatedImage = NSImage(size: rotatedSize, flipped: false) { rect in
            let transform = NSAffineTransform()
            transform.translateX(by: rect.midX, yBy: rect.midY)
            transform.rotate(byDegrees: -degrees)
            transform.translateX(
                by: -sourceSize.width / 2,
                yBy: -sourceSize.height / 2
            )
            transform.concat()
            self.draw(in: CGRect(origin: .zero, size: sourceSize))
            return true
        }
        rotatedImage.isTemplate = isTemplate
        return rotatedImage
    }
}
