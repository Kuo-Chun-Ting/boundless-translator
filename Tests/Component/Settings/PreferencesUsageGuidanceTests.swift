import AppKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_preferencesView_when_rendered_then_shows_usage_help_button() throws {
    // Arrange
    let controller = PreferencesWindowController(
        settings: TranslationSettings(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        translationShortcutController: makeTestTranslationShortcutController(),
        supportedLanguageCatalog: makeStubLanguageCatalog()
    )
    let contentView = try #require(controller.window?.contentView)

    // Act
    contentView.layoutSubtreeIfNeeded()
    let usageHelpButtons = findUsageViews(
        in: contentView,
        accessibilityIdentifier: "usageHelpButton"
    ).compactMap { $0 as? NSButton }

    // Assert
    #expect(usageHelpButtons.count == 1)
    #expect(usageHelpButtons.first?.bezelStyle == .helpButton)
}

@Test @MainActor
func test_usageGuideItems_when_created_then_describes_every_current_feature() throws {
    // Arrange
    let expectedIdentifiers = [
        "translateText",
        "translateImageText",
        "lookUp",
        "listen",
        "pinWindow",
        "languageSupport",
    ]
    let expectedTitles = [
        "Selected Text Translation",
        "Screenshot Translation",
        "Dictionary",
        "Read Aloud",
        "Pin Window",
        "Language Support",
    ]
    let expectedIcons: [UsageGuideIcon] = [
        .systemSymbol(name: "text.cursor", clockwiseRotationDegrees: 0),
        .systemSymbol(name: "photo", clockwiseRotationDegrees: 0),
        .text(LookupActionOverlay.bookIcon),
        .systemSymbol(name: "speaker.wave.2", clockwiseRotationDegrees: 0),
        .systemSymbol(name: "pin", clockwiseRotationDegrees: 45),
        .systemSymbol(name: "globe", clockwiseRotationDegrees: 0),
    ]

    // Act
    let items = UsageGuideItem.make(
        translationShortcut: .commandShift1,
        screenshotShortcut: .commandShift2,
        localization: testEnglishLocalization
    )

    // Assert
    #expect(items.map(\.id) == expectedIdentifiers)
    #expect(items.map(\.title) == expectedTitles)
    #expect(items.map(\.icon) == expectedIcons)
    #expect(items[0].description.contains("⇧⌘1"))
    #expect(items[1].description.contains("⇧⌘2"))
    #expect(!items[1].description.contains("⇧⌘1"))
    #expect(items[0].description.hasPrefix("For selectable text"))
    #expect(items[1].description.hasPrefix("Press ⇧⌘2"))
    #expect(items[1].description.contains("capture the area you want to translate"))
    #expect(
        items[2].description
            == "Select a word or phrase in the source text, then click the book icon."
    )
    let languageSupport = try #require(
        items.first { $0.id == "languageSupport" }
    )
    #expect(
        languageSupport.description
            == "Interface language support matches macOS. macOS determines which languages can be translated between."
    )
}

@Test @MainActor
func test_usageGuideView_when_rendered_then_uses_readableWidth() {
    // Arrange
    let hostingView = NSHostingView(
        rootView: UsageGuideView(
            translationShortcut: .commandShift1,
            screenshotShortcut: .commandShift2,
            localization: testEnglishLocalization
        )
    )

    // Act
    hostingView.layoutSubtreeIfNeeded()

    // Assert
    #expect(abs(hostingView.fittingSize.width - 520) < 0.5)
}

@Test @MainActor
func test_usageGuideView_when_bundleContainsVersion_then_showsVersionAndBuild() throws {
    // Arrange
    let bundleURL = FileManager.default.temporaryDirectory
        .appending(path: "UsageGuideTests.\(UUID().uuidString).bundle")
    try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: bundleURL) }
    let info = [
        "CFBundleIdentifier": "UsageGuideTests",
        "CFBundleShortVersionString": "2.3.4",
        "CFBundleVersion": "567",
    ]
    try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        .write(to: bundleURL.appending(path: "Info.plist"))
    let stub_bundle = try #require(Bundle(url: bundleURL))

    // Act
    let guide = UsageGuideView(
        translationShortcut: .commandShift1,
        screenshotShortcut: .commandShift2,
        localization: testEnglishLocalization,
        bundle: stub_bundle
    )

    // Assert
    #expect(guide.versionText == "Version 2.3.4 (567)")
}

@MainActor
private func findUsageViews(
    in view: NSView,
    accessibilityIdentifier: String
) -> [NSView] {
    let current = view.accessibilityIdentifier() == accessibilityIdentifier
        ? [view]
        : []
    return current + view.subviews.flatMap {
        findUsageViews(in: $0, accessibilityIdentifier: accessibilityIdentifier)
    }
}
