import SwiftUI
@testable import BoundlessTranslator

@MainActor
func makeStubTranslationEngine() -> TranslationEngine {
    TranslationEngine(
        loadLanguages: {
            ["en", "ja", "zh-Hant"].map { Locale.Language(identifier: $0) }
        },
        makeTaskHost: { _, _ in AnyView(EmptyView()) }
    )
}

@MainActor
func makeStubLanguageCatalog() -> SupportedLanguageCatalog {
    SupportedLanguageCatalog(loadLanguages: makeStubTranslationEngine().loadLanguages)
}
