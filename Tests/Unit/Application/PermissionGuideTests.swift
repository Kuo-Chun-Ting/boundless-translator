import Testing
@testable import BoundlessTranslator

@Test
func test_configuration_when_accessibility_then_uses_accessibility_content() {
    // Arrange
    let permission = PermissionGuidePermission.accessibility

    // Act
    let configuration = PermissionGuideConfiguration(permission: permission)

    // Assert
    #expect(configuration.titleKey == "permission.accessibilityTitle")
    #expect(configuration.messageKey == "permission.accessibilityGuide")
    #expect(configuration.instructionKey == "permission.accessibilityInstruction")
    #expect(configuration.buttonKey == "permission.openSystemSettings")
    #expect(configuration.symbolName == "accessibility")
}

@Test
func test_configuration_when_screenRecording_then_uses_screenRecording_content() {
    // Arrange
    let permission = PermissionGuidePermission.screenRecording

    // Act
    let configuration = PermissionGuideConfiguration(permission: permission)

    // Assert
    #expect(configuration.titleKey == "permission.screenRecordingTitle")
    #expect(configuration.messageKey == "permission.screenRecordingGuide")
    #expect(configuration.instructionKey == nil)
    #expect(configuration.buttonKey == "permission.allowScreenRecording")
    #expect(configuration.symbolName == "rectangle.inset.filled.and.person.filled")
}
