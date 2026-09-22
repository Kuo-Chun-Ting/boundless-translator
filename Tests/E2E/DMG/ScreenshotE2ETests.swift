import XCTest

final class ScreenshotE2ETests: BoundlessTranslatorE2ETestCase {
    func test_screenshotAction_whenFixtureRegionIsCaptured_thenRoutesLiveTextSelectionToTranslation() {
        // Arrange
        launchBoundlessTranslator()
        launchFixture()

        // Act
        captureFixtureScreenshot()
        let workspace = appElement("imageWorkspace.liveText")
        XCTAssertTrue(workspace.waitForExistence(timeout: 10))
        workspace.coordinate(
            withNormalizedOffset: CGVector(dx: 0.70, dy: 0.18)
        ).doubleClick()
        triggerTranslationAction()

        // Assert
        let sourceText = appElement("translation.sourceText")
        XCTAssertTrue(sourceText.waitForExistence(timeout: 10))
        XCTAssertFalse(stringValue(of: sourceText).isEmpty)
    }

    private func captureFixtureScreenshot() {
        let sample = fixtureElement("fixture.screenshotSample")
        XCTAssertTrue(sample.waitForExistence(timeout: 5))
        let start = sample.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.10))
        let end = sample.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.90))
        triggerScreenshotAction()
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
