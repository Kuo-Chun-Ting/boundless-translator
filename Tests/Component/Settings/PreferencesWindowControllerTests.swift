import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_init_when_preferencesWindowIsCreated_then_movesWindowToActiveSpace() throws {
    // Arrange & Act
    let controller = PreferencesWindowController(settings: TranslationSettings())
    let window = try #require(controller.window)

    // Assert
    #expect(window.collectionBehavior.contains(.moveToActiveSpace))
}

@Test @MainActor
func test_present_when_activeScreenChanges_then_centersWindowOnActiveScreen() async throws {
    // Arrange
    let stub_visibleFrame = CGRect(x: 10_000, y: 4_000, width: 1_200, height: 800)
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        activeScreenVisibleFrame: { stub_visibleFrame }
    )
    let window = try #require(controller.window)

    // Act
    controller.present()
    await Task.yield()

    // Assert
    #expect(window.frame.midX == stub_visibleFrame.midX)
    #expect(window.frame.midY == stub_visibleFrame.midY)
    window.orderOut(nil)
}
