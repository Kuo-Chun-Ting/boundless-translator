import AppKit
import SwiftUI

@MainActor
protocol DictionaryDefinitionPresenting {
    func showDefinition(
        in textView: NSTextView,
        selectedRange: NSRange
    )
}

@MainActor
struct AppleDictionaryDefinitionPresenter: DictionaryDefinitionPresenting {
    func showDefinition(
        in textView: NSTextView,
        selectedRange: NSRange
    ) {
        textView.showDefinition(
            for: nil,
            range: selectedRange,
            options: [
                .presentationType: NSView.DefinitionPresentationType.overlay
            ],
            baselineOriginProvider: nil
        )
    }
}

struct LookupActionPositioner {
    let horizontalMargin: CGFloat
    let verticalGap: CGFloat

    func origin(
        selectionRect: CGRect,
        buttonSize: CGSize,
        bounds: CGRect
    ) -> CGPoint {
        let maximumX = max(
            bounds.minX + horizontalMargin,
            bounds.maxX - buttonSize.width - horizontalMargin
        )
        let preferredX = selectionRect.midX - buttonSize.width / 2
        let maximumY = max(
            bounds.minY + horizontalMargin,
            bounds.maxY - buttonSize.height - horizontalMargin
        )
        let preferredY = selectionRect.maxY + verticalGap

        return CGPoint(
            x: min(max(preferredX, bounds.minX + horizontalMargin), maximumX),
            y: min(max(preferredY, bounds.minY + horizontalMargin), maximumY)
        )
    }
}

@MainActor
final class SourceTextLookupView: NSView, NSTextViewDelegate {
    private let dictionaryPresenter: any DictionaryDefinitionPresenting
    private let lookupActionPositioner = LookupActionPositioner(
        horizontalMargin: 4,
        verticalGap: 4
    )
    private let scrollView = OverflowAwareScrollView()
    private let textView = NSTextView()
    private let lookupButton = NSButton()
    private var lookupSelection: DictionaryLookupSelection?
    private weak var lookupOverlayView: NSView?

    var isLookupActionVisible: Bool {
        !lookupButton.isHidden
    }

    init(
        dictionaryPresenter: any DictionaryDefinitionPresenting =
            AppleDictionaryDefinitionPresenter()
    ) {
        self.dictionaryPresenter = dictionaryPresenter
        super.init(frame: .zero)

        configureScrollView()
        configureTextView()
        configureLookupButton()
        observeScrolling()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard window != nil else {
            lookupButton.removeFromSuperview()
            lookupOverlayView = nil
            return
        }

        attachLookupButtonIfNeeded()
        positionLookupButton()
    }

    override func layout() {
        super.layout()
        positionLookupButton()
    }

    func updateText(_ text: String) {
        guard textView.string != text else {
            return
        }

        textView.string = text
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        updateSelection(textView.selectedRange())
    }

    func updateSelection(_ selectedRange: NSRange) {
        lookupSelection = DictionaryLookupSelection.make(
            text: textView.string,
            selectedRange: selectedRange
        )
        lookupButton.isHidden = lookupSelection == nil
        attachLookupButtonIfNeeded()
        positionLookupButton()
    }

    func performLookup() {
        guard let lookupSelection else {
            return
        }

        textView.setSelectedRange(lookupSelection.range)
        dictionaryPresenter.showDefinition(
            in: textView,
            selectedRange: lookupSelection.range
        )
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        updateSelection(textView.selectedRange())
    }

    private func configureScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = false
        scrollView.documentView = textView
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: TranslationPanelStyle.cardContentPadding
            ),
            scrollView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -TranslationPanelStyle.cardContentPadding
            ),
            scrollView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: TranslationPanelStyle.cardContentPadding
            ),
            scrollView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -TranslationPanelStyle.cardContentPadding
            )
        ])
    }

    private func configureTextView() {
        textView.delegate = self
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.textColor = .labelColor
        textView.textContainerInset = .zero
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.containerSize = NSSize(
            width: 0,
            height: CGFloat.greatestFiniteMagnitude
        )
    }

    private func configureLookupButton() {
        let label = "Look Up in Dictionary"
        lookupButton.title = "📖"
        lookupButton.image = nil
        lookupButton.font = NSFont(name: "Apple Color Emoji", size: 16)
        lookupButton.bezelStyle = .accessoryBarAction
        lookupButton.controlSize = .small
        lookupButton.target = self
        lookupButton.action = #selector(lookUpSelection(_:))
        lookupButton.toolTip = label
        lookupButton.setAccessibilityLabel(label)
        lookupButton.isHidden = true
    }

    private func observeScrolling() {
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewBoundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
    }

    private func positionLookupButton() {
        guard
            let lookupSelection,
            !lookupButton.isHidden,
            let window,
            let overlayView = lookupOverlayView
        else {
            return
        }

        let selectionRect = textView.firstRect(
            forCharacterRange: lookupSelection.range,
            actualRange: nil
        )
        let buttonSize = NSSize(width: 28, height: 28)
        let sourceScreenRect = window.convertToScreen(convert(bounds, to: nil))
        let overlayScreenRect = window.convertToScreen(
            overlayView.convert(overlayView.bounds, to: nil)
        )
        let actionBounds = NSRect(
            x: sourceScreenRect.minX,
            y: overlayScreenRect.minY,
            width: sourceScreenRect.width,
            height: overlayScreenRect.height
        )
        let origin = lookupActionPositioner.origin(
            selectionRect: selectionRect,
            buttonSize: buttonSize,
            bounds: actionBounds
        )

        let buttonScreenRect = NSRect(origin: origin, size: buttonSize)
        let buttonWindowRect = window.convertFromScreen(buttonScreenRect)
        lookupButton.frame = overlayView.convert(buttonWindowRect, from: nil)
    }

    private func attachLookupButtonIfNeeded() {
        guard
            lookupSelection != nil,
            let overlayView = window?.contentView
        else {
            return
        }

        guard lookupButton.superview !== overlayView else {
            return
        }

        lookupButton.removeFromSuperview()
        overlayView.addSubview(lookupButton, positioned: .above, relativeTo: nil)
        lookupOverlayView = overlayView
    }

    @objc
    private func lookUpSelection(_ sender: Any?) {
        performLookup()
    }

    @objc
    private func scrollViewBoundsDidChange(_ notification: Notification) {
        positionLookupButton()
    }
}

struct SelectableSourceTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> SourceTextLookupView {
        let view = SourceTextLookupView()
        view.updateText(text)
        return view
    }

    func updateNSView(
        _ nsView: SourceTextLookupView,
        context: Context
    ) {
        nsView.updateText(text)
    }
}
