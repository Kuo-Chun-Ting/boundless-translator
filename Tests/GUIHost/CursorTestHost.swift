import AppKit
import Foundation
import SwiftUI

@MainActor
private final class CursorTestHostDelegate: NSObject, NSApplicationDelegate {
    private let panel = TranslationPanel(
        contentSize: NSSize(width: 520, height: 420)
    )
    private let sourceView = SourceTextLookupView()
    private weak var lookupButton: PointingHandButton?
    private var stateTimer: Timer?
    private var previousButtonFrame: NSRect?
    private var stableFrameSampleCount = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard outputDirectory() != nil else {
            NSApplication.shared.terminate(nil)
            return
        }

        configurePanel()
        configureSourceView()
        waitForStableLayout()
    }

    private func configurePanel() {
        panel.contentView = TranslationPanelContentView(
            rootView: CursorSourceHostView(sourceView: sourceView)
        )
        panel.center()
        panel.isReleasedWhenClosed = false
        panel.orderFrontRegardless()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func configureSourceView() {
        sourceView.updateText(
            [
                "First line",
                "Second line",
                "Third line",
                "Fourth line",
                "Fifth line",
                "Sixth line",
                "Seventh line",
            ].joined(separator: "\n")
        )
        sourceView.updateSelection(NSRange(location: 46, length: 10))
        panel.contentView?.layoutSubtreeIfNeeded()
        sourceView.layoutSubtreeIfNeeded()
    }

    private func waitForStableLayout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            MainActor.assumeIsolated {
                guard let button = self.findLookupButton() else {
                    self.waitForStableLayout()
                    return
                }

                self.panel.contentView?.layoutSubtreeIfNeeded()
                let frameIsStable = self.previousButtonFrame == button.frame
                self.previousButtonFrame = button.frame
                self.stableFrameSampleCount = frameIsStable
                    ? self.stableFrameSampleCount + 1
                    : 0

                guard self.stableFrameSampleCount >= 5 else {
                    self.waitForStableLayout()
                    return
                }

                self.lookupButton = button
                self.publishReadyState()
                self.observeCursor()
            }
        }
    }

    private func findLookupButton() -> PointingHandButton? {
        panel.contentView?.subviews
            .compactMap { $0 as? PointingHandButton }
            .first
    }

    private func publishReadyState() {
        write(CursorHostReadyState(selectedLine: 5), named: "ready.json")
    }

    private func observeCursor() {
        stateTimer = Timer.scheduledTimer(
            withTimeInterval: 0.02,
            repeats: true
        ) { _ in
            MainActor.assumeIsolated {
                let hitView = self.hitViewAtMouseLocation()
                self.write(
                    CursorHostState(
                        isPointingHand:
                            NSCursor.current === NSCursor.pointingHand,
                        lookupButtonOwnsHitTest: hitView === self.lookupButton
                    ),
                    named: "cursor.json"
                )
            }
        }
    }

    private func hitViewAtMouseLocation() -> NSView? {
        guard let contentView = panel.contentView else {
            return nil
        }
        let windowPoint = panel.convertPoint(fromScreen: NSEvent.mouseLocation)
        return contentView.hitTest(windowPoint)
    }

    private func outputDirectory() -> URL? {
        guard let path = ProcessInfo.processInfo.environment[
            "BOUNDLESS_TRANSLATOR_CURSOR_HOST_OUTPUT"
        ] else {
            return nil
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    private func write<Value: Encodable>(_ value: Value, named fileName: String) {
        guard
            let outputDirectory = outputDirectory(),
            let data = try? JSONEncoder().encode(value)
        else {
            return
        }
        let url = outputDirectory.appendingPathComponent(fileName)
        try? data.write(to: url, options: .atomic)
    }
}

private struct CursorSourceHostView: View {
    let sourceView: SourceTextLookupView

    var body: some View {
        CursorSourceRepresentable(sourceView: sourceView)
            .frame(width: 320, height: 320)
            .padding(40)
    }
}

private struct CursorSourceRepresentable: NSViewRepresentable {
    let sourceView: SourceTextLookupView

    func makeNSView(context: Context) -> SourceTextLookupView {
        sourceView
    }

    func updateNSView(
        _ nsView: SourceTextLookupView,
        context: Context
    ) {}
}

private struct CursorHostReadyState: Encodable {
    let selectedLine: Int
}

private struct CursorHostState: Encodable {
    let isPointingHand: Bool
    let lookupButtonOwnsHitTest: Bool
}

@main
private enum CursorTestHost {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = CursorTestHostDelegate()
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        application.run()
    }
}
