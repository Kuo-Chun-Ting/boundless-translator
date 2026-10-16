import SwiftUI

struct TranslationPreferencesView: View {
    @ObservedObject var settings: TranslationSettings
    @ObservedObject var supportedLanguageCatalog: SupportedLanguageCatalog
    let localization: AppLocalization
    var onLanguageSettingsAnchorReady: (@MainActor (NSView) -> Void)? = nil

    var languageSetupReminderCount = 0

    var body: some View {
        Section {
            LabeledContent(localization.string("preferences.translateFrom")) {
                sourceLanguagePicker
                    .modifier(LanguageMenuShake(reminderCount: languageSetupReminderCount))
            }
            LabeledContent(localization.string("preferences.translateTo")) {
                targetLanguagePicker
                    .modifier(LanguageMenuShake(reminderCount: languageSetupReminderCount))
            }
            .background(LanguageSettingsHintAnchor(onReady: onLanguageSettingsAnchorReady))
        }
        .task {
            _ = await supportedLanguageCatalog.load()
        }
    }

    private var sourceLanguagePicker: some View {
        Picker(
            localization.string("preferences.translateFrom"),
            selection: $settings.sourceLanguageIdentifier
        ) {
            if settings.sourceLanguageIdentifier == TranslationSettings.unselectedLanguageIdentifier {
                Text(verbatim: localization.string("translation.chooseLanguage"))
                    .tag(Optional(TranslationSettings.unselectedLanguageIdentifier))
                    .disabled(true)
            }
            Text(verbatim: localization.string("translation.detectAutomatically"))
                .tag(nil as String?)
            ForEach(sourceLanguageOptions) { option in
                Text(verbatim: languageNames.name(for: option))
                    .tag(Optional(option.id))
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }

    private var targetLanguagePicker: some View {
        Picker(
            localization.string("preferences.translateTo"),
            selection: $settings.targetLanguageIdentifier
        ) {
            if settings.targetLanguageIdentifier == TranslationSettings.unselectedLanguageIdentifier {
                Text(verbatim: localization.string("translation.chooseLanguage"))
                    .tag(TranslationSettings.unselectedLanguageIdentifier)
                    .disabled(true)
            }
            ForEach(targetLanguageOptions) { option in
                Text(verbatim: languageNames.name(for: option))
                    .tag(option.id)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
    }

    private var languageNames: LanguageDisplayNameFormatter {
        LanguageDisplayNameFormatter(
            locale: Locale(identifier: localization.languageIdentifier)
        )
    }

    private var sourceLanguageOptions: [LanguageOption] {
        guard let sourceLanguageIdentifier = settings.sourceLanguageIdentifier,
              !sourceLanguageIdentifier.isEmpty else {
            return supportedLanguageCatalog.languages.map {
                LanguageOption(id: $0.minimalIdentifier, language: $0)
            }
        }

        return LanguageOption.make(
            supportedLanguages: supportedLanguageCatalog.languages,
            selectedIdentifier: sourceLanguageIdentifier
        )
    }

    private var targetLanguageOptions: [LanguageOption] {
        guard !settings.targetLanguageIdentifier.isEmpty else {
            return supportedLanguageCatalog.languages.map {
                LanguageOption(id: $0.minimalIdentifier, language: $0)
            }
        }
        return LanguageOption.make(
            supportedLanguages: supportedLanguageCatalog.languages,
            selectedIdentifier: settings.targetLanguageIdentifier
        )
    }
}

private struct LanguageMenuShake: ViewModifier {
    let reminderCount: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat.zero, trigger: reminderCount) { menu, offset in
            menu.offset(x: reduceMotion ? 0 : offset)
        } keyframes: { _ in
            LinearKeyframe(-5, duration: 0.06)
            LinearKeyframe(5, duration: 0.09)
            LinearKeyframe(-3, duration: 0.08)
            LinearKeyframe(2, duration: 0.07)
            LinearKeyframe(0, duration: 0.08)
        }
    }
}
