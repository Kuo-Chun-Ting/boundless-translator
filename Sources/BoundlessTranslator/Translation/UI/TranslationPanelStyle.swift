import AppKit

enum TranslationWindowStyle {
    static var contentFont: NSFont {
        let systemFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        guard
            let descriptor = systemFont.fontDescriptor.withDesign(.serif),
            let serifFont = NSFont(
                descriptor: descriptor,
                size: NSFont.systemFontSize
            )
        else {
            return systemFont
        }
        return serifFont
    }

    static let contentPadding: CGFloat = 18
    static let languageRowHeight: CGFloat = 32
    static let controlsVerticalPadding: CGFloat = 10
    static let speechControlSpacing: CGFloat = 8
    static let speechControlSize: CGFloat = 32
    static let speechButtonSize: CGFloat = 28

    static var nonContentHeight: CGFloat {
        languageRowHeight
            + controlsVerticalPadding * 2
            + contentPadding * 2
    }
}
