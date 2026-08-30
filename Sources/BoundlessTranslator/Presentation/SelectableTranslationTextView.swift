import AppKit
import SwiftUI

struct SelectableTranslationTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let textView = TranslationTextViewFactory.make()
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

        textView.string = text
    }
}
