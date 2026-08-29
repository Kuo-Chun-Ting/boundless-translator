import AppKit

final class OverflowAwareScrollView: NSScrollView {
    override func layout() {
        super.layout()
        updateVerticalScrollerVisibility()
    }

    private func updateVerticalScrollerVisibility() {
        guard let documentView else {
            return
        }

        let contentOverflows = documentView.frame.height > contentSize.height + 0.5
        guard hasVerticalScroller != contentOverflows else {
            return
        }

        hasVerticalScroller = contentOverflows
        super.layout()
    }
}
