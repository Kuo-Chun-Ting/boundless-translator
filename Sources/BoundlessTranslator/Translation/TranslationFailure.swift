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

    func message(localization: AppLocalization) -> String {
        switch self {
        case .unsupportedSourceLanguage:
            localization.string("translationFailure.unsupportedSource")
        case .unsupportedTargetLanguage:
            localization.string("translationFailure.unsupportedTarget")
        case .unsupportedLanguagePairing:
            localization.string("translationFailure.unsupportedPair")
        case .unableToIdentifyLanguage:
            localization.string("translationFailure.unidentifiedSource")
        case .nothingToTranslate:
            localization.string("translationFailure.emptyInput")
        case .languageNotInstalled:
            localization.string("translationFailure.missingLanguagePack")
        case .unexpected(let description):
            localization.string(
                "translationFailure.unknown",
                arguments: description
            )
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
