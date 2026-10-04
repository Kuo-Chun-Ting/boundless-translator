import CoreGraphics
import Foundation

struct ImageTextRegion: Equatable, Sendable {
    let range: NSRange
    let bounds: CGRect
    let line: Int
}

struct ImageTextDocument: Sendable {
    let text: String
    let words: [ImageTextRegion]
    let selectionRegions: [ImageTextRegion]

    init(text: String, words: [ImageTextRegion], characters: [ImageTextRegion] = []) {
        let layout = ImageTextLayout.arrange(text: text, words: words, characters: characters)
        self.text = layout.text
        self.words = layout.words
        selectionRegions = Self.completeGeometry(words: layout.words, characters: layout.characters)
    }

    func range(from start: CGPoint, to end: CGPoint) -> NSRange? {
        guard let first = nearestSelectionRegion(to: start), let last = nearestSelectionRegion(to: end)
        else { return nil }
        let lower = min(first.range.location, last.range.location)
        let upper = max(NSMaxRange(first.range), NSMaxRange(last.range))
        return NSRange(location: lower, length: upper - lower)
    }

    func intersectsText(from start: CGPoint, to end: CGPoint) -> Bool {
        selectionRegions.contains { intersects($0.bounds, from: start, to: end) }
    }

    func word(at point: CGPoint) -> ImageTextRegion? {
        words.first { $0.bounds.contains(point) }
    }

    func text(in range: NSRange?) -> String {
        range.map { (text as NSString).substring(with: $0) } ?? ""
    }

    // Vision's accurate recognizer can return one word box for several characters.
    // Treat that geometry as one selectable range instead of dropping all but its first character.
    private static func mergeSharedBounds(_ characters: [ImageTextRegion]) -> [ImageTextRegion] {
        characters.reduce(into: []) { regions, character in
            guard let previous = regions.last,
                  previous.line == character.line, previous.bounds == character.bounds else {
                regions.append(character)
                return
            }
            regions[regions.count - 1] = ImageTextRegion(
                range: NSUnionRange(previous.range, character.range),
                bounds: previous.bounds, line: previous.line
            )
        }
    }

    private static func completeGeometry(words: [ImageTextRegion], characters: [ImageTextRegion]) -> [ImageTextRegion] {
        var regions = mergeSharedBounds(characters)
        for word in words {
            let overlaps = regions.filter { NSIntersectionRange($0.range, word.range).length > 0 }
            let covered = overlaps.reduce(0) { $0 + NSIntersectionRange($1.range, word.range).length }
            guard covered < word.range.length else { continue }
            // Missing character geometry must not make recognized letters disappear.
            let range = overlaps.reduce(word.range) { NSUnionRange($0, $1.range) }
            let bounds = overlaps.reduce(word.bounds) { $0.union($1.bounds) }
            regions.removeAll { NSIntersectionRange($0.range, range).length > 0 }
            regions.append(ImageTextRegion(range: range, bounds: bounds, line: word.line))
        }
        return regions.sorted { $0.range.location < $1.range.location }
    }

    private func nearestSelectionRegion(to point: CGPoint) -> ImageTextRegion? {
        if let hit = selectionRegions.first(where: { $0.bounds.contains(point) }) { return hit }
        let lines = Dictionary(grouping: selectionRegions, by: \.line)
        guard
            let line = lines.values.min(by: {
                verticalDistance(point.y, to: $0) < verticalDistance(point.y, to: $1)
            })
        else { return nil }
        return line.min {
            horizontalDistance(point.x, $0.bounds) < horizontalDistance(point.x, $1.bounds)
        }
    }

    private func horizontalDistance(_ x: CGFloat, _ rect: CGRect) -> CGFloat {
        max(rect.minX - x, x - rect.maxX, 0)
    }

    private func verticalDistance(_ y: CGFloat, to row: [ImageTextRegion]) -> CGFloat {
        let bounds = row.dropFirst().reduce(row[0].bounds) { $0.union($1.bounds) }
        return max(bounds.minY - y, y - bounds.maxY, 0)
    }

    private func intersects(_ rect: CGRect, from start: CGPoint, to end: CGPoint) -> Bool {
        var entry: CGFloat = 0
        var exit: CGFloat = 1
        for (origin, distance, lower, upper) in [
            (start.x, end.x - start.x, rect.minX, rect.maxX),
            (start.y, end.y - start.y, rect.minY, rect.maxY)
        ] {
            if distance == 0 {
                if origin < lower || origin > upper { return false }
                continue
            }
            let first = (lower - origin) / distance
            let last = (upper - origin) / distance
            entry = max(entry, min(first, last))
            exit = min(exit, max(first, last))
            if entry > exit { return false }
        }
        return true
    }
}
