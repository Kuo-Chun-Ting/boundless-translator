import AppKit
import SwiftUI
import TipKit

@MainActor
final class ScreenshotTipController {
    private var hintView: NSHostingView<HintView>?
    private var displayTask: Task<Void, Never>?

    func present(in window: NSWindow, localization: AppLocalization, shortcut: String) {
        close()
        guard !shortcut.isEmpty, let content = window.contentView else { return }
        let tip = ScreenshotTip(localization: localization, shortcut: shortcut)
        displayTask = Task { [weak self, weak content] in
            for await shouldDisplay in tip.shouldDisplayUpdates {
                guard !Task.isCancelled, let self, let content else { return }
                if shouldDisplay {
                    show(tip, in: content)
                } else {
                    hintView?.removeFromSuperview()
                    hintView = nil
                }
            }
        }
    }

    func update(localization: AppLocalization, shortcut: String) {
        hintView?.rootView = makeHint(ScreenshotTip(localization: localization, shortcut: shortcut))
    }

    func close() {
        displayTask?.cancel()
        displayTask = nil
        hintView?.removeFromSuperview()
        hintView = nil
    }

    private func show(_ tip: ScreenshotTip, in content: NSView) {
        guard hintView == nil else { return }
        let view = NSHostingView(rootView: makeHint(tip))
        view.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            view.topAnchor.constraint(equalTo: content.topAnchor, constant: 16)
        ])
        hintView = view
    }

    private func makeHint(_ tip: ScreenshotTip) -> HintView {
        HintView(
            title: tip.title, message: tip.message,
            icon: Image(nsImage: AppBrand.spriteImage), width: 340,
            localization: tip.localization, identifier: "hint.screenshot"
        ) { [weak self] doNotShowAgain in
            if doNotShowAgain { tip.invalidate(reason: .tipClosed) }
            self?.close()
        }
    }

    deinit { displayTask?.cancel() }
}
