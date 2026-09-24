import AppKit
import XCTest

@MainActor
final class LiveTextSelectionGUITests: XCTestCase {
    private var app: XCUIApplication!
    private var outputDirectory: URL!
    private var points: LiveTextObservedState!
    private var mouseEvent: Int64 = 1000
    private var mousePosition = CGPoint.zero

    override func setUp() async throws {
        continueAfterFailure = true
        let outputRoot = try XCTUnwrap(ProcessInfo.processInfo.environment[
            "BOUNDLESS_TRANSLATOR_LIVE_TEXT_OUTPUT_ROOT"
        ])
        outputDirectory = URL(fileURLWithPath: outputRoot, isDirectory: true)
            .standardizedFileURL.appendingPathComponent(UUID().uuidString)
        let fixturePath = try XCTUnwrap(ProcessInfo.processInfo.environment[
            "BOUNDLESS_TRANSLATOR_LIVE_TEXT_FIXTURE_APP_PATH"
        ])
        app = XCUIApplication(url: URL(fileURLWithPath: fixturePath, isDirectory: true))
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_LIVE_TEXT_FIXTURE_OUTPUT"] = outputDirectory.path
        print("Live Text fixture: \(fixturePath); state directory: \(outputDirectory.path)")
        app.launch()
        points = try requireState("Arrange: OCR must recognize both fixture words") {
            $0.recognizedText.contains("ORIGINAL") && $0.recognizedText.contains("TARGET")
                && $0.selectedText.isEmpty && $0.appActive
        }
    }

    override func tearDown() async throws {
        releaseMouse()
        app?.terminate()
    }

    // Principles 1 + 2: cursor matches the location, and an I-beam permits selection.
    func test_hoverAndSelect_when_freshScreenshot_then_cursorAndSelectionAgree() throws {
        // Arrange: OCR completed; no text selected.
        try requireNoSelection()

        // Act / Assert: blank is arrow.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")

        // Act / Assert: text is I-beam.
        try moveMouse(to: points.textStart)
        try requireCursor("ibeam")

        // Act / Assert: one drag selects the new target word.
        try mouseDown(at: points.textStart)
        defer { releaseMouse() }
        try dragMouse(to: points.textEnd)
        releaseMouse()
        try requireTargetSelection()

        // Act / Assert: leaving text returns to arrow, even with a selection.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")
    }

    func test_hoverAndSelect_when_existingSelection_then_cursorAndSelectionAgree() throws {
        // Arrange: a different word is already selected.
        try selectOriginalWord()

        // Act / Assert: blank is arrow.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")

        // Act / Assert: text is I-beam.
        try moveMouse(to: points.textStart)
        try requireCursor("ibeam")

        // Act / Assert: one drag selects the new target word.
        try mouseDown(at: points.textStart)
        defer { releaseMouse() }
        try dragMouse(to: points.textEnd)
        releaseMouse()
        try requireTargetSelection()

        // Act / Assert: leaving text returns to arrow, even with a selection.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")
    }

    func test_hoverAndSelect_when_translationClosed_then_cursorAndSelectionAgree() throws {
        // Arrange: translation closed; the original selection remains.
        try selectOriginalWord()
        try openAndCloseTranslation()

        // Act / Assert: blank is arrow.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")

        // Act / Assert: text is I-beam.
        try moveMouse(to: points.textStart)
        try requireCursor("ibeam")

        // Act / Assert: one drag selects the new target word.
        try mouseDown(at: points.textStart)
        defer { releaseMouse() }
        try dragMouse(to: points.textEnd)
        releaseMouse()
        try requireTargetSelection()

        // Act / Assert: leaving text returns to arrow, even with a selection.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")
    }

    func test_hoverAndSelect_when_selectionCleared_then_cursorAndSelectionAgree() throws {
        // Arrange: translation closed; a blank click cleared the original selection.
        try selectOriginalWord()
        try openAndCloseTranslation()
        try clickBlankAndRequireClearedSelection()

        // Act / Assert: blank is arrow.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")

        // Act / Assert: text is I-beam.
        try moveMouse(to: points.textStart)
        try requireCursor("ibeam")

        // Act / Assert: one drag selects the new target word.
        try mouseDown(at: points.textStart)
        defer { releaseMouse() }
        try dragMouse(to: points.textEnd)
        releaseMouse()
        try requireTargetSelection()

        // Act / Assert: leaving text returns to arrow, even with a selection.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")
    }

    func test_hoverAndSelect_when_returnedFromAnotherApp_then_cursorAndSelectionAgree() throws {
        // Arrange: switched to Finder, then returned to the screenshot app.
        try switchToFinderAndBack()
        try requireNoSelection()

        // Act / Assert: blank is arrow.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")

        // Act / Assert: text is I-beam.
        try moveMouse(to: points.textStart)
        try requireCursor("ibeam")

        // Act / Assert: one drag selects the new target word.
        try mouseDown(at: points.textStart)
        defer { releaseMouse() }
        try dragMouse(to: points.textEnd)
        releaseMouse()
        try requireTargetSelection()

        // Act / Assert: leaving text returns to arrow, even with a selection.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")
    }

    // Principle 3: a drag starting on blank space can enter text and select it.
    func test_dragFromBlank_when_freshScreenshot_then_selectsBeforeMouseUp() throws {
        // Arrange: OCR completed; no text selected.
        try requireNoSelection()

        // Act / Assert: the drag starts on blank space INSIDE the screenshot.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")

        // Act: keep the mouse button held while entering and crossing the text.
        try mouseDown(at: points.blank)
        defer { releaseMouse() }
        try dragMouse(to: points.textEnd)

        // Assert: text shows I-beam and TARGET is selected BEFORE mouse-up.
        try requireCursor("ibeam")
        try requireTargetSelection()
    }

    func test_dragFromBlank_when_existingSelection_then_selectsBeforeMouseUp() throws {
        // Arrange: a different word is already selected.
        try selectOriginalWord()

        // Act / Assert: the drag starts on blank space INSIDE the screenshot.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")

        // Act: keep the mouse button held while entering and crossing the text.
        try mouseDown(at: points.blank)
        defer { releaseMouse() }
        try dragMouse(to: points.textEnd)

        // Assert: text shows I-beam and TARGET is selected BEFORE mouse-up.
        try requireCursor("ibeam")
        try requireTargetSelection()
    }

    func test_dragFromBlank_when_translationClosed_then_selectsBeforeMouseUp() throws {
        // Arrange: translation closed; the original selection remains.
        try selectOriginalWord()
        try openAndCloseTranslation()

        // Act / Assert: the drag starts on blank space INSIDE the screenshot.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")

        // Act: keep the mouse button held while entering and crossing the text.
        try mouseDown(at: points.blank)
        defer { releaseMouse() }
        try dragMouse(to: points.textEnd)

        // Assert: text shows I-beam and TARGET is selected BEFORE mouse-up.
        try requireCursor("ibeam")
        try requireTargetSelection()
    }

    func test_dragFromBlank_when_selectionCleared_then_selectsBeforeMouseUp() throws {
        // Arrange: translation closed; a blank click cleared the original selection.
        try selectOriginalWord()
        try openAndCloseTranslation()
        try clickBlankAndRequireClearedSelection()

        // Act / Assert: the drag starts on blank space INSIDE the screenshot.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")

        // Act: keep the mouse button held while entering and crossing the text.
        try mouseDown(at: points.blank)
        defer { releaseMouse() }
        try dragMouse(to: points.textEnd)

        // Assert: text shows I-beam and TARGET is selected BEFORE mouse-up.
        try requireCursor("ibeam")
        try requireTargetSelection()
    }

    func test_dragFromBlank_when_returnedFromAnotherApp_then_selectsBeforeMouseUp() throws {
        // Arrange: switched to Finder, then returned to the screenshot app.
        try switchToFinderAndBack()
        try requireNoSelection()

        // Act / Assert: the drag starts on blank space INSIDE the screenshot.
        try moveMouse(to: points.blank)
        try requireCursor("arrow")

        // Act: keep the mouse button held while entering and crossing the text.
        try mouseDown(at: points.blank)
        defer { releaseMouse() }
        try dragMouse(to: points.textEnd)

        // Assert: text shows I-beam and TARGET is selected BEFORE mouse-up.
        try requireCursor("ibeam")
        try requireTargetSelection()
    }

    private func selectOriginalWord() throws {
        // Establish history through real mouse input, never overlay selection setters.
        try moveMouse(to: points.original)
        try click(at: points.original, clickCount: 1)
        try click(at: points.original, clickCount: 2)
        _ = try requireState("Arrange: double-click must select ORIGINAL") {
            $0.selectedText.trimmingCharacters(in: .whitespacesAndNewlines) == "ORIGINAL"
        }
    }

    private func openAndCloseTranslation() throws {
        app.typeKey("t", modifierFlags: [.command, .shift])
        _ = try requireState("Arrange: production translation window must open") { $0.translationVisible }
        let translation = app.windows["liveText.translation"]
        XCTAssertTrue(translation.waitForExistence(timeout: 5))
        translation.buttons[XCUIIdentifierCloseWindow].click()
        _ = try requireState("Arrange: translation must close WITHOUT clearing ORIGINAL") {
            !$0.translationVisible && $0.selectedText.trimmingCharacters(in: .whitespacesAndNewlines) == "ORIGINAL"
        }
    }

    private func clickBlankAndRequireClearedSelection() throws {
        try click(at: points.blank)
        _ = try requireState("Arrange failed: blank click did not clear selection") {
            $0.selectedText.isEmpty
        }
    }

    private func switchToFinderAndBack() throws {
        let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")
        finder.activate()
        _ = try requireState("Arrange: screenshot app must lose activation") { !$0.appActive }
        app.activate()
        _ = try requireState("Arrange: screenshot app must regain activation") { $0.appActive }
    }

    private func requireNoSelection() throws {
        _ = try requireState("Expected no selected text") { $0.selectedText.isEmpty }
    }

    private func requireTargetSelection() throws {
        _ = try requireState("Expected newly selected TARGET, not the old ORIGINAL selection") {
            $0.selectedText.trimmingCharacters(in: .whitespacesAndNewlines) == "TARGET"
        }
    }

    private func requireCursor(_ cursor: String) throws {
        _ = try requireState("Expected cursor: \(cursor)") { $0.cursor == cursor }
    }

    private func moveMouse(to point: CGPoint) throws {
        let window = app.windows["liveText.screenshot"]
        let frame = window.frame
        window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: point.x - frame.minX, dy: point.y - frame.minY
        )).hover()
        mousePosition = point
    }

    private func mouseDown(at point: CGPoint) throws {
        try postMouse(.leftMouseDown, at: point)
    }

    private func dragMouse(to end: CGPoint) throws {
        let start = mousePosition
        // Intermediate events model a continuous drag. No release occurs here.
        for step in 1...12 {
            let fraction = CGFloat(step) / 12
            try postMouse(.leftMouseDragged, at: CGPoint(
                x: start.x + (end.x - start.x) * fraction,
                y: start.y + (end.y - start.y) * fraction
            ))
        }
    }

    private func click(at point: CGPoint, clickCount: Int64 = 1) throws {
        try postMouse(.leftMouseDown, at: point, clickCount: clickCount)
        try postMouse(.leftMouseUp, at: point, clickCount: clickCount)
    }

    private func releaseMouse() {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                                  mouseCursorPosition: mousePosition, mouseButton: .left) else { return }
        event.post(tap: .cghidEventTap)
    }

    private func postMouse(_ type: CGEventType, at point: CGPoint, clickCount: Int64 = 1) throws {
        guard CGPreflightPostEventAccess() else {
            XCTFail("Test runner lacks permission to send mouse events; no product behavior has been tested")
            throw LiveTextObservationError.mouseEventPermissionMissing
        }
        let event = try XCTUnwrap(CGEvent(mouseEventSource: nil, mouseType: type,
                                          mouseCursorPosition: point, mouseButton: .left))
        mouseEvent += 1
        mousePosition = point
        event.setIntegerValueField(.eventSourceUserData, value: mouseEvent)
        event.setIntegerValueField(.mouseEventClickState, value: clickCount)
        event.post(tap: .cghidEventTap)
        let expectedEvent = mouseEvent
        _ = try requireState("Mouse event \(expectedEvent) must reach screenshot app") {
            $0.lastMouseEvent == expectedEvent
        }
    }

    @discardableResult
    private func requireState(
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        matching predicate: (LiveTextObservedState) -> Bool
    ) throws -> LiveTextObservedState {
        let started = Date().timeIntervalSince1970
        let deadline = Date(timeIntervalSinceNow: 5)
        var latest: LiveTextObservedState?
        repeat {
            if let data = try? Data(contentsOf: outputDirectory.appendingPathComponent("state.json")),
               let state = try? JSONDecoder().decode(LiveTextObservedState.self, from: data) {
                latest = state
                if state.sampleTime >= started, predicate(state) { return state }
            }
            // Poll observable state; elapsed time is never the success criterion.
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
        } while Date() < deadline
        XCTFail("\(message). Last observed state: \(String(describing: latest))", file: file, line: line)
        throw LiveTextObservationError.conditionNotReached
    }
}

private struct LiveTextObservedState: Decodable {
    let sampleTime: TimeInterval
    let recognizedText: String
    let selectedText: String
    let cursor: String
    let lastMouseEvent: Int64
    let translationVisible: Bool
    let appActive: Bool
    let blank: CGPoint
    let textStart: CGPoint
    let textEnd: CGPoint
    let original: CGPoint
}

private enum LiveTextObservationError: Error {
    case conditionNotReached
    case mouseEventPermissionMissing
}
