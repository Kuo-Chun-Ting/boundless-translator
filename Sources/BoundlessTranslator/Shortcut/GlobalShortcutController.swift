import AppKit
import Combine
import Foundation

@MainActor
final class GlobalShortcutController: ObservableObject {
    typealias MonitorFactory = @MainActor (
        _ definition: GlobalShortcutDefinition,
        _ handler: @escaping @MainActor () -> Void
    ) -> any GlobalShortcutMonitoring

    @Published private(set) var definition: GlobalShortcutDefinition
    @Published private(set) var errorMessage: String?

    private let defaults: UserDefaults
    private let makeMonitor: MonitorFactory
    private let handler: @MainActor () -> Void
    private var monitor: (any GlobalShortcutMonitoring)?

    init(
        defaults: UserDefaults = .standard,
        makeMonitor: @escaping MonitorFactory = {
            GlobalShortcutMonitor(definition: $0, handler: $1)
        },
        handler: @escaping @MainActor () -> Void
    ) {
        self.defaults = defaults
        self.makeMonitor = makeMonitor
        self.handler = handler
        definition = Self.loadDefinition(from: defaults)
    }

    func start() throws {
        guard monitor == nil else {
            return
        }

        let monitor = makeMonitor(definition, handler)
        do {
            try monitor.start()
            self.monitor = monitor
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func updateShortcut(_ candidate: GlobalShortcutDefinition) {
        guard candidate.isValid else {
            errorMessage = "Use Command, Option, or Control with another key."
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
            errorMessage = nil
            persist(candidate)
        } catch {
            restore(previousDefinition)
            errorMessage = error.localizedDescription
        }
    }

    func beginRecording() {
        monitor?.stop()
        monitor = nil
        errorMessage = nil
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
            errorMessage = error.localizedDescription
        }
    }

    private func persist(_ definition: GlobalShortcutDefinition) {
        defaults.set(Int(definition.keyCode), forKey: Keys.keyCode)
        defaults.set(Int(definition.modifierFlags.rawValue), forKey: Keys.modifiers)
        defaults.set(definition.keyEquivalent, forKey: Keys.keyEquivalent)
    }

    private static func loadDefinition(
        from defaults: UserDefaults
    ) -> GlobalShortcutDefinition {
        guard
            defaults.object(forKey: Keys.keyCode) != nil,
            defaults.object(forKey: Keys.modifiers) != nil,
            let keyEquivalent = defaults.string(forKey: Keys.keyEquivalent)
        else {
            return .commandShiftT
        }

        let keyCode = defaults.integer(forKey: Keys.keyCode)
        let modifiers = defaults.integer(forKey: Keys.modifiers)
        guard
            let storedKeyCode = UInt16(exactly: keyCode),
            let modifierRawValue = UInt(exactly: modifiers)
        else {
            return .commandShiftT
        }

        let definition = GlobalShortcutDefinition(
            keyCode: storedKeyCode,
            modifierFlags: NSEvent.ModifierFlags(rawValue: modifierRawValue),
            keyEquivalent: keyEquivalent
        )
        return definition.isValid ? definition : .commandShiftT
    }

    private enum Keys {
        static let keyCode = "globalShortcutKeyCode"
        static let modifiers = "globalShortcutModifiers"
        static let keyEquivalent = "globalShortcutKeyEquivalent"
    }
}
