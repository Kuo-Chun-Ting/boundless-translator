import Foundation
import Testing
@testable import WhisperTranslate

@Test @MainActor
func test_init_when_service_is_registered_then_reports_enabled() {
    // Arrange
    let stub_service = LoginItemServiceMock(isRegistered: true)

    // Act
    let controller = LaunchAtLoginController(service: stub_service)

    // Assert
    #expect(controller.isEnabled)
    #expect(controller.errorMessage == nil)
}

@Test @MainActor
func test_setEnabled_when_enabling_succeeds_then_registers_login_item() {
    // Arrange
    let mock_service = LoginItemServiceMock(isRegistered: false)
    let controller = LaunchAtLoginController(service: mock_service)

    // Act
    controller.setEnabled(true)

    // Assert
    #expect(mock_service.registrationCount == 1)
    #expect(controller.isEnabled)
    #expect(controller.errorMessage == nil)
}

@Test @MainActor
func test_setEnabled_when_disabling_succeeds_then_unregisters_login_item() {
    // Arrange
    let mock_service = LoginItemServiceMock(isRegistered: true)
    let controller = LaunchAtLoginController(service: mock_service)

    // Act
    controller.setEnabled(false)

    // Assert
    #expect(mock_service.unregistrationCount == 1)
    #expect(!controller.isEnabled)
    #expect(controller.errorMessage == nil)
}

@Test @MainActor
func test_setEnabled_when_registration_fails_then_preserves_state_and_reports_error() {
    // Arrange
    let stub_service = LoginItemServiceMock(
        isRegistered: false,
        registrationError: LoginItemTestError.denied
    )
    let controller = LaunchAtLoginController(service: stub_service)

    // Act
    controller.setEnabled(true)

    // Assert
    #expect(!controller.isEnabled)
    #expect(controller.errorMessage == "Login item permission was denied.")
}

@Test @MainActor
func test_setEnabled_when_unregistration_fails_then_preserves_state_and_reports_error() {
    // Arrange
    let stub_service = LoginItemServiceMock(
        isRegistered: true,
        unregistrationError: LoginItemTestError.denied
    )
    let controller = LaunchAtLoginController(service: stub_service)

    // Act
    controller.setEnabled(false)

    // Assert
    #expect(controller.isEnabled)
    #expect(controller.errorMessage == "Login item permission was denied.")
}

@MainActor
private final class LoginItemServiceMock: LoginItemServicing {
    private(set) var isRegistered: Bool
    private(set) var registrationCount = 0
    private(set) var unregistrationCount = 0

    private let registrationError: Error?
    private let unregistrationError: Error?

    init(
        isRegistered: Bool,
        registrationError: Error? = nil,
        unregistrationError: Error? = nil
    ) {
        self.isRegistered = isRegistered
        self.registrationError = registrationError
        self.unregistrationError = unregistrationError
    }

    func register() throws {
        registrationCount += 1
        if let registrationError {
            throw registrationError
        }
        isRegistered = true
    }

    func unregister() throws {
        unregistrationCount += 1
        if let unregistrationError {
            throw unregistrationError
        }
        isRegistered = false
    }
}

private enum LoginItemTestError: LocalizedError {
    case denied

    var errorDescription: String? {
        "Login item permission was denied."
    }
}
