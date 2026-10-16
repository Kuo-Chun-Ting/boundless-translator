import SwiftUI
import TipKit

struct TranslationLanguageTip: Tip {
    let localization: AppLocalization

    var title: Text {
        Text(verbatim: localization.string("translationLanguages.title"))
    }

    var message: Text? {
        Text(verbatim: localization.string("translationLanguages.guidance"))
    }
}
