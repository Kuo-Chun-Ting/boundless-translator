import SwiftUI
import TipKit
import Foundation

struct ScreenshotTip: Tip {
    let localization: AppLocalization
    let shortcut: String

    var title: Text { Text(verbatim: localization.string("screenshot.hintTitle")) }
    var message: Text? { Text(verbatim: instruction) }

    var instruction: String {
        localization.string("screenshot.guidance", arguments: shortcut)
    }
}

struct ScreenshotLanguageTip: Tip {
    let localization: AppLocalization
    let sourceLanguageIdentifier: String

    var title: Text { Text(verbatim: localization.string("screenshot.languageLimitTitle")) }
    var message: Text? { Text(verbatim: instruction) }

    var instruction: String {
        let language = LanguageDisplayNameFormatter(
            locale: Locale(identifier: localization.languageIdentifier)
        ).name(for: sourceLanguageIdentifier)
        return localization.string("screenshot.languageLimitMessage", arguments: language)
    }

    static func make(
        localization: AppLocalization, sourceLanguageIdentifier: String?,
        recognitionLanguages: [String]?
    ) -> ScreenshotLanguageTip? {
        guard let sourceLanguageIdentifier, let recognitionLanguages else { return nil }
        let source = languageGroup(sourceLanguageIdentifier)
        guard !recognitionLanguages.contains(where: { languageGroup($0) == source }) else { return nil }
        return ScreenshotLanguageTip(
            localization: localization, sourceLanguageIdentifier: sourceLanguageIdentifier)
    }

    private static func languageGroup(_ identifier: String) -> String {
        let language = Locale.Language(identifier: identifier)
        let code = language.languageCode?.identifier ?? identifier
        let normalizedCode = code == "no" ? "nb" : code
        return "\(normalizedCode)-\(language.script?.identifier ?? "")"
    }
}
