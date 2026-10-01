import AppKit
import SwiftUI
import TipKit

@MainActor
final class SettingsTipController: NSObject {
    private weak var anchor: NSButton?
    private weak var parent: NSWindow?
    private var panel: NSPanel?
    private var tip: SettingsTip?
    private var displayTask: Task<Void, Never>?

    func setAnchor(_ button: NSButton, localization: AppLocalization) {
        anchor = button
        tip = SettingsTip(localization: localization)
        Task { [weak self] in
            await Task.yield()
            self?.updateHint()
        }
    }

    func present(in window: NSWindow) {
        close()
        parent = window
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(
            self, selector: #selector(close), name: NSWindow.willCloseNotification, object: window
        )
        guard let tip else { return }
        displayTask = Task { [weak self] in
            for await shouldDisplay in tip.shouldDisplayUpdates {
                guard !Task.isCancelled, let self else { return }
                if shouldDisplay { show() } else { removeHint() }
            }
        }
    }

    @objc func close() {
        displayTask?.cancel()
        displayTask = nil
        removeHint()
    }

    private func show() {
        guard panel == nil, let parent, parent.isVisible, let tip else { return }
        let panel = NSPanel(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: makeHint(tip))
        self.panel = panel
        updateHint()
        parent.addChildWindow(panel, ordered: .above)
    }

    private func updateHint() {
        guard let panel, let parent, let anchor, let tip,
              let view = panel.contentView as? NSHostingView<HintView> else { return }
        view.rootView = makeHint(tip)
        parent.contentView?.layoutSubtreeIfNeeded()
        let anchorFrame = parent.convertToScreen(anchor.convert(anchor.bounds, to: nil))
        let size = view.fittingSize
        panel.setFrame(CGRect(
            x: parent.frame.maxX + 8, y: anchorFrame.midY - 28,
            width: size.width, height: ceil(size.height)
        ), display: true)
    }

    private func makeHint(_ tip: SettingsTip) -> HintView {
        HintView(
            title: tip.title, message: tip.message, icon: Image(nsImage: AppBrand.spriteImage),
            width: 248, localization: tip.localization, identifier: "hint.settings",
            onClose: { [weak self] doNotShowAgain in
                if doNotShowAgain { tip.invalidate(reason: .tipClosed) }
                self?.close()
            }, presentation: .callout
        )
    }

    private func removeHint() {
        guard let panel else { return }
        parent?.removeChildWindow(panel)
        panel.orderOut(nil)
        self.panel = nil
    }

    deinit { displayTask?.cancel() }
}
