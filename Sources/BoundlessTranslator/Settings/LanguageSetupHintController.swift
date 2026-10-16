import AppKit
import SwiftUI

// This required guidance follows Settings state, not TipKit dismissal history.
@MainActor
final class LanguageSetupHintController: NSObject {
    private weak var anchor: NSView?
    private weak var parent: NSWindow?
    private var panel: NSPanel?
    private var localization = AppLocalization(languageIdentifier: "en")

    func setAnchor(_ view: NSView) {
        anchor = view
        Task { @MainActor [weak self] in self?.updatePosition() }
    }

    func present(in window: NSWindow, localization: AppLocalization) {
        self.localization = localization
        parent = window
        if panel == nil {
            let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                                backing: .buffered, defer: false)
            panel.identifier = NSUserInterfaceItemIdentifier("languageSetupHint")
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.contentView = NSHostingView(rootView: LanguageSetupHintView(localization: localization))
            self.panel = panel
            observeParent(window)
            updatePosition()
            window.addChildWindow(panel, ordered: .above)
        } else {
            updatePosition()
        }
    }

    @objc func close() {
        NotificationCenter.default.removeObserver(self)
        if let panel {
            parent?.removeChildWindow(panel)
            panel.orderOut(nil)
        }
        panel = nil
        parent = nil
    }

    private func observeParent(_ window: NSWindow) {
        let notifications = NotificationCenter.default
        notifications.removeObserver(self)
        notifications.addObserver(self, selector: #selector(close), name: NSWindow.willCloseNotification, object: window)
        for name in [NSWindow.didMoveNotification, NSWindow.didResizeNotification] {
            notifications.addObserver(self, selector: #selector(updatePosition), name: name, object: window)
        }
    }

    @objc private func updatePosition() {
        guard let panel, let parent, let anchor,
              let view = panel.contentView as? NSHostingView<LanguageSetupHintView> else { return }
        parent.contentView?.layoutSubtreeIfNeeded()
        view.rootView = LanguageSetupHintView(localization: localization)
        let size = view.fittingSize
        // The target row's upper edge lies between the two language controls.
        let anchorFrame = parent.convertToScreen(anchor.convert(anchor.bounds, to: nil))
        let x = parent.frame.maxX + 8
        let y = anchorFrame.maxY - 28
        panel.setFrame(CGRect(x: x, y: y,
                              width: size.width, height: ceil(size.height)), display: true)
    }
}

struct LanguageSetupHintView: View {
    let localization: AppLocalization
    private let surface = HintSurface(presentation: .callout)

    var body: some View {
        HintDescription(
            title: Text(verbatim: localization.string("translationSetup.title")),
            message: Text(verbatim: localization.string("translationSetup.guidance")),
            icon: Image(nsImage: AppBrand.spriteImage)
        )
        .environment(\.locale, Locale(identifier: localization.languageIdentifier))
        .environment(\.layoutDirection,
                     Locale.Language(identifier: localization.languageIdentifier).characterDirection == .rightToLeft
                     ? .rightToLeft : .leftToRight)
        .padding(16)
        .frame(width: 240, alignment: .leading)
        .padding(.leading, 8)
        .fixedSize(horizontal: false, vertical: true)
        .background(surface.fill(Color.primary.opacity(0.06)))
        .background(surface.fill(Color(nsColor: .windowBackgroundColor)))
        .overlay(surface.stroke(Color(nsColor: .separatorColor), lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("hint.languageSetup")
        .environment(\.layoutDirection, .leftToRight)
    }
}

struct LanguageSettingsHintAnchor: NSViewRepresentable {
    var onReady: (@MainActor (NSView) -> Void)?

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ view: NSView, context: Context) {
        onReady?(view)
    }
}
