import Foundation
import Translation

enum TranslationFailure: Error, Equatable, Sendable {
    case unsupportedSourceLanguage
    case unsupportedTargetLanguage
    case unsupportedLanguagePairing
    case unableToIdentifyLanguage
    case nothingToTranslate
    case languageNotInstalled
    case unexpected(String)

    init(error: Error) {
        if TranslationError.unsupportedSourceLanguage ~= error {
            self = .unsupportedSourceLanguage
        } else if TranslationError.unsupportedTargetLanguage ~= error {
            self = .unsupportedTargetLanguage
        } else if TranslationError.unsupportedLanguagePairing ~= error {
            self = .unsupportedLanguagePairing
        } else if TranslationError.unableToIdentifyLanguage ~= error {
            self = .unableToIdentifyLanguage
        } else if TranslationError.nothingToTranslate ~= error {
            self = .nothingToTranslate
        } else if #available(macOS 26.0, *), TranslationError.notInstalled ~= error {
            self = .languageNotInstalled
        } else {
            self = .unexpected(error.localizedDescription)
        }
    }

    var message: String {
        switch self {
        case .unsupportedSourceLanguage:
            "The language of the selected text is not supported."
        case .unsupportedTargetLanguage:
            "The selected target language is not supported. Choose another language in Settings."
        case .unsupportedLanguagePairing:
            "The text may already be in the target language, or this language pair is not supported."
        case .unableToIdentifyLanguage:
            "The language of the selected text could not be detected."
        case .nothingToTranslate:
            "The selection does not contain text that can be translated."
        case .languageNotInstalled:
            "The required language is not installed. Try again and allow macOS to download it."
        case .unexpected(let description):
            "\(description) Try again."
        }
    }

    var canRetry: Bool {
        switch self {
        case .languageNotInstalled, .unexpected:
            true
        default:
            false
        }
    }
}
