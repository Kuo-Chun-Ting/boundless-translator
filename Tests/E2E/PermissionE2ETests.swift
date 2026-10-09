import XCTest

final class PermissionE2ETests: BoundlessTranslatorE2ETestCase {
    private let systemSettings = XCUIApplication(bundleIdentifier: "com.apple.systempreferences")

    func test_translationAction_withoutAccessibilityPermission_thenContinuesToSystemSettings() {
        // Arrange
        systemSettings.terminate()
        launchBoundlessTranslator()
        launchFixture()
        fixtureElement("fixture.selectAccessibilityText").click()

        // Act
        triggerTranslationAction()
        let continueButton = appElement("permissionGuide.continueButton")

        // Assert
        XCTAssertTrue(
            appElement("permissionGuide.title").waitForExistence(timeout: 5)
        )
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.click()
        XCTAssertFalse(continueButton.waitForExistence(timeout: 2))
        assertPermissionSettingsAppear(title: "Accessibility")
    }

    func test_screenshotAction_withoutScreenRecordingPermission_thenRequestsSystemPermission() {
        // Arrange
        systemSettings.terminate()
        launchBoundlessTranslator()
        launchFixture()

        // Act
        triggerScreenshotAction()
        let continueButton = appElement("permissionGuide.continueButton")

        // Assert
        XCTAssertTrue(
            appElement("permissionGuide.title").waitForExistence(timeout: 5)
        )
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.click()
        XCTAssertFalse(continueButton.waitForExistence(timeout: 2))
        let systemPrompt = XCUIApplication(bundleIdentifier: "com.apple.accessibility.universalAccessAuthWarn")
        let openSettings = systemPrompt.buttons["Open System Settings"]
        XCTAssertTrue(openSettings.waitForExistence(timeout: 10))
        openSettings.click()
        assertPermissionSettingsAppear(title: "Screen & System Audio Recording")
    }

    private func assertPermissionSettingsAppear(title: String) {
        XCTAssertTrue(systemSettings.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(
            systemSettings.windows[title].waitForExistence(timeout: 10),
            "System Settings did not open the \(title) permission page."
        )
    }
}
