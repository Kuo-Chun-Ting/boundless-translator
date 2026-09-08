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

    func message(localization: AppLocalization) -> String {
        switch self {
        case .eventHandlerInstallationFailed(let status):
            localization.string(
                "shortcutError.installation",
                arguments: String(status)
            )
        case .registrationFailed(let status):
            localization.string(
                "shortcutError.registration",
                arguments: String(status)
            )
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
    private nonisolated static let hotKeySignature: OSType = 0x5754_524E
    private static var nextIdentifier: UInt32 = 0
    nonisolated let identifier: UInt32

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
        Self.nextIdentifier += 1
        identifier = Self.nextIdentifier
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
            id: identifier
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
        guard hotKeyReference != nil else { return }
        handler()
    }

    nonisolated func acceptsEvent(signature: OSType, identifier: UInt32) -> Bool {
        signature == Self.hotKeySignature && identifier == self.identifier
    }

    private nonisolated static let carbonEventHandler: EventHandlerUPP = {
        _, event, userData in
        guard let event, let userData else {
            return OSStatus(eventNotHandledErr)
        }

        let monitor = Unmanaged<GlobalShortcutMonitor>
            .fromOpaque(userData)
            .takeUnretainedValue()
        var eventID = EventHotKeyID()
        let status = GetEventParameter(
            event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
            nil, MemoryLayout<EventHotKeyID>.size, nil, &eventID
        )
        guard status == noErr,
              monitor.acceptsEvent(signature: eventID.signature, identifier: eventID.id) else {
            return OSStatus(eventNotHandledErr)
        }
        Task { @MainActor in
            monitor.invokeHandler()
        }
        return noErr
    }
}
