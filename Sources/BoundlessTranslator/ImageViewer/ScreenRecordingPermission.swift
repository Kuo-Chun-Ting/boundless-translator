import CoreGraphics

@MainActor
enum ScreenRecordingPermission {
    static func requestIfNeeded(
        isGranted: () -> Bool = { CGPreflightScreenCaptureAccess() },
        explain: () -> Bool = { PermissionExplanation.confirm(permission: .screenRecording) },
        requestAccess: () -> Bool = { CGRequestScreenCaptureAccess() }
    ) -> Bool {
        PermissionExplanation.requestPermission(
            isGranted: isGranted,
            explain: explain,
            request: requestAccess
        )
    }
}
