@MainActor
struct ApplicationOpenCoordinator {
    func handleInitialLaunch(
        showPreferences: @MainActor () -> Void
    ) {
        showPreferences()
    }

    func handleReopen(
        showPreferences: @MainActor () -> Void
    ) -> Bool {
        showPreferences()
        return false
    }
}
