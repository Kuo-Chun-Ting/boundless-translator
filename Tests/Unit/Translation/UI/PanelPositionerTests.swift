import CoreGraphics
import Testing
@testable import BoundlessTranslator

@Test
func test_origin_when_panel_fits_below_pointer_then_offsets_from_pointer() {
    // Arrange
    let positioner = PanelPositioner(pointerOffset: 12)
    let visibleFrame = CGRect(x: 0, y: 0, width: 1_000, height: 800)

    // Act
    let origin = positioner.origin(
        pointer: CGPoint(x: 400, y: 500),
        panelSize: CGSize(width: 300, height: 180),
        visibleFrame: visibleFrame
    )

    // Assert
    #expect(origin == CGPoint(x: 412, y: 308))
}

@Test
func test_origin_when_panel_exceeds_right_edge_then_clamps_horizontally() {
    // Arrange
    let positioner = PanelPositioner(pointerOffset: 12)
    let visibleFrame = CGRect(x: 100, y: 50, width: 800, height: 600)

    // Act
    let origin = positioner.origin(
        pointer: CGPoint(x: 850, y: 500),
        panelSize: CGSize(width: 300, height: 180),
        visibleFrame: visibleFrame
    )

    // Assert
    #expect(origin.x == 600)
}

@Test
func test_origin_when_panel_exceeds_bottom_edge_then_clamps_vertically() {
    // Arrange
    let positioner = PanelPositioner(pointerOffset: 12)
    let visibleFrame = CGRect(x: 100, y: 50, width: 800, height: 600)

    // Act
    let origin = positioner.origin(
        pointer: CGPoint(x: 400, y: 100),
        panelSize: CGSize(width: 300, height: 180),
        visibleFrame: visibleFrame
    )

    // Assert
    #expect(origin.y == 50)
}

@Test
func test_origin_when_pointer_is_left_of_visible_frame_then_clamps_to_left_edge() {
    // Arrange
    let positioner = PanelPositioner(pointerOffset: 12)
    let visibleFrame = CGRect(x: 100, y: 50, width: 800, height: 600)

    // Act
    let origin = positioner.origin(
        pointer: CGPoint(x: 20, y: 500),
        panelSize: CGSize(width: 300, height: 180),
        visibleFrame: visibleFrame
    )

    // Assert
    #expect(origin.x == 100)
}

@Test
func test_origin_when_panel_exceeds_top_edge_then_clamps_vertically() {
    // Arrange
    let positioner = PanelPositioner(pointerOffset: 12)
    let visibleFrame = CGRect(x: 100, y: 50, width: 800, height: 600)

    // Act
    let origin = positioner.origin(
        pointer: CGPoint(x: 400, y: 900),
        panelSize: CGSize(width: 300, height: 180),
        visibleFrame: visibleFrame
    )

    // Assert
    #expect(origin.y == 470)
}

@Test
func test_resizedOrigin_when_panel_grows_after_being_moved_then_preserves_top_left() {
    // Arrange
    let positioner = PanelPositioner(pointerOffset: 12)
    let currentFrame = CGRect(x: 260, y: 240, width: 560, height: 220)
    let visibleFrame = CGRect(x: 0, y: 0, width: 1_200, height: 900)

    // Act
    let origin = positioner.resizedOrigin(
        currentFrame: currentFrame,
        newPanelSize: CGSize(width: 560, height: 340),
        visibleFrame: visibleFrame
    )

    // Assert
    #expect(origin == CGPoint(x: 260, y: 120))
}
