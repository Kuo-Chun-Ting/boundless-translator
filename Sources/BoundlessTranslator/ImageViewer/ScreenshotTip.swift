import SwiftUI
import TipKit

struct ScreenshotTip: Tip {
    let localization: AppLocalization
    let shortcut: String

    var title: Text { Text(verbatim: localization.string("screenshot.hintTitle")) }
    var message: Text? { Text(verbatim: instruction) }

    var instruction: String {
        localization.string("screenshot.guidance", arguments: shortcut)
    }
}
