import Combine
import Foundation

@MainActor
final class TranslationSettings: ObservableObject {
    static let unselectedLanguageIdentifier = ""
    private static let automaticSourceLanguageValue = "automatic"

    @Published var sourceLanguageIdentifier: String? {
        didSet {
            defaults.set(
                sourceLanguageIdentifier ?? Self.automaticSourceLanguageValue,
                forKey: sourceLanguageKey
            )
        }
    }

    @Published var targetLanguageIdentifier: String {
        didSet {
            defaults.set(targetLanguageIdentifier, forKey: targetLanguageKey)
        }
    }

    var hasSelectedLanguages: Bool {
        sourceLanguageIdentifier != Self.unselectedLanguageIdentifier
            && targetLanguageIdentifier != Self.unselectedLanguageIdentifier
    }

    private let defaults: UserDefaults
    private let sourceLanguageKey = "sourceLanguageIdentifier"
    private let targetLanguageKey = "targetLanguageIdentifier"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedSourceLanguage = defaults.string(forKey: sourceLanguageKey) ?? Self.unselectedLanguageIdentifier
        sourceLanguageIdentifier = savedSourceLanguage == Self.automaticSourceLanguageValue
            ? nil : savedSourceLanguage
        targetLanguageIdentifier = defaults.string(forKey: targetLanguageKey)
            ?? Self.unselectedLanguageIdentifier
    }

    func resetUnsupportedSourceLanguage(supportedLanguages: [Locale.Language]) {
        guard let sourceLanguageIdentifier, !sourceLanguageIdentifier.isEmpty,
              !supportedLanguages.isEmpty else {
            return
        }

        guard !isLanguageSupported(sourceLanguageIdentifier, in: supportedLanguages) else { return }

        self.sourceLanguageIdentifier = Self.unselectedLanguageIdentifier
    }

    func resetUnsupportedTargetLanguage(supportedLanguages: [Locale.Language]) {
        guard !targetLanguageIdentifier.isEmpty, !supportedLanguages.isEmpty else {
            return
        }

        guard !isLanguageSupported(targetLanguageIdentifier, in: supportedLanguages) else { return }

        targetLanguageIdentifier = Self.unselectedLanguageIdentifier
    }

    private func isLanguageSupported(_ identifier: String, in supportedLanguages: [Locale.Language]) -> Bool {
        let selectedLanguage = Locale.Language(identifier: identifier)
        return supportedLanguages.contains {
            $0.maximalIdentifier == selectedLanguage.maximalIdentifier
        }
    }
}
