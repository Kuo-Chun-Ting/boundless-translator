import Foundation

struct DictionaryLookupSelection: Equatable, Sendable {
    let text: String
    let range: NSRange

    static func make(
        text: String,
        selectedRange: NSRange
    ) -> DictionaryLookupSelection? {
        guard selectedRange.length > 0,
              let stringRange = Range(selectedRange, in: text) else {
            return nil
        }

        let selectedText = String(text[stringRange])
        let trimmedText = selectedText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedText.isEmpty,
              let trimmedRange = text.range(
                of: trimmedText,
                options: .literal,
                range: stringRange
              ) else {
            return nil
        }

        return DictionaryLookupSelection(
            text: trimmedText,
            range: NSRange(trimmedRange, in: text)
        )
    }
}
