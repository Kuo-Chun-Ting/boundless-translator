@MainActor
struct PreferencesPresentationCoordinator {
    func present(
        activateApplication: () -> Void,
        showWindow: () -> Void
    ) {
        activateApplication()
        showWindow()
    }
}
