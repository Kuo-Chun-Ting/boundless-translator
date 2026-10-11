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
        let languages = await TranslationEngine.apple.loadLanguages()
        let supported = Set(languages.map { languageGroup($0.minimalIdentifier) })
        let fixtures = try load().filter { supported.contains($0.id) }
        print("ENVIRONMENT: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        print("Translation languages: \(supported.sorted())")
        print("Translation languages not exercised: \(supported.subtracting(fixtures.map(\.id)).sorted())")
        return fixtures
    }

    static func ocrFixtures() throws -> [Self] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        let supported = Set(try request.supportedRecognitionLanguages().map(languageGroup))
        let fixtures = try load().filter { supported.contains($0.id) && $0.ocrImage != nil }
        print("OCR languages (Vision revision \(request.revision)): \(supported.sorted())")
        print("OCR languages not exercised: \(supported.subtracting(fixtures.map(\.id)).sorted())")
        return fixtures
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
