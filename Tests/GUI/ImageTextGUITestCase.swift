import AppKit
import XCTest

@MainActor
class ImageTextGUITestCase: XCTestCase {
    var fixtureURL: URL!
    var app: XCUIApplication!
    var helper: XCUIApplication!
    let session = UUID().uuidString

    override func setUp() async throws {
        continueAfterFailure = false
        releaseCommand()
        fixtureURL = URL(
            fileURLWithPath: try XCTUnwrap(
                ProcessInfo.processInfo.environment["BOUNDLESS_TRANSLATOR_IMAGE_TEXT_FIXTURE_APP_PATH"]))
        helper = XCUIApplication(
            url: fixtureURL.deletingLastPathComponent().appendingPathComponent(
                "BoundlessTranslatorE2ETestHost.app"))
        helper.launchEnvironment["IMAGE_TEXT_FOCUS_TEST"] = "1"
        helper.launch()
        app = XCUIApplication(url: fixtureURL)
        app.launchEnvironment = [
            "IMAGE_TEXT_SESSION": session,
        ]
        app.launch()
        XCTAssertTrue(
            waitFor {
                self.words().contains { $0.text == "TARGET" }
            })
        XCTAssertLessThan(helper.windows.firstMatch.frame.maxX, imageFrame.minX,
                          "The other app must not cover the screenshot's return targets")
    }

    override func tearDown() async throws {
        app?.terminate()
        helper?.terminate()
    }

    func checkReturn(_ region: String) throws {
        // Arrange
        try select("TARGET")
        switchAway()
        // Act
        let target = try word("TARGET")
        click(region == "text" ? coordinate(target, "center") : point(region))
        move(coordinate(target, "center"))
        // Assert
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 12, y: 11))
        try select("TARGET")
        capture("return-" + region)
    }

    func select(_ text: String) throws {
        let w = try word(text)
        drag(coordinate(w, "start"), coordinate(w, "end"))
        XCTAssertTrue(
            waitFor { self.selectedText == text },
            "Must select \(text), got \(selectedText)")
    }

    func switchAway() {
        let frame = helper.windows.firstMatch.frame
        click(CGPoint(x: frame.maxX - 24, y: frame.midY))
        XCTAssertTrue(waitFor { self.helper.state == .runningForeground })
        XCTAssertTrue(waitFor { self.app.state != .runningForeground })
    }

    var selectedText: String { app.textViews["imageText.selection"].value as? String ?? "" }
    var imageFrame: CGRect { app.groups["imageText.content"].frame }
    var translationWindow: XCUIElement { app.windows["imageText.translation"] }
    var settingsWindow: XCUIElement { app.windows["imageText.settings"] }
    var translationSource: String { translationWindow.textViews["translation.sourceText"].value as? String ?? "" }
    var recognitionPending: Bool { app.images["imageWorkspace.loading"].exists }

    struct Word {
        let text: String
        let line: Int
        let frame: CGRect
    }

    func words() -> [Word] {
        let content = app.groups["imageText.content"]
        guard content.exists, let snapshot = try? content.snapshot() else { return [] }
        return snapshot.children.filter {
            $0.identifier.hasPrefix("imageText.word.")
        }.map { element in
            let line = Int(element.identifier.split(separator: ".")[2])!
            return Word(text: element.label, line: line, frame: element.frame)
        }
    }

    func wordsInLine(containing text: String) throws -> [Word] {
        let recognizedWords = words()
        let anchor = try XCTUnwrap(recognizedWords.first { $0.text.contains(text) })
        return recognizedWords.filter { $0.line == anchor.line }
    }

    func word(_ text: String) throws -> Word {
        try XCTUnwrap(words().first { $0.text == text })
    }

    func coordinate(_ word: Word, _ edge: String) -> CGPoint {
        let x = edge == "start" ? word.frame.minX + 1
            : edge == "end" ? word.frame.maxX - 1 : word.frame.midX
        return CGPoint(x: x, y: word.frame.midY)
    }

    func point(_ region: String) -> CGPoint {
        fixturePoint(35, region == "margin" ? -35 : 220)
    }

    func loadFixture(_ name: String, holdCompletionUntilInactive: Bool = false) throws {
        app.terminate()
        app.launchEnvironment = [
            "IMAGE_TEXT_SESSION": session,
            "IMAGE_TEXT_FIXTURE": name,
            "IMAGE_TEXT_HOLD_UNTIL_INACTIVE": holdCompletionUntilInactive ? "1" : "0",
        ]
        app.launch()
        XCTAssertTrue(app.windows["imageText.screenshot"].waitForExistence(timeout: 8))
        if !holdCompletionUntilInactive {
            XCTAssertTrue(waitFor { self.recognitionPending == false })
        }
    }

    func fixturePoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: imageFrame.minX + x * imageFrame.width / 760,
                y: imageFrame.minY + (360 - y) * imageFrame.height / 360)
    }

    func assertSelected(_ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            waitFor { self.selectedText == expected },
            "Expected \(expected), got \(selectedText)", file: file, line: line)
    }

    func pressTranslate() {
        XCTAssertFalse(selectedText.isEmpty)
        key(36, .maskCommand)
        XCTAssertTrue(waitFor { self.translationWindow.exists })
    }

    func copyPreservingClipboard() throws -> String {
        let board = NSPasteboard.general
        let saved = (board.pasteboardItems ?? []).map { item in
            Dictionary(
                uniqueKeysWithValues: item.types.compactMap { type in
                    item.data(forType: type).map { (type, $0) }
                })
        }
        let oldCount = board.changeCount
        key(8, .maskCommand)
        XCTAssertTrue(waitFor { board.changeCount != oldCount })
        let ownedCount = board.changeCount
        defer {
            if board.changeCount == ownedCount {
                board.clearContents()
                let items = saved.map { values in
                    let item = NSPasteboardItem()
                    for (type, data) in values { item.setData(data, forType: type) }
                    return item
                }
                board.writeObjects(items)
            }
        }
        return try XCTUnwrap(board.string(forType: .string))
    }
    func capture(_ name: String, window: XCUIElement? = nil) {
        let a = XCTAttachment(screenshot: (window ?? app.windows["imageText.screenshot"]).screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }
    func move(_ p: CGPoint) {
        mouse(.mouseMoved, p)
        pause(0.2)
    }
    func click(_ p: CGPoint) {
        move(p)
        mouse(.leftMouseDown, p)
        mouse(.leftMouseUp, p)
        pause(0.2)
    }
    func drag(_ a: CGPoint, _ b: CGPoint) {
        move(a)
        mouse(.leftMouseDown, a)
        for step in 1...12 {
            let t = CGFloat(step) / 12
            mouse(.leftMouseDragged, CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
        }
        mouse(.leftMouseUp, b)
        pause(0.2)
    }
    func mouse(_ type: CGEventType, _ point: CGPoint) {
        let event = CGEvent(
            mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left)!
        event.setIntegerValueField(.mouseEventClickState, value: 1)
        event.flags = []
        event.post(tap: .cghidEventTap)
        pause(0.04)
    }
    func key(_ code: CGKeyCode, _ flags: CGEventFlags = []) {
        for down in [true, false] {
            let e = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down)!
            e.flags = flags
            e.post(tap: .cghidEventTap)
            pause(0.04)
        }
        if flags.contains(.maskCommand) { releaseCommand() }
        pause(0.2)
    }
    func releaseCommand() {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: false)!
        event.type = .flagsChanged
        event.flags = []
        event.post(tap: .cghidEventTap)
        pause(0.04)
    }
    func pause(_ time: Double) { RunLoop.current.run(until: Date(timeIntervalSinceNow: time)) }
    func waitFor(_ condition: @escaping () -> Bool) -> Bool {
        XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)],
            timeout: 8) == .completed
    }
}
