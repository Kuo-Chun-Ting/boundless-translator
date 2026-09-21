import AppKit
import Carbon.HIToolbox
import Foundation
import XCTest

@MainActor
class BoundlessTranslatorE2ETestCase: XCTestCase {
    var boundlessTranslator: XCUIApplication!
    var fixture: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        guard let appPath = ProcessInfo.processInfo.environment[
            "BOUNDLESS_TRANSLATOR_E2E_APP_PATH"
        ] else {
            throw E2ETestConfigurationError.missingApplicationPath
        }
        guard FileManager.default.fileExists(atPath: appPath) else {
            throw E2ETestConfigurationError.applicationDoesNotExist(appPath)
        }

        boundlessTranslator = XCUIApplication(
            url: URL(fileURLWithPath: appPath, isDirectory: true)
        )
        fixture = XCUIApplication()
    }

    override func tearDownWithError() throws {
        fixture?.terminate()
        boundlessTranslator?.terminate()
        _ = boundlessTranslator?.wait(for: .notRunning, timeout: 5)
    }

    func launchBoundlessTranslator(usingBaselinePreferences: Bool = true) {
        boundlessTranslator.launchArguments = usingBaselinePreferences
            ? Self.baselinePreferenceArguments
            : []
        boundlessTranslator.launch()
        XCTAssertTrue(
            boundlessTranslator.wait(for: .runningForeground, timeout: 10),
            "Boundless Translator did not reach the foreground."
        )
    }

    func launchFixture() {
        fixture.launch()
        XCTAssertTrue(
            fixture.windows["Boundless Translator E2E Fixture"]
                .waitForExistence(timeout: 5),
            "The E2E fixture window did not appear."
        )
    }

    func triggerTranslationAction() {
        postGlobalShortcut(keyCode: Self.translationShortcutKeyCode)
    }

    func triggerScreenshotAction() {
        postGlobalShortcut(keyCode: Self.screenshotShortcutKeyCode)
    }

    func appElement(_ accessibilityIdentifier: String) -> XCUIElement {
        boundlessTranslator.descendants(matching: .any)[accessibilityIdentifier]
    }

    func fixtureElement(_ accessibilityIdentifier: String) -> XCUIElement {
        fixture.descendants(matching: .any)[accessibilityIdentifier]
    }

    func stringValue(of element: XCUIElement) -> String {
        if let value = element.value as? String {
            return value
        }
        return element.label
    }

    private func postGlobalShortcut(keyCode: CGKeyCode) {
        guard CGPreflightPostEventAccess() else {
            XCTFail("The E2E Test Runner cannot post system keyboard events.")
            return
        }
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            XCTFail("Could not create the global-shortcut keyboard events.")
            return
        }

        let modifierKeys: [(keyCode: CGKeyCode, flag: CGEventFlags)] = [
            (CGKeyCode(kVK_Control), .maskControl),
            (CGKeyCode(kVK_Option), .maskAlternate),
            (CGKeyCode(kVK_Shift), .maskShift),
            (CGKeyCode(kVK_Command), .maskCommand),
        ]

        var activeFlags: CGEventFlags = []
        for modifier in modifierKeys {
            activeFlags.insert(modifier.flag)
            postKeyEvent(
                source: source,
                keyCode: modifier.keyCode,
                keyDown: true,
                flags: activeFlags
            )
        }

        postKeyEvent(source: source, keyCode: keyCode, keyDown: true, flags: activeFlags)
        postKeyEvent(source: source, keyCode: keyCode, keyDown: false, flags: activeFlags)

        for modifier in modifierKeys.reversed() {
            activeFlags.remove(modifier.flag)
            postKeyEvent(
                source: source,
                keyCode: modifier.keyCode,
                keyDown: false,
                flags: activeFlags
            )
        }
    }

    private func postKeyEvent(
        source: CGEventSource,
        keyCode: CGKeyCode,
        keyDown: Bool,
        flags: CGEventFlags
    ) {
        guard let event = CGEvent(
            keyboardEventSource: source,
            virtualKey: keyCode,
            keyDown: keyDown
        ) else {
            XCTFail("Could not create the global-shortcut keyboard event.")
            return
        }
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }

    private static let baselinePreferenceArguments = [
        "-sourceLanguageIdentifier", "en",
        "-targetLanguageIdentifier", "zh-Hant",
        "-interfaceLanguageIdentifier", "zh-Hant",
        "-globalShortcutKeyCode", String(translationShortcutKeyCode),
        "-globalShortcutModifiers", String(shortcutModifierFlags.rawValue),
        "-screenshotShortcutKeyCode", String(screenshotShortcutKeyCode),
        "-screenshotShortcutModifiers", String(shortcutModifierFlags.rawValue)
    ]

    private static let translationShortcutKeyCode = CGKeyCode(kVK_ANSI_7)
    private static let screenshotShortcutKeyCode = CGKeyCode(kVK_ANSI_8)

    private static let shortcutModifierFlags: NSEvent.ModifierFlags = [
        .command, .option, .control, .shift,
    ]
}

private enum E2ETestConfigurationError: Error, CustomStringConvertible {
    case missingApplicationPath
    case applicationDoesNotExist(String)

    var description: String {
        switch self {
        case .missingApplicationPath:
            "BOUNDLESS_TRANSLATOR_E2E_APP_PATH is not set. Run Scripts/run_e2e_tests.sh."
        case .applicationDoesNotExist(let path):
            "The configured E2E application does not exist: \(path)"
        }
    }
}
