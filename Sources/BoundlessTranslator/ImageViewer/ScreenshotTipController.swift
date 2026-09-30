import AppKit
import SwiftUI
import TipKit

@MainActor
final class ScreenshotTipController {
    var onHeightChange: (CGFloat) -> Void = { _ in }

    private var hintView: NSHostingView<HintView>?
    private var displayTask: Task<Void, Never>?
    private var tip: ScreenshotTip?
    private var width: CGFloat = 0

    func present(in window: NSWindow, localization: AppLocalization, shortcut: String) {
        close()
        guard !shortcut.isEmpty, let content = window.contentView else { return }
        let tip = ScreenshotTip(localization: localization, shortcut: shortcut)
        self.tip = tip
        displayTask = Task { [weak self, weak content] in
            for await shouldDisplay in tip.shouldDisplayUpdates {
                guard !Task.isCancelled, let self, let content else { return }
                if shouldDisplay { show(in: content) } else { removeHint() }
            }
        }
    }

    func update(localization: AppLocalization, shortcut: String) {
        tip = ScreenshotTip(localization: localization, shortcut: shortcut)
        updateHint()
    }

    func resize(to width: CGFloat) {
        guard self.width != width else { return }
        self.width = width
        updateHint()
    }

    func close() {
        displayTask?.cancel()
        displayTask = nil
        removeHint()
    }

    private func show(in content: NSView) {
        guard hintView == nil, let tip else { return }
        width = content.bounds.width
        let view = NSHostingView(rootView: makeHint(tip))
        view.autoresizingMask = [.width, .minYMargin]
        content.addSubview(view)
        hintView = view
        updateHint()
    }

    private func updateHint() {
        guard let view = hintView, let tip, let content = view.superview else { return }
        view.rootView = makeHint(tip)
        let height = ceil(view.fittingSize.height)
        onHeightChange(height)
        view.frame = NSRect(x: 0, y: content.bounds.height - height, width: width, height: height)
    }

    private func removeHint() {
        hintView?.removeFromSuperview()
        hintView = nil
        onHeightChange(0)
    }

    private func makeHint(_ tip: ScreenshotTip) -> HintView {
        HintView(
            title: tip.title, message: tip.message,
            icon: Image(nsImage: AppBrand.spriteImage), width: width,
            localization: tip.localization, identifier: "hint.screenshot"
        ) { [weak self] doNotShowAgain in
            if doNotShowAgain { tip.invalidate(reason: .tipClosed) }
            self?.close()
        }
    }

    deinit { displayTask?.cancel() }
}
