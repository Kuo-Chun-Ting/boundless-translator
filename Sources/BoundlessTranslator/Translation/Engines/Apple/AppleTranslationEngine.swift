import SwiftUI
@preconcurrency import Translation

extension TranslationEngine {
    static var apple: TranslationEngine {
        TranslationEngine(
            loadLanguages: {
                await LanguageAvailability().supportedLanguages
            },
            makeTaskHost: { request, coordinator in
                AnyView(AppleTranslationTaskHost(request: request, coordinator: coordinator))
            }
        )
    }
}

private struct AppleTranslationTaskHost: View {
    let request: TranslationRequest
    let coordinator: TranslationCoordinator

    @State private var configuration: TranslationSession.Configuration?

    init(request: TranslationRequest, coordinator: TranslationCoordinator) {
        self.request = request
        self.coordinator = coordinator
        _configuration = State(
            initialValue: AppleTranslationConfigurationFactory.make(for: request)
        )
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .translationTask(configuration) { session in
                await coordinator.translate(request, using: AppleTranslationRunner(session: session))
            }
    }
}
