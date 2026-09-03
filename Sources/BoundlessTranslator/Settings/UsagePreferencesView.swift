import SwiftUI

struct UsagePreferencesView: View {
    let shortcut: GlobalShortcutDefinition
    let localization: AppLocalization

    @State private var isPresentingGuide = false

    var body: some View {
        PreferencesActionButton(
            style: .help,
            accessibilityIdentifier: "usageHelpButton",
            accessibilityLabel: localization.string("usage.show"),
            action: {
                isPresentingGuide.toggle()
            }
        )
        .fixedSize()
        .popover(isPresented: $isPresentingGuide, arrowEdge: .trailing) {
            UsageGuideView(
                shortcut: shortcut,
                localization: localization
            )
        }
    }
}

struct UsageGuideView: View {
    let shortcut: GlobalShortcutDefinition
    let localization: AppLocalization

    init(
        shortcut: GlobalShortcutDefinition,
        localization: AppLocalization
    ) {
        self.shortcut = shortcut
        self.localization = localization
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
        }
        .padding(18)
        .frame(width: 520)
    }

    private var items: [UsageGuideItem] {
        UsageGuideItem.make(
            shortcut: shortcut,
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

    static func make(
        shortcut: GlobalShortcutDefinition,
        localization: AppLocalization
    ) -> [UsageGuideItem] {
        let shortcutName = shortcut.displayName
        return [
            UsageGuideItem(
                id: "translateText",
                icon: .systemSymbol(
                    name: "text.cursor",
                    clockwiseRotationDegrees: 0
                ),
                title: localization.string("usage.translateText.title"),
                description: localization.string(
                    "usage.translateText.description",
                    arguments: shortcutName
                )
            ),
            UsageGuideItem(
                id: "translateImageText",
                icon: .systemSymbol(
                    name: "photo",
                    clockwiseRotationDegrees: 0
                ),
                title: localization.string("usage.translateImageText.title"),
                description: localization.string(
                    "usage.translateImageText.description",
                    arguments: shortcutName,
                    shortcutName
                )
            ),
            UsageGuideItem(
                id: "lookUp",
                icon: .text("📖"),
                title: localization.string("usage.lookUp.title"),
                description: localization.string("usage.lookUp.description")
            ),
            UsageGuideItem(
                id: "listen",
                icon: .systemSymbol(
                    name: "speaker.wave.2.fill",
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
