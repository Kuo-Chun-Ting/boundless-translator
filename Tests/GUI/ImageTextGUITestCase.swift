import AppKit
import XCTest

@MainActor
class ImageTextGUITestCase: XCTestCase {
    var outputDirectory: URL!
    var fixtureURL: URL!
    var app: XCUIApplication!
    var helper: XCUIApplication!
    var token = UUID().uuidString

    override func setUp() async throws {
        continueAfterFailure = false
        releaseCommand()
        fixtureURL = URL(
            fileURLWithPath: try XCTUnwrap(
                ProcessInfo.processInfo.environment["BOUNDLESS_TRANSLATOR_IMAGE_TEXT_FIXTURE_APP_PATH"]))
        let outputRoot = URL(
            fileURLWithPath: try XCTUnwrap(
                ProcessInfo.processInfo.environment["BOUNDLESS_TRANSLATOR_IMAGE_TEXT_OUTPUT_ROOT"]))
        outputDirectory = outputRoot.appendingPathComponent(token)
        helper = XCUIApplication(
            url: fixtureURL.deletingLastPathComponent().appendingPathComponent(
                "BoundlessTranslatorE2ETestHost.app"))
        helper.launch()
        let helperFrame = helper.windows.firstMatch.frame
        // Keep only a left-edge strip visible, so the foreground helper cannot cover return targets.
        drag(CGPoint(x: helperFrame.midX, y: helperFrame.minY + 12),
             CGPoint(x: 120 - helperFrame.width / 2, y: helperFrame.minY + 12))
        app = XCUIApplication(url: fixtureURL)
        app.launchEnvironment = [
            "BOUNDLESS_TRANSLATOR_IMAGE_TEXT_FIXTURE_OUTPUT": outputDirectory.path,
            "IMAGE_TEXT_TOKEN": token,
        ]
        app.launch()
        XCTAssertTrue(
            waitFor {
                self.state()["token"] as? String == self.token
                    && self.words().contains { $0["text"] as? String == "TARGET" }
            })
        let imageFrame = state()["imageFrame"] as! [Double]
        XCTAssertLessThan(helper.windows.firstMatch.frame.maxX, imageFrame[0],
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
        XCTAssertEqual(state()["active"] as? Bool, true)
        XCTAssertEqual(state()["selectionResponder"] as? Bool, true)
        XCTAssertEqual(NSCursor.currentSystem?.hotSpot, NSPoint(x: 12, y: 11))
        try select("TARGET")
        capture("return-" + region)
    }

    func select(_ text: String) throws {
        let w = try word(text)
        drag(coordinate(w, "start"), coordinate(w, "end"))
        XCTAssertTrue(
            waitFor { self.state()["selected"] as? String == text },
            "Must select \(text), got \(state()["selected"] ?? "nil")")
    }

    func switchAway() {
        let frame = helper.windows.firstMatch.frame
        click(CGPoint(x: frame.maxX - 24, y: frame.midY))
        XCTAssertTrue(waitFor { self.state()["active"] as? Bool == false })
    }

    func state() -> [String: Any] {
        guard let data = try? Data(contentsOf: outputDirectory.appendingPathComponent("state.json"))
        else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }
    func words() -> [[String: Any]] { state()["words"] as? [[String: Any]] ?? [] }
    func word(_ text: String) throws -> [String: Any] {
        try XCTUnwrap(words().first { $0["text"] as? String == text })
    }
    func coordinate(_ object: [String: Any], _ key: String) -> CGPoint {
        let xy = object[key] as! [Double]
        return CGPoint(x: xy[0], y: xy[1])
    }
    func point(_ key: String) -> CGPoint { coordinate(state(), key) }

    func loadFixture(_ name: String, holdCompletionUntilInactive: Bool = false) throws {
        app.terminate()
        token = UUID().uuidString
        app.launchEnvironment = [
            "BOUNDLESS_TRANSLATOR_IMAGE_TEXT_FIXTURE_OUTPUT": outputDirectory.path,
            "IMAGE_TEXT_TOKEN": token,
            "IMAGE_TEXT_FIXTURE": name,
            "IMAGE_TEXT_HOLD_UNTIL_INACTIVE": holdCompletionUntilInactive ? "1" : "0",
        ]
        app.launch()
        XCTAssertTrue(waitFor { self.state()["token"] as? String == self.token })
        if !holdCompletionUntilInactive {
            XCTAssertTrue(waitFor { self.state()["ocrPending"] as? Bool == false })
        }
    }

    func fixturePoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        let rect = state()["imageFrame"] as! [Double]
        return CGPoint(x: rect[0] + x * rect[2] / 760, y: rect[1] + (360 - y) * rect[3] / 360)
    }

    func assertSelected(_ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            waitFor { self.state()["selected"] as? String == expected },
            "Expected \(expected), got \(state()["selected"] ?? "nil")", file: file, line: line)
    }

    func pressTranslate() {
        XCTAssertFalse((state()["selected"] as? String ?? "").isEmpty)
        key(36, .maskCommand)
        XCTAssertTrue(waitFor { self.state()["keyWindow"] as? String == "translation" })
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
