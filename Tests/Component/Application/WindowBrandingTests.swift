import AppKit
import Testing
@testable import BoundlessTranslator

enum BrandedWindowKind: CaseIterable {
    case translation, screenshot, settings, permission, subscription
}

@Test(arguments: BrandedWindowKind.allCases) @MainActor
func test_init_when_completeWindowIsCreated_then_displaysSharedBrand(kind: BrandedWindowKind) throws {
    // Arrange & Act
    let window = try makeBrandedWindow(kind)

    // Assert
    #expect(window.title == "Boundless Translator")
    #expect(window.titleVisibility == .hidden)
    #expect(window.titlebarAccessoryViewControllers.count == 1)
    let accessory = try #require(window.titlebarAccessoryViewControllers.first)
    let stack = try #require(accessory.view as? NSStackView)
    let icon = try #require(stack.arrangedSubviews.compactMap { $0 as? NSImageView }.first)
    let label = try #require(stack.arrangedSubviews.compactMap { $0 as? NSTextField }.first)
    #expect(icon.image === AppBrand.spriteImage)
    #expect(label.stringValue == "Boundless Translator")
}

@MainActor
private func makeBrandedWindow(_ kind: BrandedWindowKind) throws -> NSWindow {
    switch kind {
    case .translation:
        let window = TranslationWindow()
        window.configureChrome(for: .translation)
        return window
    case .screenshot:
        return try #require(ImageViewerWindowController(
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            recognitionLanguages: { ["en"] }
        ).window)
    case .settings:
        return try #require(PreferencesWindowController(
            settings: TranslationSettings(),
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
            translationShortcutController: makeTestTranslationShortcutController(),
            supportedLanguageCatalog: makeStubLanguageCatalog()
        ).window)
    case .permission:
        return try #require(PermissionGuideWindowController(
            configuration: PermissionGuideConfiguration(permission: .accessibility),
            localization: testEnglishLocalization
        ).window)
    case .subscription:
        return try #require(SubscriptionWindowController(
            access: SubscriptionAccessController(productID: "annual", provider: BrandingEntitlementsStub()),
            interfaceLanguageSettings: makeTestInterfaceLanguageSettings()
        ).window)
    }
}

@MainActor
private struct BrandingEntitlementsStub: SubscriptionProviding {
    func loadEntitlements() async throws -> [SubscriptionEntitlement] { [] }
    func observeChanges(_ onChange: @escaping @MainActor @Sendable () async -> Void) async {}
}
