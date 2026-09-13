import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_present_whenApplicationIsInactive_then_makesWindowKeyAfterActivation() {
    // Arrange
    let application = ApplicationActivationState(isActive: false)
    var calls: [String] = []
    let notificationCenter = NotificationCenter()
    let window = WindowPresentationSpy { action in
        calls.append(action)
    }
    let presenter = ForegroundWindowPresenter(
        notificationCenter: notificationCenter,
        isApplicationActive: { application.isActive },
        activateApplication: {
            calls.append("activate")
        }
    )

    // Act
    presenter.present(window)

    // Assert
    #expect(calls == ["front", "activate"])

    // Act
    application.isActive = true
    notificationCenter.post(name: NSApplication.didBecomeActiveNotification, object: nil)

    // Assert
    #expect(calls == ["front", "activate", "keyAndFront"])
}

@Test @MainActor
func test_present_whenApplicationIsActive_then_makesWindowKeyImmediately() {
    // Arrange
    var calls: [String] = []
    let window = WindowPresentationSpy { action in
        calls.append(action)
    }
    let presenter = ForegroundWindowPresenter(
        notificationCenter: NotificationCenter(),
        isApplicationActive: { true },
        activateApplication: {
            Issue.record("Active application should not request activation")
        }
    )

    // Act
    presenter.present(window)

    // Assert
    #expect(calls == ["front", "keyAndFront"])
}

@Test @MainActor
func test_present_whenMultipleWindowsAwaitActivation_then_lastWindowBecomesKey() {
    // Arrange
    let application = ApplicationActivationState(isActive: false)
    var activationCount = 0
    var firstCalls: [String] = []
    var secondCalls: [String] = []
    let notificationCenter = NotificationCenter()
    let firstWindow = WindowPresentationSpy { firstCalls.append($0) }
    let secondWindow = WindowPresentationSpy { secondCalls.append($0) }
    let presenter = ForegroundWindowPresenter(
        notificationCenter: notificationCenter,
        isApplicationActive: { application.isActive },
        activateApplication: {
            activationCount += 1
        }
    )

    // Act
    presenter.present(firstWindow)
    presenter.present(secondWindow)
    application.isActive = true
    notificationCenter.post(name: NSApplication.didBecomeActiveNotification, object: nil)

    // Assert
    #expect(activationCount == 2)
    #expect(firstCalls == ["front"])
    #expect(secondCalls == ["front", "keyAndFront"])
}

@MainActor
private final class WindowPresentationSpy: NSWindow {
    private let record: (String) -> Void

    init(record: @escaping (String) -> Void) {
        self.record = record
        super.init(
            contentRect: .zero,
            styleMask: [],
            backing: .buffered,
            defer: false
        )
    }

    override func orderFront(_ sender: Any?) {
        record("front")
    }

    override func makeKeyAndOrderFront(_ sender: Any?) {
        record("keyAndFront")
    }
}

@MainActor
private final class ApplicationActivationState {
    var isActive: Bool

    init(isActive: Bool) {
        self.isActive = isActive
    }
}
