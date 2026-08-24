import Combine
import ServiceManagement

@MainActor
protocol LoginItemServicing: AnyObject {
    var isRegistered: Bool { get }

    func register() throws
    func unregister() throws
}

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var errorMessage: String?

    private let service: any LoginItemServicing

    init(service: any LoginItemServicing = SystemLoginItemService()) {
        self.service = service
        isEnabled = service.isRegistered
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            isEnabled = service.isRegistered
            errorMessage = enabled && !isEnabled
                ? "Allow Whisper Translate in System Settings > General > Login Items."
                : nil
        } catch {
            isEnabled = service.isRegistered
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
private final class SystemLoginItemService: LoginItemServicing {
    var isRegistered: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func register() throws {
        guard !isRegistered else {
            return
        }
        try SMAppService.mainApp.register()
    }

    func unregister() throws {
        guard SMAppService.mainApp.status != .notRegistered else {
            return
        }
        try SMAppService.mainApp.unregister()
    }
}
