import AppKit
import NaturalLanguage
import Vision

enum ImageTextRecognizer {
    static func recognize(_ image: CGImage, size: CGSize) throws -> ImageTextDocument {
        let request = makeRequest()
        try VNImageRequestHandler(cgImage: image).perform([request])
        return try makeDocument(from: request.results ?? [], size: size)
    }

    static func supportedLanguages() throws -> [String] {
        try makeRequest().supportedRecognitionLanguages()
    }

    private static func makeRequest() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        return request
    }

    private static func makeDocument(
        from observations: [VNRecognizedTextObservation], size: CGSize
    ) throws -> ImageTextDocument {
        var text = ""
        var words: [ImageTextRegion] = []
        var characters: [ImageTextRegion] = []
        for (line, observation) in observations.enumerated() {
            guard let result = observation.topCandidates(1).first else { continue }
            if !text.isEmpty { text += "\n" }
            let offset = text.utf16.count
            text += result.string
            words += try wordRanges(in: result.string).compactMap {
                try region(in: result, range: $0, offset: offset, line: line, size: size)
            }
            characters += try result.string.indices.compactMap { index in
                guard !result.string[index].isWhitespace else { return nil }
                return try region(
                    in: result, range: index..<result.string.index(after: index),
                    offset: offset, line: line, size: size
                )
            }
        }
        return ImageTextDocument(text: text, words: words, characters: characters)
    }

    private static func wordRanges(in text: String) -> [Range<String.Index>] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        let ranges = tokenizer.tokens(for: text.startIndex..<text.endIndex)
        return ranges.enumerated().map { index, range in
            var end = index + 1 < ranges.count ? ranges[index + 1].lowerBound : text.endIndex
            while end > range.upperBound && text[text.index(before: end)].isWhitespace {
                end = text.index(before: end)
            }
            return range.lowerBound..<end
        }
    }

    private static func region(
        in result: VNRecognizedText, range: Range<String.Index>,
        offset: Int, line: Int, size: CGSize
    ) throws -> ImageTextRegion? {
        guard let box = try result.boundingBox(for: range)?.boundingBox, !box.isEmpty else {
            return nil
        }
        let localRange = NSRange(range, in: result.string)
        return ImageTextRegion(
            range: NSRange(location: offset + localRange.location, length: localRange.length),
            bounds: CGRect(
                x: box.minX * size.width, y: box.minY * size.height,
                width: box.width * size.width, height: box.height * size.height),
            line: line
        )
    }
}
