import SwiftUI

struct UsagePreferencesView: View {
    let translationShortcut: GlobalShortcutDefinition
    let screenshotShortcut: GlobalShortcutDefinition
    let localization: AppLocalization
    var onHelpButtonReady: (@MainActor (NSButton) -> Void)? = nil

    @State private var isPresentingGuide = false

    var body: some View {
        PreferencesActionButton(
            style: .help,
            accessibilityIdentifier: "usageHelpButton",
            accessibilityLabel: localization.string("usage.show"),
            action: {
                isPresentingGuide.toggle()
            }, onButtonReady: onHelpButtonReady
        )
        .fixedSize()
        .popover(isPresented: $isPresentingGuide, arrowEdge: .trailing) {
            UsageGuideView(
                translationShortcut: translationShortcut,
                screenshotShortcut: screenshotShortcut,
                localization: localization
            )
        }
    }
}

struct UsageGuideView: View {
    let translationShortcut: GlobalShortcutDefinition
    let screenshotShortcut: GlobalShortcutDefinition
    let localization: AppLocalization
    let versionText: String?

    init(
        translationShortcut: GlobalShortcutDefinition,
        screenshotShortcut: GlobalShortcutDefinition,
        localization: AppLocalization,
        bundle: Bundle = .main
    ) {
        self.translationShortcut = translationShortcut
        self.screenshotShortcut = screenshotShortcut
        self.localization = localization
        if let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            versionText = "Version \(version) (\(build))"
        } else {
            versionText = nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(verbatim: localization.string("usage.label"))
                .font(.title3.weight(.semibold))

            ForEach(items) { item in
                HStack(alignment: .top, spacing: 12) {
                    icon(item.icon)
                        .frame(width: 18)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: item.title)
                            .font(.headline)
                        Text(verbatim: item.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("usageItem.\(item.id)")
            }

            if let versionText {
                Text(verbatim: versionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityIdentifier("usageVersion")
            }
        }
        .padding(18)
        .frame(width: 520)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("usageGuide")
    }

    private var items: [UsageGuideItem] {
        UsageGuideItem.make(
            translationShortcut: translationShortcut,
            screenshotShortcut: screenshotShortcut,
            localization: localization
        )
    }

    @ViewBuilder
    private func icon(_ icon: UsageGuideIcon) -> some View {
        switch icon {
        case .text(let value):
            Text(value)
        case .systemSymbol(let name, let clockwiseRotationDegrees):
            Image(systemName: name)
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(clockwiseRotationDegrees))
        }
    }
}

enum UsageGuideIcon: Equatable {
    case text(String)
    case systemSymbol(name: String, clockwiseRotationDegrees: Double)
}

struct UsageGuideItem: Identifiable {
    let id: String
    let icon: UsageGuideIcon
    let title: String
    let description: String

    @MainActor
    static func make(
        translationShortcut: GlobalShortcutDefinition,
        screenshotShortcut: GlobalShortcutDefinition,
        localization: AppLocalization
    ) -> [UsageGuideItem] {
        let translationShortcutName = translationShortcut.displayName
        let screenshotShortcutName = screenshotShortcut.displayName
        return [
            UsageGuideItem(
                id: "translateText",
                icon: .systemSymbol(
                    name: "text.cursor",
                    clockwiseRotationDegrees: 0
                ),
                title: localization.string("shortcut.selectedTextTranslation"),
                description: localization.string(
                    "usage.translateText.description",
                    arguments: translationShortcutName
                )
            ),
            UsageGuideItem(
                id: "translateImageText",
                icon: .systemSymbol(
                    name: "photo",
                    clockwiseRotationDegrees: 0
                ),
                title: localization.string("shortcut.screenshotTranslation"),
                description: localization.string(
                    "usage.translateImageText.description",
                    arguments: screenshotShortcutName, translationShortcutName
                )
            ),
            UsageGuideItem(
                id: "lookUp",
                icon: .text("📖"),
                title: localization.string("lookup.title"),
                description: localization.string("usage.lookUp.description")
            ),
            UsageGuideItem(
                id: "listen",
                icon: .systemSymbol(
                    name: "speaker.wave.2",
                    clockwiseRotationDegrees: 0
                ),
                title: localization.string("usage.listen.title"),
                description: localization.string("usage.listen.description")
            ),
            UsageGuideItem(
                id: "pinWindow",
                icon: .systemSymbol(
                    name: "pin",
                    clockwiseRotationDegrees: 45
                ),
                title: localization.string("usage.pinWindow.title"),
                description: localization.string("usage.pinWindow.description")
            ),
            UsageGuideItem(
                id: "languageSupport",
                icon: .systemSymbol(
                    name: "globe",
                    clockwiseRotationDegrees: 0
                ),
                title: localization.string("usage.languageSupport.title"),
                description: localization.string(
                    "usage.languageSupport.description"
                )
            ),
        ]
    }
}
