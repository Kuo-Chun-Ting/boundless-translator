import AppKit

struct LookupActionPositioner {
    let horizontalMargin: CGFloat
    let verticalGap: CGFloat

    func origin(
        selectionRect: CGRect,
        previousLineRect: CGRect? = nil,
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
        let preferredY = previousLineRect.map {
            $0.midY - buttonSize.height / 2
        } ?? selectionRect.maxY + verticalGap

        return CGPoint(
            x: min(max(preferredX, bounds.minX + horizontalMargin), maximumX),
            y: min(max(preferredY, bounds.minY + horizontalMargin), maximumY)
        )
    }
}

@MainActor
final class PointingHandButton: NSButton {}

@MainActor
final class LookupActionOverlay {
    private let button = PointingHandButton()
    private let positioner = LookupActionPositioner(
        horizontalMargin: 4,
        verticalGap: 2
    )
    private weak var containerView: NSView?

    var isVisible: Bool {
        !button.isHidden
    }

    init(target: AnyObject, action: Selector) {
        configureButton(target: target, action: action)
    }

    func attach(to containerView: NSView?) {
        guard let containerView else {
            button.removeFromSuperview()
            self.containerView = nil
            return
        }
        guard button.superview !== containerView else {
            return
        }

        button.removeFromSuperview()
        containerView.addSubview(button, positioned: .above, relativeTo: nil)
        self.containerView = containerView
    }

    func update(
        isActive: Bool,
        selection: DictionaryLookupSelection?,
        sourceView: NSView,
        textView: NSTextView,
        scrollView: NSScrollView
    ) {
        guard isActive, let selection else {
            button.isHidden = true
            return
        }

        button.isHidden = false
        guard
            let window = sourceView.window,
            let containerView = window.contentView
        else {
            return
        }

        attach(to: containerView)
        let selectionIsVisible = isSelectionVisible(
            selection.range,
            textView: textView,
            scrollView: scrollView
        )
        button.isHidden = !selectionIsVisible
        guard selectionIsVisible else {
            return
        }

        positionButton(
            for: selection.range,
            sourceView: sourceView,
            textView: textView,
            in: window
        )
    }

    private func configureButton(target: AnyObject, action: Selector) {
        let label = "Look Up in Dictionary"
        button.title = "📖"
        button.image = nil
        button.font = NSFont(name: "Apple Color Emoji", size: 16)
        button.bezelStyle = .accessoryBarAction
        button.controlSize = .small
        button.target = target
        button.action = action
        button.toolTip = label
        button.setAccessibilityLabel(label)
        button.isHidden = true
    }

    private func positionButton(
        for selectedRange: NSRange,
        sourceView: NSView,
        textView: NSTextView,
        in window: NSWindow
    ) {
        guard let containerView else {
            return
        }

        let selectionRect = textView.firstRect(
            forCharacterRange: selectedRange,
            actualRange: nil
        )
        let buttonSize = NSSize(width: 28, height: 28)
        let sourceScreenRect = window.convertToScreen(
            sourceView.convert(sourceView.bounds, to: nil)
        )
        let containerScreenRect = window.convertToScreen(
            containerView.convert(containerView.bounds, to: nil)
        )
        let actionBounds = NSRect(
            x: sourceScreenRect.minX,
            y: containerScreenRect.minY,
            width: sourceScreenRect.width,
            height: containerScreenRect.height
        )
        let origin = positioner.origin(
            selectionRect: selectionRect,
            previousLineRect: previousVisualLineScreenRect(
                for: selectedRange,
                textView: textView,
                window: window
            ),
            buttonSize: buttonSize,
            bounds: actionBounds
        )

        let buttonScreenRect = NSRect(origin: origin, size: buttonSize)
        let buttonWindowRect = window.convertFromScreen(buttonScreenRect)
        button.frame = containerView.convert(buttonWindowRect, from: nil)
    }

    private func previousVisualLineScreenRect(
        for selectedRange: NSRange,
        textView: NSTextView,
        window: NSWindow
    ) -> NSRect? {
        guard
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        else {
            return nil
        }

        layoutManager.ensureLayout(for: textContainer)
        let selectedGlyphRange = layoutManager.glyphRange(
            forCharacterRange: selectedRange,
            actualCharacterRange: nil
        )
        var selectedLineGlyphRange = NSRange()
        layoutManager.lineFragmentRect(
            forGlyphAt: selectedGlyphRange.location,
            effectiveRange: &selectedLineGlyphRange
        )
        guard selectedLineGlyphRange.location > 0 else {
            return nil
        }

        let previousLineRect = layoutManager.lineFragmentUsedRect(
            forGlyphAt: selectedLineGlyphRange.location - 1,
            effectiveRange: nil
        ).offsetBy(
            dx: textView.textContainerOrigin.x,
            dy: textView.textContainerOrigin.y
        )
        let previousLineWindowRect = textView.convert(previousLineRect, to: nil)
        return window.convertToScreen(previousLineWindowRect)
    }

    private func isSelectionVisible(
        _ selectedRange: NSRange,
        textView: NSTextView,
        scrollView: NSScrollView
    ) -> Bool {
        guard
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        else {
            return false
        }

        layoutManager.ensureLayout(for: textContainer)
        let glyphRange = layoutManager.glyphRange(
            forCharacterRange: selectedRange,
            actualCharacterRange: nil
        )
        let selectionRect = layoutManager.boundingRect(
            forGlyphRange: glyphRange,
            in: textContainer
        ).offsetBy(
            dx: textView.textContainerOrigin.x,
            dy: textView.textContainerOrigin.y
        )
        let selectionRectInClipView = textView.convert(
            selectionRect,
            to: scrollView.contentView
        )
        return selectionRectInClipView.intersects(scrollView.contentView.bounds)
    }
}
