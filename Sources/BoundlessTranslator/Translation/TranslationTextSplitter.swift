import Foundation
import NaturalLanguage

struct TranslationTextSplitter: Sendable {
    let targetCharacters: Int

    init(targetCharacters: Int = 10_000) {
        precondition(targetCharacters > 0)
        self.targetCharacters = targetCharacters
    }

    func split(_ text: String, languageIdentifier: String?) throws -> [String] {
        var chunks: [String] = []
        var current = ""
        var currentCount = 0
        for paragraph in try units(in: text, unit: .paragraph, languageIdentifier: languageIdentifier) {
            try Task.checkCancellation()
            let parts = paragraph.count > targetCharacters
                ? try units(in: paragraph, unit: .sentence, languageIdentifier: languageIdentifier)
                : [paragraph]
            for part in parts {
                try Task.checkCancellation()
                let count = part.count
                if !current.isEmpty, currentCount + count > targetCharacters {
                    chunks.append(current)
                    current = ""
                    currentCount = 0
                }
                current += part
                currentCount += count
            }
        }
        if !current.isEmpty { chunks.append(current) }
        return chunks
    }

    private func units(
        in text: String,
        unit: NLTokenUnit,
        languageIdentifier: String?
    ) throws -> [String] {
        guard !text.isEmpty else { return [] }
        let tokenizer = NLTokenizer(unit: unit)
        tokenizer.string = text
        if let languageIdentifier {
            tokenizer.setLanguage(NLLanguage(rawValue: languageIdentifier))
        }
        var starts: [String.Index] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            guard !Task.isCancelled else { return false }
            starts.append(range.lowerBound)
            return true
        }
        try Task.checkCancellation()
        // Use adjacent starts, retaining every space and newline between tokens.
        let boundaries = [text.startIndex] + starts.dropFirst() + [text.endIndex]
        return zip(boundaries, boundaries.dropFirst()).map { String(text[$0..<$1]) }
    }
}
