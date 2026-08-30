import Carbon.HIToolbox
import Foundation

enum GlobalShortcutError: LocalizedError {
    case eventHandlerInstallationFailed(OSStatus)
    case registrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .eventHandlerInstallationFailed(let status):
            "The global shortcut event handler could not be installed (\(status))."
        case .registrationFailed(let status):
            "The keyboard shortcut could not be registered (\(status)). It may be used by another app."
        }
    }
}

@MainActor
protocol GlobalShortcutMonitoring: AnyObject {
    func start() throws
    func stop()
}

@MainActor
final class GlobalShortcutMonitor: GlobalShortcutMonitoring {
    private static let hotKeySignature: OSType = 0x5754_524E

    private let definition: GlobalShortcutDefinition
    private let handler: @MainActor () -> Void

    private var eventHandlerReference: EventHandlerRef?
    private var hotKeyReference: EventHotKeyRef?

    init(
        definition: GlobalShortcutDefinition = .commandShiftT,
        handler: @escaping @MainActor () -> Void
    ) {
        self.definition = definition
        self.handler = handler
    }

    func start() throws {
        guard eventHandlerReference == nil, hotKeyReference == nil else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let installationStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.carbonEventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerReference
        )
        guard installationStatus == noErr else {
            throw GlobalShortcutError.eventHandlerInstallationFailed(
                installationStatus
            )
        }

        let hotKeyID = EventHotKeyID(
            signature: Self.hotKeySignature,
            id: 1
        )
        let registrationStatus = RegisterEventHotKey(
            UInt32(definition.keyCode),
            definition.carbonModifierFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            definition.carbonRegistrationOptions,
            &hotKeyReference
        )
        guard registrationStatus == noErr else {
            stop()
            throw GlobalShortcutError.registrationFailed(registrationStatus)
        }
    }

    func stop() {
        if let hotKeyReference {
            UnregisterEventHotKey(hotKeyReference)
        }
        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
        }
        hotKeyReference = nil
        eventHandlerReference = nil
    }

    private func invokeHandler() {
        handler()
    }

    private nonisolated static let carbonEventHandler: EventHandlerUPP = {
        _, _, userData in
        guard let userData else {
            return OSStatus(eventNotHandledErr)
        }

        let monitor = Unmanaged<GlobalShortcutMonitor>
            .fromOpaque(userData)
            .takeUnretainedValue()
        Task { @MainActor in
            monitor.invokeHandler()
        }
        return noErr
    }
}
