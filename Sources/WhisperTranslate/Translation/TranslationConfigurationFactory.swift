import Foundation
@preconcurrency import Translation

enum TranslationConfigurationFactory {
    static func make(
        for request: TranslationRequest
    ) -> TranslationSession.Configuration {
        TranslationSession.Configuration(
            source: Locale.Language(
                identifier: request.sourceLanguageIdentifier
            ),
            target: Locale.Language(
                identifier: request.targetLanguageIdentifier
            )
        )
    }
}
