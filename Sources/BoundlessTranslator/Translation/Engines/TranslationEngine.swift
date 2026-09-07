import SwiftUI

@MainActor
struct TranslationEngine {
    let loadLanguages: @MainActor () async -> [Locale.Language]
    let makeTaskHost: @MainActor (TranslationRequest, TranslationCoordinator) -> AnyView
}
