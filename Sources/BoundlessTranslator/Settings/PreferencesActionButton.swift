import AppKit
import SwiftUI

struct PreferencesActionButton: NSViewRepresentable {
    enum Style: Equatable {
        case help
        case standard(title: String)
    }

    let style: Style
    let accessibilityIdentifier: String
    let action: @MainActor @Sendable () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(
            title: "",
            target: context.coordinator,
            action: #selector(Coordinator.performAction)
        )
        configure(button)
        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        context.coordinator.action = action
        configure(button)
    }

    private func configure(_ button: NSButton) {
        switch style {
        case .help:
            button.title = ""
            button.bezelStyle = .helpButton
            button.setAccessibilityLabel("Show Usage")
        case .standard(let title):
            button.title = title
            button.bezelStyle = .rounded
            button.setAccessibilityLabel(title)
        }
        button.setAccessibilityIdentifier(accessibilityIdentifier)
        button.sizeToFit()
    }

    @MainActor
    final class Coordinator: NSObject {
        var action: @MainActor @Sendable () -> Void

        init(action: @escaping @MainActor @Sendable () -> Void) {
            self.action = action
        }

        @objc func performAction() {
            action()
        }
    }
}
