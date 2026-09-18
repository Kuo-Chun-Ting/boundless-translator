import AppKit

struct TranslationWindowMetrics: Equatable {
    let size: CGSize
    let contentHeight: CGFloat
    let idealContentHeight: CGFloat
}

struct TranslationWindowLayout {
    private let windowWidth: CGFloat
    private let compactHeight: CGFloat
    private let maximumHeight: CGFloat
    private let translationNonContentHeight: CGFloat

    init(
        windowWidth: CGFloat = 560,
        compactHeight: CGFloat = 211,
        maximumHeight: CGFloat = 440,
        translationNonContentHeight: CGFloat = TranslationWindowStyle.nonContentHeight
    ) {
        self.windowWidth = windowWidth
        self.compactHeight = compactHeight
        self.maximumHeight = maximumHeight
        self.translationNonContentHeight = translationNonContentHeight
    }

    func metrics(
        sourceText: String,
        status: TranslationStatus,
        localization: AppLocalization
    ) -> TranslationWindowMetrics {
        let idealContentHeight = max(
            measuredHeight(for: sourceText),
            resultHeight(for: status, localization: localization)
        )
        return makeMetrics(
            idealContentHeight: idealContentHeight,
            nonContentHeight: translationNonContentHeight
        )
    }

    private func makeMetrics(
        idealContentHeight: CGFloat,
        nonContentHeight: CGFloat
    ) -> TranslationWindowMetrics {
        let desiredHeight = nonContentHeight + idealContentHeight
        let windowHeight = min(
            max(desiredHeight, compactHeight),
            maximumHeight
        )
        let contentHeight = max(
            windowHeight - nonContentHeight,
            TranslationWindowStyle.contentFont.pointSize
        )

        return TranslationWindowMetrics(
            size: CGSize(width: windowWidth, height: windowHeight),
            contentHeight: contentHeight,
            idealContentHeight: idealContentHeight
        )
    }

    private func resultHeight(
        for status: TranslationStatus,
        localization: AppLocalization
    ) -> CGFloat {
        switch status {
        case .idle:
            measuredHeight(for: localization.string("panel.idle"))
        case .translating:
            TranslationWindowStyle.contentFont.pointSize
        case .translated(let output):
            measuredHeight(for: output.translatedText)
        case .failed(let failure):
            measuredHeight(for: failure.message(localization: localization)) + 52
        }
    }

    private func measuredHeight(for text: String) -> CGFloat {
        let availableWidth = windowWidth
            - TranslationWindowStyle.horizontalPadding * 2
            - TranslationWindowStyle.columnSpacing
        let contentWidth = availableWidth / 2
            - TranslationWindowStyle.cardContentPadding * 2
        return measuredHeight(for: text, width: contentWidth)
    }

    private func measuredHeight(
        for text: String,
        width: CGFloat,
        font: NSFont = TranslationWindowStyle.contentFont
    ) -> CGFloat {
        let bounds = (text as NSString).boundingRect(
            with: CGSize(
                width: width,
                height: CGFloat.greatestFiniteMagnitude
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [
                .font: font
            ]
        )
        return max(ceil(bounds.height), font.pointSize)
    }
}
