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

@Test @MainActor
func test_recording_when_windowCloses_then_cancelsAndKeepsOriginalShortcut() {
    // Arrange
    var cancellationCount = 0
    let button = ShortcutRecorderButton(
        definition: .commandShiftT,
        localization: testEnglishLocalization,
        onRecordingCancelled: { cancellationCount += 1 },
        onShortcutRecorded: { _ in Issue.record("Closing must not save a shortcut") }
    )
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 200, height: 80),
        styleMask: [.titled, .closable], backing: .buffered, defer: false
    )
    window.isReleasedWhenClosed = false
    window.contentView = button
    button.beginRecording()

    // Act
    window.close()

    // Assert
    #expect(!button.isRecording)
    #expect(cancellationCount == 1)
    #expect(button.title == "⇧⌘T")
}

@Test @MainActor
func test_recording_when_windowResignsKey_then_cancelsOnlyOnce() {
    // Arrange
    var cancellationCount = 0
    let button = ShortcutRecorderButton(
        definition: .commandShiftT,
        localization: testEnglishLocalization,
        onRecordingCancelled: { cancellationCount += 1 },
        onShortcutRecorded: { _ in Issue.record("Losing focus must not save a shortcut") }
    )
    let window = NSWindow()
    window.isReleasedWhenClosed = false
    window.contentView = button
    button.beginRecording()

    // Act
    NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)
    window.close()

    // Assert
    #expect(!button.isRecording)
    #expect(cancellationCount == 1)
    #expect(button.title == "⇧⌘T")
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
