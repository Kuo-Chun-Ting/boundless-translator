import Combine
import Foundation

@MainActor
final class TranslationSettings: ObservableObject {
    static let defaultTargetLanguageIdentifier = "zh-Hant"

    @Published var sourceLanguageIdentifier: String? {
        didSet {
            defaults.set(sourceLanguageIdentifier, forKey: sourceLanguageKey)
        }
    }

    @Published var targetLanguageIdentifier: String {
        didSet {
            defaults.set(targetLanguageIdentifier, forKey: targetLanguageKey)
        }
    }

    private let defaults: UserDefaults
    private let sourceLanguageKey = "sourceLanguageIdentifier"
    private let targetLanguageKey = "targetLanguageIdentifier"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sourceLanguageIdentifier = defaults.string(forKey: sourceLanguageKey)
        targetLanguageIdentifier = defaults.string(forKey: targetLanguageKey)
            ?? Self.defaultTargetLanguageIdentifier
    }

    func validateSourceLanguage(supportedLanguages: [Locale.Language]) {
        guard let sourceLanguageIdentifier, !supportedLanguages.isEmpty else {
            return
        }

        let sourceLanguage = Locale.Language(identifier: sourceLanguageIdentifier)
        let isSupported = supportedLanguages.contains {
            $0.maximalIdentifier == sourceLanguage.maximalIdentifier
        }
        if !isSupported {
            self.sourceLanguageIdentifier = nil
        }
    }

    func validateTargetLanguage(supportedLanguages: [Locale.Language]) {
        guard !supportedLanguages.isEmpty else {
            return
        }

        let selectedLanguage = Locale.Language(identifier: targetLanguageIdentifier)
        if supportedLanguages.contains(where: {
            $0.maximalIdentifier == selectedLanguage.maximalIdentifier
        }) {
            return
        }

        let defaultLanguage = Locale.Language(
            identifier: Self.defaultTargetLanguageIdentifier
        )
        if supportedLanguages.contains(where: {
            $0.maximalIdentifier == defaultLanguage.maximalIdentifier
        }) {
            targetLanguageIdentifier = Self.defaultTargetLanguageIdentifier
        } else if let firstSupportedLanguage = supportedLanguages.first {
            targetLanguageIdentifier = firstSupportedLanguage.minimalIdentifier
        }
    }
}
