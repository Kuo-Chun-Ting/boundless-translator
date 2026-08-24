import SwiftUI

struct TranslationPanelToolbar: View {
    @ObservedObject var panelState: TranslationPanelState

    var body: some View {
        HStack(spacing: 8) {
            nativeWindowControlsSpacing
            Spacer(minLength: 8)
            pinButton
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var nativeWindowControlsSpacing: some View {
        Color.clear
            .frame(width: 62, height: 30)
            .accessibilityHidden(true)
    }

}

struct TranslationLanguageBar: View {
    @ObservedObject var coordinator: TranslationCoordinator

    let supportedLanguages: [Locale.Language]

    private let formatter = TranslationLanguagePairFormatter(locale: .current)

    var body: some View {
        HStack(spacing: 0) {
            sourceLanguageMenu
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            targetLanguageMenu
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay {
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
        .padding(.vertical, 6)
    }

    private var sourceLanguageMenu: some View {
        Menu {
            ForEach(sourceLanguageOptions) { option in
                languageMenuButton(
                    option: option,
                    selectedIdentifier: request?.sourceLanguageIdentifier,
                    action: coordinator.updateSourceLanguage
                )
            }
        } label: {
            LanguageMenuLabel(
                title: sourceLanguageName,
                badge: request?.sourceLanguageWasDetected == true ? "Auto" : nil
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("Source Language")
        .accessibilityValue(sourceLanguageDescription)
    }

    private var targetLanguageMenu: some View {
        Menu {
            ForEach(targetLanguageOptions) { option in
                languageMenuButton(
                    option: option,
                    selectedIdentifier: request?.targetLanguageIdentifier,
                    action: coordinator.updateTargetLanguage
                )
            }
        } label: {
            LanguageMenuLabel(
                title: targetLanguageDescription
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityLabel("Target Language")
        .accessibilityValue(targetLanguageDescription)
    }

    @ViewBuilder
    private func languageMenuButton(
        option: LanguageOption,
        selectedIdentifier: String?,
        action: @escaping @MainActor (String) -> Void
    ) -> some View {
        Button {
            guard option.id != selectedIdentifier else {
                return
            }
            action(option.id)
        } label: {
            if option.id == selectedIdentifier {
                Label(
                    formatter.languageName(for: option.id),
                    systemImage: "checkmark"
                )
            } else {
                Text(formatter.languageName(for: option.id))
            }
        }
    }

    private var request: TranslationRequest? {
        coordinator.request
    }

    private var sourceLanguageOptions: [LanguageOption] {
        guard let request else {
            return []
        }
        return LanguageOption.make(
            supportedLanguages: supportedLanguages,
            selectedIdentifier: request.sourceLanguageIdentifier
        )
    }

    private var targetLanguageOptions: [LanguageOption] {
        guard let request else {
            return []
        }
        return LanguageOption.make(
            supportedLanguages: supportedLanguages,
            selectedIdentifier: request.targetLanguageIdentifier
        )
    }

    private var sourceLanguageDescription: String {
        guard let request else {
            return "Source"
        }
        return formatter.sourceDescription(
            languageIdentifier: request.sourceLanguageIdentifier,
            wasDetected: request.sourceLanguageWasDetected
        )
    }

    private var sourceLanguageName: String {
        guard let request else {
            return "Source"
        }
        return formatter.languageName(for: request.sourceLanguageIdentifier)
    }

    private var targetLanguageDescription: String {
        guard let request else {
            return "Target"
        }
        return formatter.languageName(for: request.targetLanguageIdentifier)
    }
}

private struct LanguageMenuLabel: View {
    let title: String
    var badge: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)
            if let badge {
                Text(badge)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        Color.secondary.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 4, style: .continuous)
                    )
                    .fixedSize()
            }
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
        .background(
            Color.primary.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
        )
        .contentShape(Rectangle())
    }
}

private extension TranslationPanelToolbar {
    var pinButton: some View {
        Button {
            panelState.togglePin()
        } label: {
            Image(systemName: "pin.fill")
                .font(.system(size: 14, weight: .medium))
                .rotationEffect(.degrees(panelState.pinRotationDegrees))
                .foregroundStyle(
                    panelState.isPinned ? Color.blue : Color.secondary
                )
                .toolbarControlFrame(
                    size: 30,
                    isSelected: panelState.isPinned
                )
        }
        .buttonStyle(.plain)
        .help(panelState.isPinned ? "Unpin Translation" : "Pin Translation")
        .accessibilityLabel(
            panelState.isPinned ? "Unpin Translation" : "Pin Translation"
        )
    }
}

private extension View {
    func toolbarControlFrame(
        size: CGFloat = 28,
        isSelected: Bool = false
    ) -> some View {
        frame(width: size, height: size)
            .background(
                isSelected
                    ? Color.blue.opacity(0.18)
                    : Color.primary.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
            )
            .contentShape(Rectangle())
    }
}
