import Foundation

enum TranslationFailure: Error, Equatable, Sendable {
    case unsupportedSourceLanguage
    case unsupportedTargetLanguage
    case unsupportedLanguagePairing
    case unableToIdentifyLanguage
    case nothingToTranslate
    case languageNotInstalled
    case unexpected(String)

    init(error: Error) {
        self = error as? TranslationFailure ?? .unexpected(error.localizedDescription)
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
