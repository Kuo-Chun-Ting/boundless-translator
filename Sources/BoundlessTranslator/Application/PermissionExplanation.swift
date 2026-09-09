import AppKit

@MainActor
enum PermissionExplanation {
    static func requestPermission(
        isGranted: () -> Bool,
        explain: () -> Bool,
        request: () -> Bool
    ) -> Bool {
        if isGranted() { return true }
        guard explain() else { return false }
        return request()
    }

    static func confirm(permission: PermissionGuidePermission) -> Bool {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return false }
        let localization = AppLocalization(
            languageIdentifier: InterfaceLanguageSettings().resolvedLanguageIdentifier
        )
        return PermissionGuideWindowController(
            configuration: PermissionGuideConfiguration(permission: permission),
            localization: localization
        ).present()
    }
}
