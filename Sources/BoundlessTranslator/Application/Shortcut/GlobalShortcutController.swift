import AppKit
import Combine
import Foundation

enum GlobalShortcutFailure {
    case invalidCandidate
    case alreadyAssigned
    case monitor(Error)
}

enum GlobalShortcutKind {
    case translation
    case screenshot

    var defaultDefinition: GlobalShortcutDefinition {
        self == .translation ? .optionShiftE : .optionShiftR
    }

    var storagePrefix: String {
        self == .translation ? "globalShortcut" : "screenshotShortcut"
    }
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
    private let kind: GlobalShortcutKind
    private let makeMonitor: MonitorFactory
    private let handler: @MainActor () -> Void
    private var monitor: (any GlobalShortcutMonitoring)?

    init(
        kind: GlobalShortcutKind = .translation,
        defaults: UserDefaults = .standard,
        makeMonitor: @escaping MonitorFactory = {
            GlobalShortcutMonitor(definition: $0, handler: $1)
        },
        handler: @escaping @MainActor () -> Void
    ) {
        self.kind = kind
        self.defaults = defaults
        self.makeMonitor = makeMonitor
        self.handler = handler
        definition = Self.loadDefinition(from: defaults, kind: kind)
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

    func updateShortcut(_ candidate: GlobalShortcutDefinition, reserved: [GlobalShortcutDefinition] = []) {
        guard candidate.isValid else {
            failure = .invalidCandidate
            return
        }
        guard !reserved.contains(where: {
            $0.keyCode == candidate.keyCode && $0.modifierFlags == candidate.modifierFlags
        }) else {
            resumeCurrentShortcut()
            failure = .alreadyAssigned
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
        case .alreadyAssigned:
            return localization.string("shortcut.alreadyAssigned")
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
        defaults.set(Int(definition.keyCode), forKey: kind.storagePrefix + "KeyCode")
        defaults.set(Int(definition.modifierFlags.rawValue), forKey: kind.storagePrefix + "Modifiers")
        defaults.set(definition.keyEquivalent, forKey: kind.storagePrefix + "KeyEquivalent")
    }

    private static func loadDefinition(
        from defaults: UserDefaults,
        kind: GlobalShortcutKind
    ) -> GlobalShortcutDefinition {
        guard
            defaults.object(forKey: kind.storagePrefix + "KeyCode") != nil,
            defaults.object(forKey: kind.storagePrefix + "Modifiers") != nil,
            let keyEquivalent = defaults.string(forKey: kind.storagePrefix + "KeyEquivalent")
        else {
            return kind.defaultDefinition
        }

        let keyCode = defaults.integer(forKey: kind.storagePrefix + "KeyCode")
        let modifiers = defaults.integer(forKey: kind.storagePrefix + "Modifiers")
        guard
            let storedKeyCode = UInt16(exactly: keyCode),
            let modifierRawValue = UInt(exactly: modifiers)
        else {
            return kind.defaultDefinition
        }

        let definition = GlobalShortcutDefinition(
            keyCode: storedKeyCode,
            modifierFlags: NSEvent.ModifierFlags(rawValue: modifierRawValue),
            keyEquivalent: keyEquivalent
        )
        return definition.isValid ? definition : kind.defaultDefinition
    }
}
