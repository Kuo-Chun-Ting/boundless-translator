import AppKit
import SwiftUI

struct SelectableTranslationTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let textView = TranslationTextViewFactory.make()
        textView.setAccessibilityIdentifier("translation.targetText")
        let scrollView = OverflowAwareScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = false
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }
        guard textView.string != text else {
            return
        }

        let visibleOrigin = scrollView.contentView.bounds.origin
        if !textView.string.isEmpty, text.hasPrefix(textView.string) {
            let suffix = String(text.dropFirst(textView.string.count))
            textView.textStorage?.append(NSAttributedString(string: suffix, attributes: [
                .font: TranslationWindowStyle.contentFont, .foregroundColor: NSColor.labelColor
            ]))
        } else {
            textView.string = text
        }
        scrollView.contentView.scroll(to: visibleOrigin)
    }
}
