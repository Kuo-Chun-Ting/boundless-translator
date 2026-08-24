@MainActor
struct PreferencesPresentationCoordinator {
    func present(
        deferPresentation: (@escaping @MainActor () -> Void) -> Void,
        activateApplication: @escaping @MainActor () -> Void,
        showWindow: @escaping @MainActor () -> Void,
        forceWindowToFront: @escaping @MainActor () -> Void
    ) {
        deferPresentation {
            activateApplication()
            showWindow()
            forceWindowToFront()
        }
    }
}
