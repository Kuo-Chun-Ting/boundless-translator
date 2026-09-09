enum PermissionGuidePermission {
    case accessibility
    case screenRecording
}

struct PermissionGuideConfiguration {
    let titleKey: String
    let messageKey: String
    let instructionKey: String?
    let buttonKey: String
    let symbolName: String

    init(permission: PermissionGuidePermission) {
        switch permission {
        case .accessibility:
            titleKey = "permission.accessibilityTitle"
            messageKey = "permission.accessibilityGuide"
            instructionKey = "permission.accessibilityInstruction"
            buttonKey = "permission.openSystemSettings"
            symbolName = "accessibility"
        case .screenRecording:
            titleKey = "permission.screenRecordingTitle"
            messageKey = "permission.screenRecordingGuide"
            instructionKey = nil
            buttonKey = "permission.allowScreenRecording"
            symbolName = "rectangle.inset.filled.and.person.filled"
        }
    }
}
