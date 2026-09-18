import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_present_whenApplicationIsInactive_then_selectsTargetBeforeActivation() {
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
    #expect(calls == ["keyAndFront", "main", "activate"])

    // Act
    application.isActive = true
    notificationCenter.post(name: NSApplication.didBecomeActiveNotification, object: nil)

    // Assert
    #expect(calls == [
        "keyAndFront",
        "main",
        "activate",
        "keyAndFront",
        "main",
    ])
}

@Test @MainActor
func test_present_whenApplicationIsActive_then_makesTargetMainAndKeyImmediately() {
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
    #expect(calls == ["keyAndFront", "main"])
}

@Test @MainActor
func test_present_whenMultipleWindowsAwaitActivation_then_lastWindowBecomesMainAndKey() {
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
    #expect(firstCalls == ["keyAndFront", "main"])
    #expect(secondCalls == [
        "keyAndFront",
        "main",
        "keyAndFront",
        "main",
    ])
}

@MainActor
private final class WindowPresentationSpy: NSWindow {
    private let record: (String) -> Void

    init(
        record: @escaping (String) -> Void
    ) {
        self.record = record
        super.init(
            contentRect: .zero,
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
    }

    override func makeKeyAndOrderFront(_ sender: Any?) {
        record("keyAndFront")
    }

    override func makeMain() {
        record("main")
    }
}

@MainActor
private final class ApplicationActivationState {
    var isActive: Bool

    init(isActive: Bool) {
        self.isActive = isActive
    }
}
