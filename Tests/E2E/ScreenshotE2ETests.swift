import AppKit
import ApplicationServices
import XCTest

final class ScreenshotE2ETests: BoundlessTranslatorE2ETestCase {
    func test_screenshotPreview_when_hoveringRecognizedWord_then_showsAppleTranslation() throws {
        // Arrange
        launchBoundlessTranslator()
        launchFixture()
        captureFixtureScreenshot()
        let workspace = appElement("imageWorkspace.text")
        XCTAssertTrue(workspace.waitForExistence(timeout: 10))
        // Act
        let word = workspace.coordinate(withNormalizedOffset: CGVector(dx: 0.32, dy: 0.18)).screenPoint
        postMouseEvent(.mouseMoved, at: word)
        // Assert: this is the quick card, not the full translation window.
        let result = appElement("screenshotPreview.translation")
        XCTAssertTrue(waitUntil(timeout: 60) {
            result.exists && !self.stringValue(of: result).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        })
        XCTAssertFalse(appElement("translation.sourceText").exists)
        attachScreen("screenshot-hover-translation", window: boundlessTranslator.dialogs["screenshotPreview"])
    }

    func test_screenshotTranslation_whenReturningAfterTranslation_thenTranslatesSelectedText() throws {
        // Arrange
        let screenshot = try prepareScreenshotAfterReturningFromAnotherApp()
        try establishTextSelection(in: screenshot)

        // Act
        triggerTranslationAction()

        // Assert
        XCTAssertTrue(waitForTranslation(of: "SCREENSHOT SAMPLE"), "The shortcut must translate text that is already selected.")
        attachScreen("translation-after-returning", window: boundlessTranslator.windows
            .containing(.any, identifier: "translation.sourceText").firstMatch)
    }

    func test_settings_whenReopenedAfterScreenshotTranslationAndAppSwitch_thenReceivesKeyboardFocus() throws {
        // Arrange
        _ = try prepareScreenshotAfterReturningFromAnotherApp()

        // Act
        try reopenBoundless()

        // Assert
        XCTAssertTrue(waitUntil { self.settingsHasKeyboardFocus() },
                      "Settings must receive keyboard focus without an extra click or activation request.")
        attachScreen("settings-after-reopening", window: boundlessTranslator.windows["Boundless Translator 設定"])
    }

    private var screenshotWindow: XCUIElement {
        boundlessTranslator.windows["截圖翻譯"]
    }

    private func prepareScreenshotAfterReturningFromAnotherApp() throws -> ScreenshotSelection {
        launchBoundlessTranslator()
        launchFixture()
        captureFixtureScreenshot()
        let screenshot = try establishInitialScreenshotSelection()
        triggerTranslationAction()
        XCTAssertTrue(waitForTranslation(of: "SAMPLE"), "Setup: the screenshot must translate successfully before switching apps.")
        let fixtureFrame = fixture.windows["Boundless Translator E2E Fixture"].frame
        postMouseClick(at: CGPoint(x: fixtureFrame.midX, y: fixtureFrame.minY + 10))
        XCTAssertTrue(fixture.wait(for: .runningForeground, timeout: 5),
                      "Setup: clicking the fixture must switch to the other app.")
        XCTAssertTrue(waitUntil { !self.appElement("translation.sourceText").exists })
        XCTAssertTrue(screenshot.workspace.exists)
        // XCUI clicks activate the app automatically; use physical mouse events instead.
        postMouseClick(at: screenshot.returnPoint)
        let initialCoverage = try screenshot.highlight.coverage(in: screenshot.workspace.screenshot())
        XCTAssertLessThan(initialCoverage, 0.9, "Setup: the entire sentence must not already be selected.")
        return screenshot
    }

    private func establishInitialScreenshotSelection() throws -> ScreenshotSelection {
        let workspace = appElement("imageWorkspace.text")
        XCTAssertTrue(workspace.waitForExistence(timeout: 10))
        // The fixture's first glyph starts at 13.5% of the image width.
        // Begin inside the first glyph of SAMPLE.
        let start = workspace.coordinate(withNormalizedOffset: CGVector(dx: 0.14, dy: 0.18)).screenPoint
        let end = workspace.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.18)).screenPoint
        let returnPoint = workspace.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.18)).screenPoint
        let unselected = workspace.screenshot()
        postMouseDrag(from: start, to: end)
        let highlight = try SelectionHighlightReference(unselected: unselected, selected: workspace.screenshot())
        XCTAssertGreaterThan(highlight.points.count, 20, "The initial selection must have a visible highlight.")
        // Translate just one word initially, so retaining it cannot satisfy the next full-sentence drag.
        let sampleWord = workspace.coordinate(withNormalizedOffset: CGVector(dx: 0.70, dy: 0.18)).screenPoint
        postMouseClick(at: sampleWord, count: 2)
        return ScreenshotSelection(workspace: workspace, selectionStart: start, selectionEnd: end,
                                   returnPoint: returnPoint, highlight: highlight)
    }

    private func dragToSelectText(in screenshot: ScreenshotSelection) throws -> Double {
        postMouseDrag(from: screenshot.selectionStart, to: screenshot.selectionEnd)
        let coverage = try screenshot.highlight.coverage(in: screenshot.workspace.screenshot())
        return coverage
    }

    private func establishTextSelection(in screenshot: ScreenshotSelection) throws {
        let coverage = try dragToSelectText(in: screenshot)
        attachScreen("first-drag", window: screenshotWindow)
        XCTAssertGreaterThan(coverage, 0.9, "The first drag must select text before translation can be tested.")
    }

    private func waitForTranslation(of expectedSource: String) -> Bool {
        waitUntil(timeout: 60) {
            let source = self.appElement("translation.sourceText")
            let target = self.appElement("translation.targetText")
            return source.exists && self.stringValue(of: source).trimmingCharacters(in: .whitespacesAndNewlines) == expectedSource
                && target.exists && !self.stringValue(of: target).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func reopenBoundless() throws {
        let appURL = URL(fileURLWithPath: try XCTUnwrap(ProcessInfo.processInfo.environment["BOUNDLESS_TRANSLATOR_E2E_APP_PATH"]))
        let opened = expectation(description: "Reopen Boundless as Finder does")
        NSWorkspace.shared.openApplication(at: appURL, configuration: .init()) { _, error in
            XCTAssertNil(error)
            opened.fulfill()
        }
        wait(for: [opened], timeout: 10)
    }

    private var runningBoundless: NSRunningApplication {
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.lillard.BoundlessTranslator.e2e").first!
    }

    private func settingsHasKeyboardFocus() -> Bool {
        let active = runningBoundless.isActive
        let app = AXUIElementCreateApplication(runningBoundless.processIdentifier)
        guard let focused = axValue(app, kAXFocusedWindowAttribute) else { return false }
        let title = axValue(focused as! AXUIElement, kAXTitleAttribute) as? String
        return active && title == "Boundless Translator 設定"
    }

    private func axValue(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value
    }

    private func waitUntil(timeout: TimeInterval = 10, _ condition: @escaping () -> Bool) -> Bool {
        let observed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
        return XCTWaiter.wait(for: [observed], timeout: timeout) == .completed
    }

    private func attachScreen(_ name: String, window: XCUIElement) {
        guard window.exists else { return }
        let attachment = XCTAttachment(screenshot: window.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func postMouseDrag(from start: CGPoint, to end: CGPoint) {
        postMouseEvent(.leftMouseDown, at: start)
        for step in 1...20 {
            let fraction = CGFloat(step) / 20
            postMouseEvent(.leftMouseDragged, at: CGPoint(
                x: start.x + (end.x - start.x) * fraction,
                y: start.y + (end.y - start.y) * fraction
            ))
        }
        postMouseEvent(.leftMouseUp, at: end)
    }

    private func postMouseEvent(_ type: CGEventType, at point: CGPoint) {
        XCTAssertTrue(CGPreflightPostEventAccess(), "Test runner must be allowed to send mouse events.")
        let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left)!
        event.setIntegerValueField(.mouseEventClickState, value: 1)
        event.post(tap: .cghidEventTap)
        RunLoop.current.run(until: Date().addingTimeInterval(0.04))
    }

    private func postMouseClick(at point: CGPoint, count: Int = 1) {
        // XCUIElement.click() activates the app before clicking, which hides
        // failures to activate when returning to an existing screenshot.
        let source = CGEventSource(stateID: .hidSystemState)!
        for click in 1...count {
            for type in [CGEventType.leftMouseDown, .leftMouseUp] {
                let event = CGEvent(
                    mouseEventSource: source, mouseType: type,
                    mouseCursorPosition: point, mouseButton: .left
                )!
                event.setIntegerValueField(.mouseEventClickState, value: Int64(click))
                event.post(tap: .cghidEventTap)
                RunLoop.current.run(until: Date().addingTimeInterval(0.06))
            }
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
    }

    private func captureFixtureScreenshot() {
        let sample = fixtureElement("fixture.screenshotSample")
        XCTAssertTrue(sample.waitForExistence(timeout: 5))
        let start = sample.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).screenPoint
        let end = sample.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 1)).screenPoint
        triggerScreenshotAction()
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        postMouseDrag(from: start, to: end)
    }
}

@MainActor
private struct ScreenshotSelection {
    let workspace: XCUIElement
    let selectionStart: CGPoint
    let selectionEnd: CGPoint
    let returnPoint: CGPoint
    let highlight: SelectionHighlightReference
}

// Observe selection without Copy or any keyboard operation that could change focus.
@MainActor
private struct SelectionHighlightReference {
    let original: NSBitmapImageRep
    let points: [(x: Int, y: Int)]

    init(unselected: XCUIScreenshot, selected: XCUIScreenshot) throws {
        original = try XCTUnwrap(NSBitmapImageRep(data: unselected.pngRepresentation))
        let reference = try XCTUnwrap(NSBitmapImageRep(data: selected.pngRepresentation))
        var changed: [(x: Int, y: Int)] = []
        for y in stride(from: 0, to: original.pixelsHigh, by: 8) {
            for x in stride(from: 0, to: original.pixelsWide, by: 8) {
                let before = original.colorAt(x: x, y: y)!.usingColorSpace(.sRGB)!
                let after = reference.colorAt(x: x, y: y)!.usingColorSpace(.sRGB)!
                if min(before.redComponent, before.greenComponent, before.blueComponent) > 0.9,
                   Self.distance(before, after) > 0.12 {
                    changed.append((x, y))
                }
            }
        }
        points = changed
    }

    func coverage(in screenshot: XCUIScreenshot) throws -> Double {
        let current = try XCTUnwrap(NSBitmapImageRep(data: screenshot.pngRepresentation))
        guard current.pixelsWide == original.pixelsWide,
              current.pixelsHigh == original.pixelsHigh else {
            throw HighlightObservationError.imageSizeChanged
        }
        let highlighted = points.filter { point in
            let before = original.colorAt(x: point.x, y: point.y)!.usingColorSpace(.sRGB)!
            let after = current.colorAt(x: point.x, y: point.y)!.usingColorSpace(.sRGB)!
            return Self.distance(before, after) > 0.06
        }.count
        return Double(highlighted) / Double(max(points.count, 1))
    }

    private static func distance(_ first: NSColor, _ second: NSColor) -> CGFloat {
        max(abs(first.redComponent - second.redComponent),
            abs(first.greenComponent - second.greenComponent),
            abs(first.blueComponent - second.blueComponent))
    }
}

private enum HighlightObservationError: Error {
    case imageSizeChanged
}
