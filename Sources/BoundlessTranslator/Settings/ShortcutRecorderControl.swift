import AppKit
import SwiftUI

struct ShortcutRecorderControl: NSViewRepresentable {
    let definition: GlobalShortcutDefinition
    let localization: AppLocalization
    let onRecordingStarted: () -> Void
    let onRecordingCancelled: () -> Void
    let onShortcutRecorded: (GlobalShortcutDefinition) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        ShortcutRecorderButton(
            definition: definition,
            localization: localization,
            onRecordingStarted: onRecordingStarted,
            onRecordingCancelled: onRecordingCancelled,
            onShortcutRecorded: onShortcutRecorded
        )
    }

    func updateNSView(
        _ button: ShortcutRecorderButton,
        context: Context
    ) {
        button.onShortcutRecorded = onShortcutRecorded
        button.onRecordingStarted = onRecordingStarted
        button.onRecordingCancelled = onRecordingCancelled
        button.updateLocalization(localization)
        button.updateDefinition(definition)
    }
}

@MainActor
final class ShortcutRecorderButton: NSButton {
    private(set) var isRecording = false
    var onRecordingStarted: () -> Void
    var onRecordingCancelled: () -> Void
    var onShortcutRecorded: (GlobalShortcutDefinition) -> Void

    private var definition: GlobalShortcutDefinition
    private var localization: AppLocalization

    init(
        definition: GlobalShortcutDefinition,
        localization: AppLocalization,
        onRecordingStarted: @escaping () -> Void = {},
        onRecordingCancelled: @escaping () -> Void = {},
        onShortcutRecorded: @escaping (GlobalShortcutDefinition) -> Void
    ) {
        self.definition = definition
        self.localization = localization
        self.onRecordingStarted = onRecordingStarted
        self.onRecordingCancelled = onRecordingCancelled
        self.onShortcutRecorded = onShortcutRecorded
        super.init(frame: .zero)
        configure()
        showDefinition()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    func beginRecording() {
        guard !isRecording else {
            return
        }
        isRecording = true
        title = localization.string("shortcut.recording")
        window?.makeFirstResponder(self)
        onRecordingStarted()
    }

    func updateDefinition(_ definition: GlobalShortcutDefinition) {
        self.definition = definition
        guard !isRecording else {
            return
        }
        showDefinition()
    }

    func updateLocalization(_ localization: AppLocalization) {
        self.localization = localization
        configureLocalizedText()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        guard event.keyCode != 53 else {
            cancelRecording()
            return
        }
        guard let candidate = makeDefinition(from: event), candidate.isValid else {
            NSSound.beep()
            return
        }

        definition = candidate
        finishRecording()
        onShortcutRecorded(candidate)
    }

    override func resignFirstResponder() -> Bool {
        let didResign = super.resignFirstResponder()
        if didResign, isRecording {
            cancelRecording()
        }
        return didResign
    }

    private func configure() {
        target = self
        action = #selector(handleClick)
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        font = .systemFont(ofSize: NSFont.systemFontSize)
        alignment = .center
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(greaterThanOrEqualToConstant: 104).isActive = true
        setAccessibilityIdentifier("shortcutRecorder")
        configureLocalizedText()
    }

    @objc private func handleClick() {
        beginRecording()
    }

    private func makeDefinition(from event: NSEvent) -> GlobalShortcutDefinition? {
        let modifierFlags = event.modifierFlags.intersection([
            .command,
            .option,
            .control,
            .shift,
        ])
        guard
            let characters = event.charactersIgnoringModifiers,
            let keyEquivalent = characters.first.map(String.init),
            !keyEquivalent.isEmpty
        else {
            return nil
        }

        return GlobalShortcutDefinition(
            keyCode: event.keyCode,
            modifierFlags: modifierFlags,
            keyEquivalent: keyEquivalent.uppercased()
        )
    }

    private func cancelRecording() {
        finishRecording()
        onRecordingCancelled()
    }

    private func finishRecording() {
        isRecording = false
        showDefinition()
        window?.makeFirstResponder(nil)
    }

    private func showDefinition() {
        title = definition.displayName
        setAccessibilityLabel(
            localization.string("shortcut.accessibilityLabel")
        )
        setAccessibilityValue(definition.displayName)
    }

    private func configureLocalizedText() {
        toolTip = localization.string("shortcut.tooltip")
        if isRecording {
            title = localization.string("shortcut.recording")
        } else {
            showDefinition()
        }
    }
}
