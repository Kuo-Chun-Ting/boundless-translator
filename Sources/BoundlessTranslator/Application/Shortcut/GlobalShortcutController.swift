import AppKit
import Combine
import Foundation

enum GlobalShortcutFailure {
    case invalidCandidate
    case monitor(Error)
}

enum GlobalShortcutPurpose {
    case translation
    case screenshot

    fileprivate var defaultDefinition: GlobalShortcutDefinition {
        switch self {
        case .translation:
            return .commandShift1
        case .screenshot:
            return .commandShift2
        }
    }

    fileprivate var storageKeys: GlobalShortcutStorageKeys {
        switch self {
        case .translation:
            return GlobalShortcutStorageKeys(
                keyCode: "globalShortcutKeyCode",
                modifiers: "globalShortcutModifiers",
                keyEquivalent: "globalShortcutKeyEquivalent"
            )
        case .screenshot:
            return GlobalShortcutStorageKeys(
                keyCode: "screenshotShortcutKeyCode",
                modifiers: "screenshotShortcutModifiers",
                keyEquivalent: "screenshotShortcutKeyEquivalent"
            )
        }
    }
}

private struct GlobalShortcutStorageKeys {
    let keyCode: String
    let modifiers: String
    let keyEquivalent: String
}

@MainActor
final class GlobalShortcutController: ObservableObject {
    typealias MonitorFactory = @MainActor (
        _ definition: GlobalShortcutDefinition,
        _ handler: @escaping @MainActor () -> Void
    ) -> any GlobalShortcutMonitoring

    @Published private(set) var definition: GlobalShortcutDefinition
    @Published private(set) var failure: GlobalShortcutFailure?

    private let defaults: UserDefaults
    private let storageKeys: GlobalShortcutStorageKeys
    private let makeMonitor: MonitorFactory
    private let handler: @MainActor () -> Void
    private var monitor: (any GlobalShortcutMonitoring)?

    init(
        purpose: GlobalShortcutPurpose = .translation,
        defaults: UserDefaults = .standard,
        makeMonitor: @escaping MonitorFactory = {
            GlobalShortcutMonitor(definition: $0, handler: $1)
        },
        handler: @escaping @MainActor () -> Void
    ) {
        self.defaults = defaults
        self.storageKeys = purpose.storageKeys
        self.makeMonitor = makeMonitor
        self.handler = handler
        definition = Self.loadDefinition(
            from: defaults,
            storageKeys: purpose.storageKeys,
            defaultDefinition: purpose.defaultDefinition
        )
    }

    func start() throws {
        guard monitor == nil else {
            return
        }

        let monitor = makeMonitor(definition, handler)
        do {
            try monitor.start()
            self.monitor = monitor
            failure = nil
        } catch {
            failure = .monitor(error)
            throw error
        }
    }

    func updateShortcut(_ candidate: GlobalShortcutDefinition) {
        guard candidate.isValid else {
            failure = .invalidCandidate
            return
        }
        guard candidate != definition else {
            resumeCurrentShortcut()
            return
        }

        let previousDefinition = definition
        monitor?.stop()

        let candidateMonitor = makeMonitor(candidate, handler)
        do {
            try candidateMonitor.start()
            monitor = candidateMonitor
            definition = candidate
            failure = nil
            persist(candidate)
        } catch {
            restore(previousDefinition)
            failure = .monitor(error)
        }
    }

    func beginRecording() {
        monitor?.stop()
        monitor = nil
        failure = nil
    }

    func cancelRecording() {
        resumeCurrentShortcut()
    }

    private func restore(_ definition: GlobalShortcutDefinition) {
        let restoredMonitor = makeMonitor(definition, handler)
        do {
            try restoredMonitor.start()
            monitor = restoredMonitor
        } catch {
            monitor = nil
        }
    }

    private func resumeCurrentShortcut() {
        do {
            try start()
        } catch {
            failure = .monitor(error)
        }
    }

    func failureMessage(localization: AppLocalization) -> String? {
        switch failure {
        case .invalidCandidate:
            return localization.string("shortcut.invalid")
        case .monitor(let error as GlobalShortcutError):
            return error.message(localization: localization)
        case .monitor(let error):
            return error.localizedDescription
        case nil:
            return nil
        }
    }

    private func persist(_ definition: GlobalShortcutDefinition) {
        defaults.set(Int(definition.keyCode), forKey: storageKeys.keyCode)
        defaults.set(
            Int(definition.modifierFlags.rawValue),
            forKey: storageKeys.modifiers
        )
        defaults.set(
            definition.keyEquivalent,
            forKey: storageKeys.keyEquivalent
        )
    }

    private static func loadDefinition(
        from defaults: UserDefaults,
        storageKeys: GlobalShortcutStorageKeys,
        defaultDefinition: GlobalShortcutDefinition
    ) -> GlobalShortcutDefinition {
        guard
            defaults.object(forKey: storageKeys.keyCode) != nil,
            defaults.object(forKey: storageKeys.modifiers) != nil,
            let keyEquivalent = defaults.string(forKey: storageKeys.keyEquivalent)
        else {
            return defaultDefinition
        }

        let keyCode = defaults.integer(forKey: storageKeys.keyCode)
        let modifiers = defaults.integer(forKey: storageKeys.modifiers)
        guard
            let storedKeyCode = UInt16(exactly: keyCode),
            let modifierRawValue = UInt(exactly: modifiers)
        else {
            return defaultDefinition
        }

        let definition = GlobalShortcutDefinition(
            keyCode: storedKeyCode,
            modifierFlags: NSEvent.ModifierFlags(rawValue: modifierRawValue),
            keyEquivalent: keyEquivalent
        )
        return definition.isValid ? definition : defaultDefinition
    }
}
