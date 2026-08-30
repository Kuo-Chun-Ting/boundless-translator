import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_handleInitialLaunch_when_appFinishesLaunching_then_presentsPreferences() {
    // Arrange
    let coordinator = ApplicationOpenCoordinator()
    var presentationCount = 0

    // Act
    coordinator.handleInitialLaunch {
        presentationCount += 1
    }

    // Assert
    #expect(presentationCount == 1)
}

@Test @MainActor
func test_handleReopen_when_runningAppIsOpenedAgain_then_presentsPreferencesAndSuppressesDefaultHandling() {
    // Arrange
    let coordinator = ApplicationOpenCoordinator()
    var presentationCount = 0

    // Act
    let shouldContinueDefaultHandling = coordinator.handleReopen {
        presentationCount += 1
    }

    // Assert
    #expect(presentationCount == 1)
    #expect(!shouldContinueDefaultHandling)
}
