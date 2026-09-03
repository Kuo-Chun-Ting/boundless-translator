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

@MainActor
final class SourceTextLookupView: NSView, NSTextViewDelegate {
    private let dictionaryPresenter: any DictionaryDefinitionPresenting
    private let scrollView = OverflowAwareScrollView()
    private let textView = TranslationTextViewFactory.make()
    private var localization: AppLocalization
    private lazy var lookupActionOverlay = LookupActionOverlay(
        target: self,
        action: #selector(lookUpSelection(_:)),
        localization: localization
    )
    private var lookupSelection: DictionaryLookupSelection?
    private var isSourceTextActive = false

    var isLookupActionVisible: Bool {
        lookupActionOverlay.isVisible
    }

    init(
        dictionaryPresenter: any DictionaryDefinitionPresenting =
            AppleDictionaryDefinitionPresenter(),
        localization: AppLocalization
    ) {
        self.dictionaryPresenter = dictionaryPresenter
        self.localization = localization
        super.init(frame: .zero)

        configureScrollView()
        configureTextView()
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

        NotificationCenter.default.removeObserver(
            self,
            name: .translationPanelFirstResponderDidChange,
            object: nil
        )

        guard window != nil else {
            lookupActionOverlay.attach(to: nil)
            return
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(translationPanelFirstResponderDidChange(_:)),
            name: .translationPanelFirstResponderDidChange,
            object: window
        )

        updateLookupAction()
    }

    override func layout() {
        super.layout()
        updateLookupAction()
    }

    func updateText(_ text: String) {
        guard textView.string != text else {
            return
        }

        textView.string = text
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        updateSelection(textView.selectedRange())
    }

    func updateLocalization(_ localization: AppLocalization) {
        self.localization = localization
        lookupActionOverlay.updateLocalization(localization)
    }

    func updateSelection(_ selectedRange: NSRange) {
        isSourceTextActive = true
        lookupSelection = DictionaryLookupSelection.make(
            text: textView.string,
            selectedRange: selectedRange
        )
        updateLookupAction()
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

    private func updateSourceTextActivity(_ isActive: Bool) {
        isSourceTextActive = isActive
        updateLookupAction()
    }

    @objc
    private func translationPanelFirstResponderDidChange(
        _ notification: Notification
    ) {
        let sourceIsActive = window?.firstResponder === textView
        updateSourceTextActivity(sourceIsActive)
    }

    private func updateLookupAction() {
        lookupActionOverlay.update(
            isActive: isSourceTextActive,
            selection: lookupSelection,
            sourceView: self,
            textView: textView,
            scrollView: scrollView
        )
    }

    @objc
    private func lookUpSelection(_ sender: Any?) {
        performLookup()
    }

    @objc
    private func scrollViewBoundsDidChange(_ notification: Notification) {
        updateLookupAction()
    }
}

struct SelectableSourceTextView: NSViewRepresentable {
    let text: String
    let localization: AppLocalization

    init(
        text: String,
        localization: AppLocalization
    ) {
        self.text = text
        self.localization = localization
    }

    func makeNSView(context: Context) -> SourceTextLookupView {
        let view = SourceTextLookupView(localization: localization)
        view.updateText(text)
        return view
    }

    func updateNSView(
        _ nsView: SourceTextLookupView,
        context: Context
    ) {
        nsView.updateText(text)
        nsView.updateLocalization(localization)
    }
}
