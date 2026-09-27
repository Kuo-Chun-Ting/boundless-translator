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
            TranslationPerformanceLog.record("apple_translate_begin", id: request.id, detail: "utf8_bytes=\(request.text.utf8.count)")
            let output = try await translateText(request.text)
            TranslationPerformanceLog.record("apple_translate_returned", id: request.id)
            return output
        } catch is CancellationError {
            TranslationPerformanceLog.record("apple_translate_cancelled_error", id: request.id)
            throw CancellationError()
        } catch {
            let failure = error as NSError
            TranslationPerformanceLog.record("apple_translate_error", id: request.id, detail: "domain=\(failure.domain) code=\(failure.code)")
            throw AppleTranslationErrorMapper.map(error)
        }
    }
}
