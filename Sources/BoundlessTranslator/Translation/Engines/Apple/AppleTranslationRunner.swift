import Foundation
@preconcurrency import Translation

@MainActor
struct AppleTranslationRunner: TranslationRunning {
    private let translateText: @MainActor (String) async throws -> TranslationOutput

    init(session: TranslationSession) {
        self.init { text in
            let response = try await session.translate(text)
            return TranslationOutput(
                translatedText: response.targetText,
                sourceLanguageIdentifier: response.sourceLanguage.minimalIdentifier,
                targetLanguageIdentifier: response.targetLanguage.minimalIdentifier
            )
        }
    }

    init(translateText: @escaping @MainActor (String) async throws -> TranslationOutput) {
        self.translateText = translateText
    }

    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        do {
            return try await translateText(request.text)
        } catch {
            throw AppleTranslationErrorMapper.map(error)
        }
    }
}
