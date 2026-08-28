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
        compactHeight: CGFloat = 180,
        maximumHeight: CGFloat = 440,
        translationNonContentHeight: CGFloat = 73
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

    func dictionaryMetrics(
        status: DictionaryLookupStatus
    ) -> TranslationPanelMetrics {
        makeMetrics(
            idealContentHeight: dictionaryHeight(for: status),
            nonContentHeight: 0
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
            NSFont.systemFontSize
        )

        return TranslationPanelMetrics(
            size: CGSize(width: panelWidth, height: panelHeight),
            contentHeight: contentHeight,
            idealContentHeight: idealContentHeight
        )
    }

    private func dictionaryHeight(
        for status: DictionaryLookupStatus
    ) -> CGFloat {
        switch status {
        case .idle:
            return compactHeight
        case .notFound:
            return 120
        case .found(let definition):
            let contentWidth = panelWidth - 40
            let termHeight = measuredHeight(
                for: definition.term,
                width: contentWidth,
                font: .systemFont(ofSize: 20, weight: .semibold)
            )
            let definitionHeight = measuredHeight(
                for: definition.text,
                width: contentWidth
            )
            return termHeight + definitionHeight + 52
        }
    }

    private func resultHeight(for status: TranslationStatus) -> CGFloat {
        switch status {
        case .idle:
            measuredHeight(for: "Select text and press Command-Shift-T to translate it.")
        case .translating:
            NSFont.systemFontSize
        case .translated(let output):
            measuredHeight(for: output.translatedText)
        case .failed(let failure):
            measuredHeight(for: failure.message) + 52
        }
    }

    private func measuredHeight(for text: String) -> CGFloat {
        let contentWidth = (panelWidth - 1) / 2 - 28
        return measuredHeight(for: text, width: contentWidth)
    }

    private func measuredHeight(
        for text: String,
        width: CGFloat,
        font: NSFont = .systemFont(ofSize: NSFont.systemFontSize)
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
