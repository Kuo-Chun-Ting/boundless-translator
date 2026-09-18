import AppKit

@MainActor
protocol ForegroundWindowPresenting {
    func present(_ window: NSWindow)
}

@MainActor
final class ForegroundWindowPresenter: NSObject, ForegroundWindowPresenting {
    typealias ActivateApplication = @MainActor () -> Void

    static let shared = ForegroundWindowPresenter()

    private let notificationCenter: NotificationCenter
    private let isApplicationActive: @MainActor () -> Bool
    private let activateApplication: ActivateApplication
    private weak var pendingWindow: NSWindow?

    init(
        notificationCenter: NotificationCenter = .default,
        isApplicationActive: @escaping @MainActor () -> Bool = {
            NSApplication.shared.isActive
        },
        activateApplication: @escaping ActivateApplication = {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    ) {
        self.notificationCenter = notificationCenter
        self.isApplicationActive = isApplicationActive
        self.activateApplication = activateApplication
        super.init()
        notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive(_:)),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func present(_ window: NSWindow) {
        pendingWindow = window
        makePendingWindowMainAndKey()

        if isApplicationActive() {
            return
        }

        activateApplication()
        if isApplicationActive() {
            makePendingWindowMainAndKey()
        }
    }

    @objc
    private func applicationDidBecomeActive(_ notification: Notification) {
        makePendingWindowMainAndKey()
    }

    private func makePendingWindowMainAndKey() {
        guard let pendingWindow else { return }
        pendingWindow.makeKeyAndOrderFront(nil)
        pendingWindow.makeMain()
        if isApplicationActive() {
            self.pendingWindow = nil
        }
    }
}
