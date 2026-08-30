import AppKit

struct TranslationPanelMetrics: Equatable {
    let size: CGSize
    let contentHeight: CGFloat
    let idealContentHeight: CGFloat
}

struct TranslationPanelLayout {
    private let panelWidth: CGFloat
    private let compactHeight: CGFloat
    private let maximumHeight: CGFloat
    private let translationNonContentHeight: CGFloat

    init(
        panelWidth: CGFloat = 560,
        compactHeight: CGFloat = 211,
        maximumHeight: CGFloat = 440,
        translationNonContentHeight: CGFloat = TranslationPanelStyle.nonContentHeight
    ) {
        self.panelWidth = panelWidth
        self.compactHeight = compactHeight
        self.maximumHeight = maximumHeight
        self.translationNonContentHeight = translationNonContentHeight
    }

    func metrics(
        sourceText: String,
        status: TranslationStatus
    ) -> TranslationPanelMetrics {
        let idealContentHeight = max(
            measuredHeight(for: sourceText),
            resultHeight(for: status)
        )
        return makeMetrics(
            idealContentHeight: idealContentHeight,
            nonContentHeight: translationNonContentHeight
        )
    }

    private func makeMetrics(
        idealContentHeight: CGFloat,
        nonContentHeight: CGFloat
    ) -> TranslationPanelMetrics {
        let desiredHeight = nonContentHeight + idealContentHeight
        let panelHeight = min(
            max(desiredHeight, compactHeight),
            maximumHeight
        )
        let contentHeight = max(
            panelHeight - nonContentHeight,
            TranslationPanelStyle.contentFont.pointSize
        )

        return TranslationPanelMetrics(
            size: CGSize(width: panelWidth, height: panelHeight),
            contentHeight: contentHeight,
            idealContentHeight: idealContentHeight
        )
    }

    private func resultHeight(for status: TranslationStatus) -> CGFloat {
        switch status {
        case .idle:
            measuredHeight(for: "Select text and press Command-Shift-T to translate it.")
        case .translating:
            TranslationPanelStyle.contentFont.pointSize
        case .translated(let output):
            measuredHeight(for: output.translatedText)
        case .failed(let failure):
            measuredHeight(for: failure.message) + 52
        }
    }

    private func measuredHeight(for text: String) -> CGFloat {
        let availableWidth = panelWidth
            - TranslationPanelStyle.horizontalPadding * 2
            - TranslationPanelStyle.columnSpacing
        let contentWidth = availableWidth / 2
            - TranslationPanelStyle.cardContentPadding * 2
        return measuredHeight(for: text, width: contentWidth)
    }

    private func measuredHeight(
        for text: String,
        width: CGFloat,
        font: NSFont = TranslationPanelStyle.contentFont
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
