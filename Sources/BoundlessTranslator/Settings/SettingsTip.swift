import SwiftUI
import TipKit

struct SettingsTip: Tip {
    let localization: AppLocalization

    var title: Text { Text(verbatim: localization.string("usage.label")) }
    var message: Text? { Text(verbatim: localization.string("usage.guidance")) }
}
