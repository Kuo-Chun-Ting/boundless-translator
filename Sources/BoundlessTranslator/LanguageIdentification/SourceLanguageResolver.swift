struct LanguageHypothesis: Equatable, Sendable {
    let languageIdentifier: String
    let confidence: Double
}

enum SourceLanguageResolution: Equatable, Sendable {
    case resolved(String)
    case needsSelection(suggestedLanguageIdentifier: String?)
}

protocol SourceLanguageIdentifying: Sendable {
    func identify(_ text: String) -> [LanguageHypothesis]
}

struct SourceLanguageResolver: Sendable {
    private let minimumConfidence: Double
    private let languageIdentifier: any SourceLanguageIdentifying

    init(
        minimumConfidence: Double,
        languageIdentifier: any SourceLanguageIdentifying
    ) {
        self.minimumConfidence = minimumConfidence
        self.languageIdentifier = languageIdentifier
    }

    func resolve(
        text: String,
        configuredSource: String?
    ) -> SourceLanguageResolution {
        if let configuredSource {
            return .resolved(configuredSource)
        }

        let strongestHypothesis = languageIdentifier.identify(text).max {
            $0.confidence < $1.confidence
        }
        guard let strongestHypothesis else {
            return .needsSelection(suggestedLanguageIdentifier: nil)
        }
        guard strongestHypothesis.confidence >= minimumConfidence else {
            return .needsSelection(
                suggestedLanguageIdentifier: strongestHypothesis.languageIdentifier
            )
        }
        return .resolved(strongestHypothesis.languageIdentifier)
    }
}
