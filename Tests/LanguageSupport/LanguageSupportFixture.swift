import Foundation
import Testing
import Vision
@testable import BoundlessTranslator

struct LanguageSupportFixture: Decodable, Sendable, CustomTestStringConvertible {
    let id: String
    let text: String
    let ocrImage: String?

    var testDescription: String { id }

    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["BOUNDLESS_TRANSLATOR_LANGUAGE_TESTS"] == "1"
    }

    static func load() throws -> [Self] {
        let url = try #require(Bundle.module.url(forResource: "languages", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode([Self].self, from: Data(contentsOf: url))
    }

    static func translationFixtures() async throws -> [Self] {
        let capabilities = try await LanguageSupportCapabilities.load()
        return try load().filter { capabilities.translationGroups.contains($0.id) }
    }

    static func ocrFixtures() async throws -> [Self] {
        let capabilities = try await LanguageSupportCapabilities.load()
        return try load().filter { capabilities.screenshotGroups.contains($0.id) }
    }

    static func languageGroup(_ identifier: String) -> String {
        let language = Locale.Language(identifier: identifier)
        let code = language.languageCode?.identifier ?? identifier
        if code == "zh" || code == "yue" {
            return "\(code)-\(language.script?.identifier ?? "Hans")"
        }
        return code == "no" ? "nb" : code
    }
}

struct TranslationLanguagePair: Sendable, CustomTestStringConvertible {
    let source: LanguageSupportFixture
    let target: LanguageSupportFixture

    var testDescription: String { "\(source.id) → \(target.id)" }

    static func load() async throws -> [Self] {
        let fixtures = try await LanguageSupportFixture.translationFixtures()
        let english = try #require(fixtures.first { $0.id == "en" })
        return fixtures.filter { $0.id != "en" }.flatMap {
            [Self(source: $0, target: english), Self(source: english, target: $0)]
        }
    }
}

struct LanguageSupportCapabilities: Sendable {
    let translation: [String]
    let ocr: [String]
    let interface: [String]
    let ocrRevision: Int

    var translationGroups: Set<String> { Set(translation.map(LanguageSupportFixture.languageGroup)) }
    var ocrGroups: Set<String> { Set(ocr.map(LanguageSupportFixture.languageGroup)) }
    var screenshotGroups: Set<String> { translationGroups.intersection(ocrGroups) }

    static func load() async throws -> Self {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        let translation = await TranslationEngine.apple.loadLanguages()
        return Self(
            translation: translation.map(\.minimalIdentifier),
            ocr: try request.supportedRecognitionLanguages(),
            interface: InterfaceLanguageCatalog.languageIdentifiers,
            ocrRevision: request.revision
        )
    }
}
