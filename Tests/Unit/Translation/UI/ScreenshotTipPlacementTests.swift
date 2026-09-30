import AppKit
import Testing
@testable import BoundlessTranslator

@Test
func test_side_whenBothSidesFit_then_prefersLeft() {
    // Arrange
    let window = CGRect(x: 400, y: 100, width: 500, height: 500)
    let screen = CGRect(x: 0, y: 0, width: 1_400, height: 900)
    // Act
    let side = ScreenshotTipPlacement.side(window: window, screen: screen, width: 280)
    // Assert
    #expect(side == .minX)
}

@Test
func test_side_whenLeftDoesNotFit_then_usesRight() {
    // Arrange
    let window = CGRect(x: 50, y: 100, width: 500, height: 500)
    let screen = CGRect(x: 0, y: 0, width: 1_400, height: 900)
    // Act
    let side = ScreenshotTipPlacement.side(window: window, screen: screen, width: 280)
    // Assert
    #expect(side == .maxX)
}

@Test
func test_side_whenNeitherSideFits_then_keepsImageUncovered() {
    // Arrange
    let window = CGRect(x: 50, y: 100, width: 1_300, height: 500)
    let screen = CGRect(x: 0, y: 0, width: 1_400, height: 900)
    // Act
    let side = ScreenshotTipPlacement.side(window: window, screen: screen, width: 280)
    // Assert
    #expect(side == nil)
}
