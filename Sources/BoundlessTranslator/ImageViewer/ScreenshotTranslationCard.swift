import AppKit
import SwiftUI

@MainActor
final class ScreenshotTranslationCard: NSView {
    let textView = TranslationTextViewFactory.make()
    let scrollView = NSScrollView()
    let speechButton = SpeechPlaybackButton()
    let lookupButton = PointingHandButton()
    var onSpeech: (() -> Void)?
    var onLookup: (() -> Void)?
    var onPointerEntered: (() -> Void)?
    var onPointerExited: (() -> Void)?
    private var pointerTracking: NSTrackingArea?
    private let statusLabel = NSTextField(labelWithString: "")
    private let spinner = NSProgressIndicator()
    private let scrollContent = ScreenshotTranslationContent()
    private var failureView: NSHostingView<AnyView>?
    private var isTranslating = false
    private let separator = NSBox()
    private let padding: CGFloat = 16
    private let verticalPadding: CGFloat = 12
    private let maximumWidth: CGFloat = 424
    private let horizontalInsets: CGFloat = 112
    private let actionSize = TranslationWindowStyle.speechButtonSize
    private let actionSpacing: CGFloat = 8

    override init(frame: NSRect) {
        super.init(frame: frame)
        scrollView.drawsBackground = false
        scrollView.clipsToBounds = true
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = scrollContent
        textView.font = .systemFont(ofSize: 15, weight: .medium)
        textView.drawsBackground = false
        textView.autoresizingMask = []
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.setAccessibilityIdentifier("screenshotPreview.translation")
        speechButton.target = self
        speechButton.action = #selector(speak)
        speechButton.setAccessibilityIdentifier("screenshotPreview.speech")
        lookupButton.title = LookupActionOverlay.bookIcon
        lookupButton.font = NSFont(name: "Apple Color Emoji", size: 16)
        lookupButton.bezelStyle = .accessoryBarAction
        lookupButton.controlSize = .large
        speechButton.isBordered = false
        lookupButton.isBordered = false
        separator.boxType = .separator
        lookupButton.target = self
        lookupButton.action = #selector(lookup)
        lookupButton.setAccessibilityIdentifier("screenshotPreview.lookup")
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        spinner.style = .spinning
        spinner.controlSize = .small
        for view in [scrollView, separator, speechButton, lookupButton] {
            addSubview(view)
        }
        for view in [textView, statusLabel, spinner] { scrollContent.addSubview(view) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let pointerTracking { removeTrackingArea(pointerTracking) }
        let area = NSTrackingArea(rect: .zero,
            options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited], owner: self)
        pointerTracking = area
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) { onPointerEntered?() }
    override func mouseExited(with event: NSEvent) { onPointerExited?() }

    func render(status: TranslationStatus, output: TranslationOutput?,
                localization: AppLocalization, onRetry: @escaping () -> Void) {
        let text = output?.translatedText ?? ""
        if textView.string != text { textView.string = text }
        isTranslating = status == .translating
        statusLabel.stringValue = localization.string("panel.translating")
        statusLabel.isHidden = !isTranslating
        spinner.isHidden = !isTranslating
        if isTranslating { spinner.startAnimation(nil) } else { spinner.stopAnimation(nil) }
        failureView?.removeFromSuperview()
        failureView = nil
        if case .failed(let failure) = status {
            let view = NSHostingView(rootView: AnyView(TranslationFailureView(
                failure: failure, localization: localization, onRetry: onRetry)
                .frame(width: maximumWidth - horizontalInsets)))
            failureView = view
            scrollContent.addSubview(view)
        }
        lookupButton.toolTip = localization.string("lookup.action")
        lookupButton.setAccessibilityLabel(lookupButton.toolTip)
        needsLayout = true
    }

    func updateSpeech(available: Bool, playing: Bool, localization: AppLocalization) {
        speechButton.isEnabled = available
        speechButton.updatePlayback(isPlaying: playing,
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        speechButton.toolTip = localization.string(playing ? "speech.stopSource" : "speech.readSource")
        speechButton.setAccessibilityLabel(speechButton.toolTip)
    }

    func preferredSize(maximumHeight: CGFloat) -> CGSize {
        let sample = textView.attributedString().attributedSubstring(from: NSRange(
            location: 0, length: textView.string.prefix(20_000).utf16.count))
        let naturalWidth = sample.size().width
        let statusWidth = isTranslating ? statusLabel.intrinsicContentSize.width + 26 : 0
        let minimumWidth: CGFloat = 148
        let width = failureView == nil
            ? min(maximumWidth, max(minimumWidth, max(naturalWidth, statusWidth) + horizontalInsets))
            : maximumWidth
        let storage = NSTextStorage(attributedString: sample)
        let manager = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: width - horizontalInsets, height: 240))
        container.lineFragmentPadding = 0
        storage.addLayoutManager(manager)
        manager.addTextContainer(container)
        manager.ensureLayout(for: container)
        let textHeight = sample.length == 0 ? 0 : ceil(manager.usedRect(for: container).height)
        let failureHeight = failureView?.fittingSize.height ?? 0
        let statusHeight: CGFloat = isTranslating ? 26 : 0
        let contentHeight = max(48,
            verticalPadding * 2 + min(240, textHeight) + statusHeight + failureHeight)
        return CGSize(width: width, height: min(maximumHeight, contentHeight))
    }

    override func layout() {
        super.layout()
        let width = max(0, bounds.width - horizontalInsets)
        let actionX = bounds.width - padding - actionSize * 2 - actionSpacing
        let actionY = (bounds.height - actionSize) / 2
        speechButton.frame = CGRect(x: actionX, y: actionY, width: actionSize, height: actionSize)
        lookupButton.frame = CGRect(x: actionX + actionSize + actionSpacing, y: actionY,
                                    width: actionSize, height: actionSize)
        separator.frame = CGRect(x: actionX - 8, y: 14, width: 1, height: max(0, bounds.height - 28))
        scrollView.frame = CGRect(x: padding, y: verticalPadding, width: width,
                                  height: max(0, bounds.height - verticalPadding * 2))
        textView.setFrameSize(CGSize(width: width, height: 0))
        textView.textContainer?.containerSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        let textHeight = textView.string.isEmpty ? 0 : ceil(
            textView.layoutManager!.usedRect(for: textView.textContainer!).height)
        let failureHeight = failureView?.fittingSize.height ?? 0
        let statusHeight: CGFloat = isTranslating ? 26 : 0
        let contentHeight = textHeight + failureHeight + statusHeight
        let contentY = max(0, (scrollView.contentSize.height - contentHeight) / 2)
        let height = max(scrollView.contentSize.height, contentHeight)
        scrollContent.frame = CGRect(x: 0, y: 0, width: width, height: height)
        textView.frame = CGRect(x: 0, y: contentY, width: width, height: textHeight)
        spinner.frame = CGRect(x: 0, y: contentY + textHeight + 5, width: 16, height: 16)
        statusLabel.frame = CGRect(x: 24, y: contentY + textHeight + 3, width: width - 24, height: 20)
        if let failureView {
            failureView.frame = CGRect(x: 0, y: contentY + textHeight + statusHeight,
                                       width: width, height: failureHeight)
        }
        needsDisplay = true
    }

    @objc private func speak() { onSpeech?() }
    @objc private func lookup() { onLookup?() }
}

private final class ScreenshotTranslationContent: NSView {
    override var isFlipped: Bool { true }
}
