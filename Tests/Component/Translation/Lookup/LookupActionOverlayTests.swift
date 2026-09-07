import AppKit
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_attach_when_container_changes_then_moves_single_action_button() throws {
    // Arrange
    let target = LookupActionTarget()
    let overlay = LookupActionOverlay(
        target: target,
        action: #selector(LookupActionTarget.performLookup(_:)),
        localization: testEnglishLocalization
    )
    let firstContainer = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
    let secondContainer = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
    overlay.attach(to: firstContainer)

    // Act
    overlay.attach(to: secondContainer)

    // Assert
    #expect(firstContainer.subviews.compactMap { $0 as? PointingHandButton }.isEmpty)
    #expect(secondContainer.subviews.compactMap { $0 as? PointingHandButton }.count == 1)
}

@Test @MainActor
func test_attach_when_container_is_removed_then_detaches_action_button() {
    // Arrange
    let target = LookupActionTarget()
    let overlay = LookupActionOverlay(
        target: target,
        action: #selector(LookupActionTarget.performLookup(_:)),
        localization: testEnglishLocalization
    )
    let container = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
    overlay.attach(to: container)

    // Act
    overlay.attach(to: nil)

    // Assert
    #expect(container.subviews.compactMap { $0 as? PointingHandButton }.isEmpty)
}

@MainActor
private final class LookupActionTarget: NSObject {
    @objc
    func performLookup(_ sender: Any?) {}
}
