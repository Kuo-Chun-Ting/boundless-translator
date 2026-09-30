import AppKit
import SwiftUI
import TipKit

struct ScreenshotTip: Tip {
    let localization: AppLocalization
    let shortcut: String

    var title: Text { Text(verbatim: instruction).font(.body) }

    var instruction: String {
        localization.string("screenshot.guidance", arguments: shortcut)
    }
}

struct ScreenshotTipPlacement {
    static func side(window: CGRect, screen: CGRect, width: CGFloat) -> NSRectEdge? {
        let requiredSpace = width + 24
        if window.minX - screen.minX >= requiredSpace { return .minX }
        if screen.maxX - window.maxX >= requiredSpace { return .maxX }
        return nil
    }
}

@MainActor
final class ScreenshotTipController {
    private weak var window: NSWindow?
    private var popover: TipNSPopover?
    private var displayTask: Task<Void, Never>?
    private var shouldDisplay = false

    func present(in window: NSWindow, localization: AppLocalization, shortcut: String) {
        close()
        guard !shortcut.isEmpty else { return }
        self.window = window
        let tip = ScreenshotTip(localization: localization, shortcut: shortcut)
        let popover = TipNSPopover(tip)
        popover.behavior = .applicationDefined
        self.popover = popover
        displayTask = Task { [weak self] in
            for await shouldDisplay in tip.shouldDisplayUpdates {
                guard !Task.isCancelled else { return }
                self?.shouldDisplay = shouldDisplay
                self?.updatePosition()
            }
        }
    }

    func updatePosition() {
        guard shouldDisplay, let window, window.isVisible,
              !window.isMiniaturized, let content = window.contentView,
              let screen = window.screen?.visibleFrame, let popover,
              let side = ScreenshotTipPlacement.side(
                window: window.frame, screen: screen, width: popover.contentSize.width
              ) else {
            popover?.close()
            return
        }
        let anchor = CGPoint(
            x: side == .minX ? window.frame.minX : window.frame.maxX,
            y: window.frame.maxY - 60 - popover.contentSize.height / 2
        )
        let anchorInWindow = window.convertPoint(fromScreen: anchor)
        let anchorInContent = content.convert(anchorInWindow, from: nil)
        popover.show(
            relativeTo: CGRect(origin: anchorInContent, size: CGSize(width: 1, height: 1)),
            of: content, preferredEdge: side
        )
    }

    func close() {
        displayTask?.cancel()
        displayTask = nil
        popover?.close()
        popover = nil
        shouldDisplay = false
        window = nil
    }

    deinit { displayTask?.cancel() }
}
