import SwiftUI

struct UsagePreferencesView: View {
    let shortcut: GlobalShortcutDefinition

    @State private var isPresentingGuide = false

    var body: some View {
        Section {
            LabeledContent("Usage") {
                PreferencesActionButton(
                    style: .help,
                    accessibilityIdentifier: "usageHelpButton",
                    action: {
                        isPresentingGuide.toggle()
                    }
                )
                .fixedSize()
                .popover(isPresented: $isPresentingGuide, arrowEdge: .trailing) {
                    UsageGuideView(shortcut: shortcut)
                }
            }
        }
    }
}

struct UsageGuideView: View {
    let shortcut: GlobalShortcutDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Usage")
                .font(.title3.weight(.semibold))

            ForEach(items) { item in
                HStack(alignment: .top, spacing: 12) {
                    icon(item.icon)
                        .frame(width: 18)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.description)
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
        UsageGuideItem.make(shortcut: shortcut)
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

    static func make(shortcut: GlobalShortcutDefinition) -> [UsageGuideItem] {
        let shortcutName = shortcut.displayName
        return [
            UsageGuideItem(
                id: "translateText",
                icon: .systemSymbol(
                    name: "text.cursor",
                    clockwiseRotationDegrees: 0
                ),
                title: "Translate Text",
                description: "Select text and press \(shortcutName)."
            ),
            UsageGuideItem(
                id: "translateImageText",
                icon: .systemSymbol(
                    name: "photo",
                    clockwiseRotationDegrees: 0
                ),
                title: "Translate Image Text",
                description: "Copy an image, press \(shortcutName), select its text, then press \(shortcutName) again."
            ),
            UsageGuideItem(
                id: "lookUp",
                icon: .text("📖"),
                title: "Look Up",
                description: "Select text in the translation panel, then click the book."
            ),
            UsageGuideItem(
                id: "listen",
                icon: .systemSymbol(
                    name: "speaker.wave.2.fill",
                    clockwiseRotationDegrees: 0
                ),
                title: "Listen",
                description: "Click the speaker beside either language."
            ),
            UsageGuideItem(
                id: "pinWindow",
                icon: .systemSymbol(
                    name: "pin",
                    clockwiseRotationDegrees: 45
                ),
                title: "Pin Window",
                description: "Click the pin to keep the translation visible."
            ),
        ]
    }
}
