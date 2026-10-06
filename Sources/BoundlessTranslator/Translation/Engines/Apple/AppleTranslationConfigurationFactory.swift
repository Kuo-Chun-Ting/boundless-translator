import Foundation
@preconcurrency import Translation

enum AppleTranslationConfigurationFactory {
    static func make(
        for request: TranslationRequest
    ) -> TranslationSession.Configuration {
        TranslationSession.Configuration(
            source: request.sourceLanguageIdentifier.map { Locale.Language(identifier: $0) },
            target: Locale.Language(
                identifier: request.targetLanguageIdentifier
            )
        )
    }
}
