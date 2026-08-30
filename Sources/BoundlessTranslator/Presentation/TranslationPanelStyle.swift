import AppKit

enum TranslationPanelStyle {
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

    static let horizontalPadding: CGFloat = 14
    static let bottomPadding: CGFloat = 14
    static let columnSpacing: CGFloat = 12
    static let languageRowHeight: CGFloat = 26
    static let contentSpacing: CGFloat = 10
    static let languageMenuWidth: CGFloat = 210
    static let cardContentPadding: CGFloat = 14
    static let cardCornerRadius: CGFloat = 12
    static let cardBackgroundColor = NSColor(
        name: nil,
        dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(calibratedWhite: isDark ? 0.16 : 0.97, alpha: 1)
        }
    )

    static var nonContentHeight: CGFloat {
        languageRowHeight
            + contentSpacing
            + cardContentPadding * 2
            + bottomPadding
    }
}
