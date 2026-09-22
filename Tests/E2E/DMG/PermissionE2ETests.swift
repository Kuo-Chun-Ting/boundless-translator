import XCTest

final class PermissionE2ETests: BoundlessTranslatorE2ETestCase {
    func test_translationAction_withoutAccessibilityPermission_thenContinuesToSystemSettings() {
        // Arrange
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
    }

    func test_screenshotAction_withoutScreenRecordingPermission_thenRequestsSystemPermission() {
        // Arrange
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
    }
}
