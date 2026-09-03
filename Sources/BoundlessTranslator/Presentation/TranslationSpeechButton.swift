import AppKit
import SwiftUI

struct TranslationSpeechButton: NSViewRepresentable {
    @ObservedObject var controller: TranslationSpeechController

    let role: TranslationSpeechRole
    let text: String
    let languageIdentifier: String
    let localization: AppLocalization

    init(
        controller: TranslationSpeechController,
        role: TranslationSpeechRole,
        text: String,
        languageIdentifier: String,
        localization: AppLocalization
    ) {
        self.controller = controller
        self.role = role
        self.text = text
        self.languageIdentifier = languageIdentifier
        self.localization = localization
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        button.title = ""
        button.imagePosition = .imageOnly
        button.bezelStyle = .circular
        button.controlSize = .small
        button.target = context.coordinator
        button.action = #selector(Coordinator.togglePlayback)
        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        context.coordinator.parent = self

        let isPlaying = controller.activeRole == role
        let isAvailable = controller.canPlay(
            text: text,
            languageIdentifier: languageIdentifier
        )
        let label = accessibilityLabel(isPlaying: isPlaying)
        let symbolName = isPlaying ? "stop.fill" : "speaker.wave.2.fill"

        button.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: label
        )
        button.contentTintColor = isPlaying
            ? .controlAccentColor
            : .secondaryLabelColor
        button.toolTip = label
        button.isHidden = !isAvailable
        button.isEnabled = isAvailable
        button.setAccessibilityLabel(label)
        button.setAccessibilityIdentifier(accessibilityIdentifier)
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: TranslationSpeechButton

        init(parent: TranslationSpeechButton) {
            self.parent = parent
        }

        @objc
        func togglePlayback() {
            parent.controller.togglePlayback(
                role: parent.role,
                text: parent.text,
                languageIdentifier: parent.languageIdentifier
            )
        }
    }

    private var accessibilityIdentifier: String {
        role == .source ? "sourceSpeechButton" : "targetSpeechButton"
    }

    private func accessibilityLabel(isPlaying: Bool) -> String {
        if isPlaying {
            return localization.string(
                role == .source
                    ? "speech.stopSource"
                    : "speech.stopTranslation"
            )
        }
        return localization.string(
            role == .source
                ? "speech.readSource"
                : "speech.readTranslation"
        )
    }
}
