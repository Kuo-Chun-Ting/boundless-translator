import Foundation
@preconcurrency import Translation

@MainActor
struct AppleTranslationRunner: TranslationRunning {
    let session: TranslationSession

    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        let response = try await session.translate(request.text)

        return TranslationOutput(
            translatedText: response.targetText,
            sourceLanguageIdentifier: response.sourceLanguage.minimalIdentifier,
            targetLanguageIdentifier: response.targetLanguage.minimalIdentifier
        )
    }
}
