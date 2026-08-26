import Foundation

struct TranslationRequest: Equatable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let sourceLanguageIdentifier: String
    let targetLanguageIdentifier: String
    let sourceLanguageWasDetected: Bool

    init(
        id: UUID = UUID(),
        text: String,
        sourceLanguageIdentifier: String,
        targetLanguageIdentifier: String,
        sourceLanguageWasDetected: Bool = false
    ) {
        self.id = id
        self.text = text
        self.sourceLanguageIdentifier = sourceLanguageIdentifier
        self.targetLanguageIdentifier = targetLanguageIdentifier
        self.sourceLanguageWasDetected = sourceLanguageWasDetected
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
