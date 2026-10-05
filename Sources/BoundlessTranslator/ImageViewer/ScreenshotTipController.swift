import AppKit
import SwiftUI
import TipKit

struct ScreenshotHint: Identifiable {
    let id: String
    let tip: any Tip
}

@MainActor
final class ScreenshotTipController {
    var onHeightChange: (CGFloat) -> Void = { _ in }

    private var hintView: NSHostingView<HintListView>?
    private var displayTasks: [Task<Void, Never>] = []
    private var hints: [ScreenshotHint] = []
    private var visibleIDs: Set<String> = []
    private var closedIDs: Set<String> = []
    private weak var content: NSView?
    private var localization = AppLocalization(languageIdentifier: "en")
    private var width: CGFloat = 0

    func present(in window: NSWindow, localization: AppLocalization, hints: [ScreenshotHint]) {
        close()
        content = window.contentView
        width = content?.bounds.width ?? 0
        update(localization: localization, hints: hints)
    }

    func update(localization: AppLocalization, hints: [ScreenshotHint]) {
        guard content != nil else { return }
        displayTasks.forEach { $0.cancel() }
        self.localization = localization
        self.hints = hints
        visibleIDs.formIntersection(hints.map(\.id))
        updateHint()
        displayTasks = hints.map { hint in
            Task { [weak self] in
                for await shouldDisplay in hint.tip.shouldDisplayUpdates {
                    guard !Task.isCancelled, let self else { return }
                    if shouldDisplay && !closedIDs.contains(hint.id) {
                        visibleIDs.insert(hint.id)
                    } else {
                        visibleIDs.remove(hint.id)
                    }
                    updateHint()
                }
            }
        }
    }

    func resize(to width: CGFloat) {
        guard self.width != width else { return }
        self.width = width
        updateHint()
    }

    func close() {
        displayTasks.forEach { $0.cancel() }
        displayTasks = []
        hints = []
        visibleIDs = []
        closedIDs = []
        content = nil
        removeHint()
    }

    private func updateHint() {
        guard let content else { return }
        let items = hints.filter { visibleIDs.contains($0.id) }.map(makeItem)
        guard !items.isEmpty else { removeHint(); return }
        let rootView = HintListView(items: items, width: width, localization: localization)
        let view = hintView ?? NSHostingView(rootView: rootView)
        if hintView == nil {
            view.autoresizingMask = [.width, .minYMargin]
            content.addSubview(view)
            hintView = view
        }
        view.rootView = rootView
        let height = ceil(view.fittingSize.height)
        onHeightChange(height)
        view.frame = NSRect(x: 0, y: content.bounds.height - height, width: width, height: height)
    }

    private func makeItem(_ hint: ScreenshotHint) -> HintItem {
        HintItem(
            id: hint.id, title: hint.tip.title, message: hint.tip.message,
            icon: hint.tip.image ?? Image(nsImage: AppBrand.spriteImage)
        ) { [weak self] doNotShowAgain in
            if doNotShowAgain { hint.tip.invalidate(reason: .tipClosed) }
            self?.closedIDs.insert(hint.id)
            self?.visibleIDs.remove(hint.id)
            self?.updateHint()
        }
    }

    private func removeHint() {
        hintView?.removeFromSuperview()
        hintView = nil
        onHeightChange(0)
    }

    deinit { displayTasks.forEach { $0.cancel() } }
}
