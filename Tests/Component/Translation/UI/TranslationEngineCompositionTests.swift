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
    let controller = TranslationWindowController(
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(),
        engine: engine,
        windowPresenter: ForegroundWindowPresenterSpy()
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

@Test @MainActor
func test_show_when_appleReturnsDetectedSource_then_displaysItAndAllowsExplicitRetranslation() async throws {
    // Arrange
    let coordinator = TranslationCoordinator()
    coordinator.submit(try SelectedText("test"), sourceLanguageIdentifier: nil, targetLanguageIdentifier: "zh-Hant")
    let expected = TranslationOutput(
        translatedText: "測試", sourceLanguageIdentifier: "en", targetLanguageIdentifier: "zh-Hant")
    var receivedRequests: [TranslationRequest] = []
    let engine = TranslationEngine(
        loadLanguages: { [] },
        makeTaskHost: { request, coordinator in
            receivedRequests.append(request)
            return AnyView(StubTranslationTaskHost(coordinator: coordinator, request: request, output: expected))
        })
    let presenter = ForegroundWindowPresenterSpy()
    let controller = TranslationWindowController(
        applicationNotificationCenter: NotificationCenter(),
        interfaceLanguageSettings: makeTestInterfaceLanguageSettings(), engine: engine, windowPresenter: presenter)
    defer { controller.dismissForApplicationActivation(processIdentifier: ProcessInfo.processInfo.processIdentifier + 1) }

    // Act
    controller.show(coordinator: coordinator, supportedLanguages: [
        Locale.Language(identifier: "en"), Locale.Language(identifier: "ja"), Locale.Language(identifier: "zh-Hant")
    ], pointerLocation: .zero)
    let deadline = ContinuousClock.now.advanced(by: .seconds(3))
    while coordinator.status != .translated(expected) && ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
    }
    let window = try #require(presenter.presentedWindows.first)
    let content = try #require(window.contentView)
    content.layoutSubtreeIfNeeded()
    let menu = try #require(findViews(NSPopUpButton.self, in: content).first { $0.title == "English (Auto)" })

    // Assert
    #expect(receivedRequests.first?.sourceLanguageIdentifier == nil)
    #expect(coordinator.status == .translated(expected))
    #expect(findViews(NSTextView.self, in: content).contains { $0.string == "test" })

    // Act
    let choices = try #require(menu.menu)
    let japanese = try #require(choices.items.firstIndex { $0.title == "Japanese" })
    choices.performActionForItem(at: japanese)

    // Assert
    #expect(coordinator.request?.sourceLanguageIdentifier == "ja")
    #expect(coordinator.request?.targetLanguageIdentifier == "zh-Hant")
    #expect(coordinator.request?.text == "test")
    #expect(coordinator.request?.sourceLanguageWasDetected == false)
    #expect(presenter.presentedWindows.count == 1)
    #expect(window.contentView === content)
}

@MainActor private func findViews<T: NSView>(_ type: T.Type, in view: NSView) -> [T] {
    view.subviews.flatMap { child in
        (child as? T).map { [$0] } ?? []
    } + view.subviews.flatMap { findViews(type, in: $0) }
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
