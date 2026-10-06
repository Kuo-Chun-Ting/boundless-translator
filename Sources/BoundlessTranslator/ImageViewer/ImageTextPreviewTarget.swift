import Foundation

struct ImageTextPreviewTarget: Equatable {
    let text: String
    let range: NSRange
    let bounds: CGRect

    static func make(document: ImageTextDocument, selection: NSRange?, point: CGPoint) -> Self? {
        guard let range = selection ?? document.word(at: point)?.range,
              range.length > 0 else { return nil }
        let regions = document.selectionRegions.filter {
            NSIntersectionRange($0.range, range).length > 0
        }
        guard let first = regions.first else { return nil }
        return Self(text: document.text(in: range), range: range,
                    bounds: regions.dropFirst().reduce(first.bounds) { $0.union($1.bounds) })
    }
}

enum ImageTextPreviewPositioner {
    static func frame(anchor: CGRect, size: CGSize, visibleFrame: CGRect) -> CGRect {
        let size = CGSize(width: min(size.width, visibleFrame.width),
                          height: min(size.height, visibleFrame.height))
        let above = anchor.maxY + 8
        let y = above + size.height <= visibleFrame.maxY ? above : anchor.minY - 8 - size.height
        return CGRect(x: min(max(anchor.midX - size.width / 2, visibleFrame.minX),
                             visibleFrame.maxX - size.width),
                      y: min(max(y, visibleFrame.minY), visibleFrame.maxY - size.height),
                      width: size.width, height: size.height)
    }
}
