import AppKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_show_when_engine_is_injected_then_hosts_its_task_and_uses_its_languages() async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(
        try SelectedText("Hello"), sourceLanguageIdentifier: "en", targetLanguageIdentifier: "ja"
    )
    let request = try #require(coordinator.request)
    let expected = TranslationOutput(
        translatedText: "こんにちは", sourceLanguageIdentifier: "en", targetLanguageIdentifier: "ja"
    )
    var receivedRequest: TranslationRequest?
    let engine = TranslationEngine(
        loadLanguages: { [Locale.Language(identifier: "ja")] },
        makeTaskHost: { request, coordinator in
            receivedRequest = request
            return AnyView(StubTranslationTaskHost(coordinator: coordinator, request: request, output: expected))
        }
    )
    let catalog = SupportedLanguageCatalog(loadLanguages: engine.loadLanguages)
    let controller = TranslationPanelController(
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(), engine: engine
    )
    defer {
        controller.dismissForApplicationActivation(processIdentifier: ProcessInfo.processInfo.processIdentifier + 1)
    }

    // Act
    let languages = await catalog.load()
    controller.show(coordinator: coordinator, supportedLanguages: languages, pointerLocation: .zero)
    let deadline = ContinuousClock.now.advanced(by: .seconds(3))
    while coordinator.status == .translating && ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
    }

    // Assert
    #expect(languages.map(\.minimalIdentifier) == ["ja"])
    #expect(receivedRequest == request)
    #expect(coordinator.status == .translated(expected))
}

private struct StubTranslationTaskHost: View {
    let coordinator: TranslationCoordinator
    let request: TranslationRequest
    let output: TranslationOutput

    var body: some View {
        Color.clear.frame(width: 0, height: 0).task {
            await coordinator.translate(request, using: StubTranslationRunner(output: output))
        }
    }
}

private struct StubTranslationRunner: TranslationRunning {
    let output: TranslationOutput

    func translate(_ request: TranslationRequest) async throws -> TranslationOutput {
        output
    }
}
