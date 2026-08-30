import Foundation
import XCTest

final class DictionaryLookupCursorGUITests: XCTestCase {
    private var app: XCUIApplication!
    private var outputDirectory: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        app = XCUIApplication()
        app.launchEnvironment["BOUNDLESS_TRANSLATOR_CURSOR_HOST_OUTPUT"] =
            outputDirectory.path
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        try? FileManager.default.removeItem(at: outputDirectory)
    }

    func test_lookupAction_whenHoveringFifthLineRepeatedly_thenShowsPointingHand() throws {
        // Arrange
        let lookupAction = app.buttons["Look Up in Dictionary"]
        XCTAssertTrue(lookupAction.waitForExistence(timeout: 5))
        let readyState: CursorHostReadyState = try waitForJSON(
            named: "ready.json",
            timeout: 5
        )
        XCTAssertEqual(readyState.selectedLine, 5)
        let moveAway = lookupAction.coordinate(
            withNormalizedOffset: CGVector(dx: -2, dy: -2)
        )

        for attempt in 1...3 {
            // Act
            moveAway.hover()
            _ = try waitForCursor(isPointingHand: false)
            lookupAction.hover()
            let cursorState = try waitForCursor(isPointingHand: true)

            // Assert
            XCTAssertTrue(
                cursorState.lookupButtonOwnsHitTest,
                "Attempt \(attempt): the fifth-line lookup action did not own hit testing"
            )
        }
    }

    private func waitForCursor(
        isPointingHand: Bool
    ) throws -> CursorHostState {
        let deadline = Date(timeIntervalSinceNow: 2)
        var latestState: CursorHostState?

        while Date() < deadline {
            if let state: CursorHostState = try? decodeJSON(named: "cursor.json") {
                latestState = state
                if state.isPointingHand == isPointingHand {
                    return state
                }
            }
            Thread.sleep(forTimeInterval: 0.02)
        }

        throw CursorGUITestError.cursorTimedOut(
            expectedPointingHand: isPointingHand,
            latestState: latestState
        )
    }

    private func waitForJSON<Value: Decodable>(
        named fileName: String,
        timeout: TimeInterval
    ) throws -> Value {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while Date() < deadline {
            if let value: Value = try? decodeJSON(named: fileName) {
                return value
            }
            Thread.sleep(forTimeInterval: 0.02)
        }
        throw CursorGUITestError.fileTimedOut(fileName)
    }

    private func decodeJSON<Value: Decodable>(
        named fileName: String
    ) throws -> Value {
        let url = outputDirectory.appendingPathComponent(fileName)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Value.self, from: data)
    }
}

private struct CursorHostReadyState: Decodable {
    let selectedLine: Int
}

private struct CursorHostState: Decodable {
    let isPointingHand: Bool
    let lookupButtonOwnsHitTest: Bool
}

private enum CursorGUITestError: Error {
    case fileTimedOut(String)
    case cursorTimedOut(
        expectedPointingHand: Bool,
        latestState: CursorHostState?
    )
}
