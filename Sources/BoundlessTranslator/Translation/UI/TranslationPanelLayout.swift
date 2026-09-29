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
        partialOutput: TranslationOutput? = nil,
        sourceAccessoryHeight: CGFloat = 0,
        localization: AppLocalization
    ) -> TranslationWindowMetrics {
        let idealContentHeight = max(
            measuredHeight(for: sourceText) + sourceAccessoryHeight,
            max(
                resultHeight(for: status, localization: localization),
                partialOutput.map { measuredHeight(for: $0.translatedText) } ?? 0
            )
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
        let contentWidth = windowWidth / 2
            - TranslationWindowStyle.contentPadding * 2
        return measuredHeight(for: text, width: contentWidth)
    }

    private func measuredHeight(
        for text: String,
        width: CGFloat,
        font: NSFont = TranslationWindowStyle.contentFont
    ) -> CGFloat {
        // Only lay out enough lines to size the capped window, not the entire document.
        let storage = NSTextStorage(string: text, attributes: [.font: font])
        let manager = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: width, height: maximumHeight))
        container.lineFragmentPadding = 0
        storage.addLayoutManager(manager)
        manager.addTextContainer(container)
        manager.ensureLayout(for: container)
        return max(ceil(manager.usedRect(for: container).height), font.pointSize)
    }
}
