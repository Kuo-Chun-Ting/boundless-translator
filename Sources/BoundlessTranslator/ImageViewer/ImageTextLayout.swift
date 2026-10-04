import CoreGraphics
import Foundation

enum ImageTextLayout {
    private struct Fragment {
        let range: NSRange
        let bounds: CGRect
        let words: [ImageTextRegion]
        let characters: [ImageTextRegion]
    }

    static func arrange(text: String, words: [ImageTextRegion], characters: [ImageTextRegion]) -> (
        text: String, words: [ImageTextRegion], characters: [ImageTextRegion]
    ) {
        let fragments = makeFragments(words: words, characters: characters)
        guard !fragments.isEmpty else { return (text, words, characters) }
        let rows = visualRows(fragments)
        var arrangedText = ""
        var arrangedWords: [ImageTextRegion] = []
        var arrangedCharacters: [ImageTextRegion] = []
        for (line, row) in rows.enumerated() {
            if line > 0 { arrangedText += separator(between: rows[line - 1], and: row, text: text) }
            for (index, fragment) in row.enumerated() {
                if index > 0 { arrangedText += " " }
                let offset = (arrangedText as NSString).length - fragment.range.location
                arrangedText += (text as NSString).substring(with: fragment.range)
                arrangedWords += remap(fragment.words, offset: offset, line: line)
                arrangedCharacters += remap(fragment.characters, offset: offset, line: line)
            }
        }
        return (arrangedText, arrangedWords, arrangedCharacters)
    }

    private static func separator(between previous: [Fragment], and next: [Fragment], text: String) -> String {
        guard previous.count == 1, next.count == 1 else { return "\n" }
        let upper = previous[0].bounds
        let lower = next[0].bounds
        let height = min(upper.height, lower.height)
        let gap = upper.minY - lower.maxY
        let aligned = abs(upper.minX - lower.minX) <= height / 2
            || abs(upper.maxX - lower.maxX) <= height / 2
        guard aligned, gap >= 0, gap <= height * 0.8,
              max(upper.height, lower.height) <= height * 1.5 else { return "\n" }
        let source = text as NSString
        let last = source.substring(with: previous[0].range).unicodeScalars.last
        let first = source.substring(with: next[0].range).unicodeScalars.first
        if let last, let first, isUnspacedScript(last), isUnspacedScript(first) { return "" }
        return " "
    }

    private static func isUnspacedScript(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3000...0x30FF, 0x3400...0x9FFF, 0xF900...0xFAFF, 0xFF00...0xFFEF,
             0x20000...0x2FA1F:
            return true
        default:
            return false
        }
    }

    private static func makeFragments(words: [ImageTextRegion], characters: [ImageTextRegion])
        -> [Fragment]
    {
        let wordLines = Dictionary(grouping: words, by: \.line)
        let characterLines = Dictionary(grouping: characters, by: \.line)
        return Set(wordLines.keys).union(characterLines.keys).map { line in
            let lineWords = wordLines[line] ?? []
            let lineCharacters = characterLines[line] ?? []
            let regions = lineWords + lineCharacters
            let lower = regions.map(\.range.location).min()!
            let upper = regions.map { NSMaxRange($0.range) }.max()!
            let bounds = regions.dropFirst().reduce(regions[0].bounds) { $0.union($1.bounds) }
            return Fragment(
                range: NSRange(location: lower, length: upper - lower), bounds: bounds,
                words: lineWords, characters: lineCharacters)
        }
    }

    private static func visualRows(_ fragments: [Fragment]) -> [[Fragment]] {
        var rows: [[Fragment]] = []
        let sorted = fragments.sorted {
            $0.bounds.midY == $1.bounds.midY
                ? $0.bounds.minX < $1.bounds.minX : $0.bounds.midY > $1.bounds.midY
        }
        for fragment in sorted {
            if let index = rows.firstIndex(where: { row in row.allSatisfy { sharesRow($0, fragment) } }) {
                rows[index].append(fragment)
            } else {
                rows.append([fragment])
            }
        }
        return rows.map { $0.sorted { $0.bounds.minX < $1.bounds.minX } }
    }

    private static func sharesRow(_ first: Fragment, _ second: Fragment) -> Bool {
        let overlap =
            min(first.bounds.maxY, second.bounds.maxY) - max(first.bounds.minY, second.bounds.minY)
        return overlap >= min(first.bounds.height, second.bounds.height) * 0.5
    }

    private static func remap(_ regions: [ImageTextRegion], offset: Int, line: Int)
        -> [ImageTextRegion]
    {
        regions.map {
            ImageTextRegion(
                range: NSRange(location: $0.range.location + offset, length: $0.range.length),
                bounds: $0.bounds, line: line)
        }
    }
}
