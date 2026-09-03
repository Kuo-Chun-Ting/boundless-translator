import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_keyDown_when_validShortcutIsRecorded_then_reportsShortcutAndEndsRecording() throws {
    // Arrange
    var recordedShortcut: GlobalShortcutDefinition?
    let button = ShortcutRecorderButton(
        definition: .commandShiftT,
        localization: testEnglishLocalization,
        onShortcutRecorded: { recordedShortcut = $0 }
    )
    let event = try #require(
        makeKeyEvent(
            keyCode: 40,
            modifierFlags: [.command, .option],
            charactersIgnoringModifiers: "k"
        )
    )
    button.beginRecording()

    // Act
    button.keyDown(with: event)

    // Assert
    #expect(
        recordedShortcut == GlobalShortcutDefinition(
            keyCode: 40,
            modifierFlags: [.command, .option],
            keyEquivalent: "K"
        )
    )
    #expect(!button.isRecording)
}

@Test @MainActor
func test_keyDown_when_escapeIsPressed_then_cancelsWithoutChangingShortcut() throws {
    // Arrange
    var recordedShortcut: GlobalShortcutDefinition?
    let button = ShortcutRecorderButton(
        definition: .commandShiftT,
        localization: testEnglishLocalization,
        onShortcutRecorded: { recordedShortcut = $0 }
    )
    let event = try #require(
        makeKeyEvent(
            keyCode: 53,
            modifierFlags: [],
            charactersIgnoringModifiers: "\u{1b}"
        )
    )
    button.beginRecording()

    // Act
    button.keyDown(with: event)

    // Assert
    #expect(recordedShortcut == nil)
    #expect(!button.isRecording)
}

@Test @MainActor
func test_keyDown_when_shortcutHasOnlyShiftModifier_then_keepsRecording() throws {
    // Arrange
    var recordedShortcut: GlobalShortcutDefinition?
    let button = ShortcutRecorderButton(
        definition: .commandShiftT,
        localization: testEnglishLocalization,
        onShortcutRecorded: { recordedShortcut = $0 }
    )
    let event = try #require(
        makeKeyEvent(
            keyCode: 0,
            modifierFlags: [.shift],
            charactersIgnoringModifiers: "a"
        )
    )
    button.beginRecording()

    // Act
    button.keyDown(with: event)

    // Assert
    #expect(recordedShortcut == nil)
    #expect(button.isRecording)
}

@Test @MainActor
func test_recording_when_startedAndCancelled_then_reportsBothStateChanges() throws {
    // Arrange
    var recordingStarted = false
    var recordingCancelled = false
    let button = ShortcutRecorderButton(
        definition: .commandShiftT,
        localization: testEnglishLocalization,
        onRecordingStarted: { recordingStarted = true },
        onRecordingCancelled: { recordingCancelled = true },
        onShortcutRecorded: { _ in }
    )
    let event = try #require(
        makeKeyEvent(
            keyCode: 53,
            modifierFlags: [],
            charactersIgnoringModifiers: "\u{1b}"
        )
    )

    // Act
    button.beginRecording()
    button.keyDown(with: event)

    // Assert
    #expect(recordingStarted)
    #expect(recordingCancelled)
}

private func makeKeyEvent(
    keyCode: UInt16,
    modifierFlags: NSEvent.ModifierFlags,
    charactersIgnoringModifiers: String
) -> NSEvent? {
    NSEvent.keyEvent(
        with: .keyDown,
        location: .zero,
        modifierFlags: modifierFlags,
        timestamp: 0,
        windowNumber: 0,
        context: nil,
        characters: charactersIgnoringModifiers,
        charactersIgnoringModifiers: charactersIgnoringModifiers,
        isARepeat: false,
        keyCode: keyCode
    )
}
