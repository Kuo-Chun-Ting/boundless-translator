import Foundation

struct TranslationRequest: Equatable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let sourceLanguageIdentifier: String
    let targetLanguageIdentifier: String

    init(
        id: UUID = UUID(),
        text: String,
        sourceLanguageIdentifier: String,
        targetLanguageIdentifier: String
    ) {
        self.id = id
        self.text = text
        self.sourceLanguageIdentifier = sourceLanguageIdentifier
        self.targetLanguageIdentifier = targetLanguageIdentifier
    }
}

struct TranslationOutput: Equatable, Sendable {
    let translatedText: String
    let sourceLanguageIdentifier: String
    let targetLanguageIdentifier: String
}

enum TranslationStatus: Equatable, Sendable {
    case idle
    case translating
    case translated(TranslationOutput)
    case failed(TranslationFailure)
}
