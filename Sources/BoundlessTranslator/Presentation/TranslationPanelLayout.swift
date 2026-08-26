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
    private let nonContentHeight: CGFloat

    init(
        panelWidth: CGFloat = 560,
        compactHeight: CGFloat = 180,
        maximumHeight: CGFloat = 440,
        nonContentHeight: CGFloat = 116
    ) {
        self.panelWidth = panelWidth
        self.compactHeight = compactHeight
        self.maximumHeight = maximumHeight
        self.nonContentHeight = nonContentHeight
    }

    func metrics(
        sourceText: String,
        status: TranslationStatus
    ) -> TranslationPanelMetrics {
        let idealContentHeight = max(
            measuredHeight(for: sourceText),
            resultHeight(for: status)
        )
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
        let bounds = (text as NSString).boundingRect(
            with: CGSize(
                width: contentWidth,
                height: CGFloat.greatestFiniteMagnitude
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ]
        )
        return max(ceil(bounds.height), NSFont.systemFontSize)
    }
}
