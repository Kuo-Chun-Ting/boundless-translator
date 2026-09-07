import NaturalLanguage

struct NaturalLanguageIdentifier: SourceLanguageIdentifying {
    func identify(_ text: String) -> [LanguageHypothesis] {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        return recognizer.languageHypotheses(withMaximum: 3).map {
            LanguageHypothesis(
                languageIdentifier: $0.key.rawValue,
                confidence: $0.value
            )
        }
    }
}
