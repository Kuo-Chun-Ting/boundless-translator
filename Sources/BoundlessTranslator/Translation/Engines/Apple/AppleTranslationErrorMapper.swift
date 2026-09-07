import Foundation
import Translation

enum AppleTranslationErrorMapper {
    static func map(_ error: Error) -> TranslationFailure {
        if TranslationError.unsupportedSourceLanguage ~= error {
            return .unsupportedSourceLanguage
        }
        if TranslationError.unsupportedTargetLanguage ~= error {
            return .unsupportedTargetLanguage
        }
        if TranslationError.unsupportedLanguagePairing ~= error {
            return .unsupportedLanguagePairing
        }
        if TranslationError.unableToIdentifyLanguage ~= error {
            return .unableToIdentifyLanguage
        }
        if TranslationError.nothingToTranslate ~= error {
            return .nothingToTranslate
        }
        if #available(macOS 26.0, *), TranslationError.notInstalled ~= error {
            return .languageNotInstalled
        }
        return TranslationFailure(error: error)
    }
}
