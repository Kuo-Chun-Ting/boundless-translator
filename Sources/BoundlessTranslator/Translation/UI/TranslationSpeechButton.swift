import AppKit
import SwiftUI
import Symbols

struct TranslationSpeechButton: NSViewRepresentable {
    @ObservedObject var controller: TranslationSpeechController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    func makeNSView(context: Context) -> SpeechPlaybackButton {
        let button = SpeechPlaybackButton()
        button.target = context.coordinator
        button.action = #selector(Coordinator.togglePlayback)
        return button
    }

    func updateNSView(_ button: SpeechPlaybackButton, context: Context) {
        context.coordinator.parent = self

        let isPlaying = controller.activeRole == role
        let isAvailable = controller.canPlay(
            text: text,
            languageIdentifier: languageIdentifier
        )
        let label = accessibilityLabel(isPlaying: isPlaying)
        button.updatePlayback(isPlaying: isPlaying, reduceMotion: reduceMotion)
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

@MainActor
final class SpeechPlaybackButton: NSButton {
    private let speakerView = NSImageView()
    private var isAnimating = false

    override var intrinsicContentSize: NSSize {
        NSSize(
            width: TranslationWindowStyle.speechButtonSize,
            height: TranslationWindowStyle.speechButtonSize
        )
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        title = ""
        bezelStyle = .rounded
        if #available(macOS 26.0, *) {
            borderShape = .circle
        }
        controlSize = .large
        speakerView.image = NSImage(
            systemSymbolName: "speaker.wave.2",
            accessibilityDescription: nil
        )
        speakerView.symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: 17, weight: .regular
        )
        speakerView.setAccessibilityElement(false)
        speakerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(speakerView)
        NSLayoutConstraint.activate([
            speakerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            speakerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            speakerView.widthAnchor.constraint(equalToConstant: 24),
            speakerView.heightAnchor.constraint(equalToConstant: 22),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        super.hitTest(point) == nil ? nil : self
    }

    func updatePlayback(isPlaying: Bool, reduceMotion: Bool) {
        speakerView.contentTintColor = isPlaying ? .controlAccentColor : .secondaryLabelColor
        let shouldAnimate = isPlaying && !reduceMotion
        guard shouldAnimate != isAnimating else { return }
        isAnimating = shouldAnimate
        if shouldAnimate {
            speakerView.addSymbolEffect(.variableColor.cumulative)
        } else {
            speakerView.removeSymbolEffect(ofType: .variableColor, animated: false)
        }
    }
}
