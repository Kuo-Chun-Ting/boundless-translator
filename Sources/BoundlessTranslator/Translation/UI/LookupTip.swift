import SwiftUI
import TipKit

struct LookupTip: Tip {
    let localization: AppLocalization

    var title: Text { Text(verbatim: localization.string("lookup.title")) }
    var message: Text? { Text(verbatim: localization.string("lookup.guidance")) }
}
