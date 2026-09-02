import Foundation
import Testing
@testable import BoundlessTranslator

@Test @MainActor
func test_togglePlayback_when_sourceIsIdle_then_playsSourceText() {
    // Arrange
    let mock_player = SpeechPlayerMock(supportedLanguageIdentifiers: ["en"])
    let controller = TranslationSpeechController(player: mock_player)

    // Act
    controller.togglePlayback(
        role: .source,
        text: "Hello",
        languageIdentifier: "en"
    )

    // Assert
    #expect(controller.activeRole == .source)
    #expect(
        mock_player.playRequests == [
            SpeechPlayerMock.Request(text: "Hello", languageIdentifier: "en")
        ]
    )
}

@Test @MainActor
func test_togglePlayback_when_sameRoleIsActive_then_stopsPlayback() {
    // Arrange
    let mock_player = SpeechPlayerMock(supportedLanguageIdentifiers: ["en"])
    let controller = TranslationSpeechController(player: mock_player)
    controller.togglePlayback(
        role: .source,
        text: "Hello",
        languageIdentifier: "en"
    )

    // Act
    controller.togglePlayback(
        role: .source,
        text: "Hello",
        languageIdentifier: "en"
    )

    // Assert
    #expect(controller.activeRole == nil)
    #expect(mock_player.stopCallCount == 1)
    #expect(mock_player.playRequests.count == 1)
}

@Test @MainActor
func test_togglePlayback_when_otherRoleIsActive_then_stopsBeforePlayingNewText() {
    // Arrange
    let mock_player = SpeechPlayerMock(
        supportedLanguageIdentifiers: ["en", "zh-Hant"]
    )
    let controller = TranslationSpeechController(player: mock_player)
    controller.togglePlayback(
        role: .source,
        text: "Hello",
        languageIdentifier: "en"
    )

    // Act
    controller.togglePlayback(
        role: .target,
        text: "你好",
        languageIdentifier: "zh-Hant"
    )

    // Assert
    #expect(controller.activeRole == .target)
    #expect(
        mock_player.events == [
            .play(text: "Hello", languageIdentifier: "en"),
            .stop,
            .play(text: "你好", languageIdentifier: "zh-Hant")
        ]
    )
}

@Test @MainActor
func test_playbackCompletion_when_currentPlaybackFinishes_then_clearsActiveRole() throws {
    // Arrange
    let mock_player = SpeechPlayerMock(supportedLanguageIdentifiers: ["en"])
    let controller = TranslationSpeechController(player: mock_player)
    controller.togglePlayback(
        role: .source,
        text: "Hello",
        languageIdentifier: "en"
    )

    // Act
    try mock_player.completePlayback(at: 0)

    // Assert
    #expect(controller.activeRole == nil)
}

@Test @MainActor
func test_playbackCompletion_when_previousPlaybackFinishes_then_keepsNewPlaybackActive() throws {
    // Arrange
    let mock_player = SpeechPlayerMock(
        supportedLanguageIdentifiers: ["en", "zh-Hant"]
    )
    let controller = TranslationSpeechController(player: mock_player)
    controller.togglePlayback(
        role: .source,
        text: "Hello",
        languageIdentifier: "en"
    )
    controller.togglePlayback(
        role: .target,
        text: "你好",
        languageIdentifier: "zh-Hant"
    )

    // Act
    try mock_player.completePlayback(at: 0)

    // Assert
    #expect(controller.activeRole == .target)
}

@Test @MainActor
func test_togglePlayback_when_textIsBlank_then_doesNotPlay() {
    // Arrange
    let mock_player = SpeechPlayerMock(supportedLanguageIdentifiers: ["en"])
    let controller = TranslationSpeechController(player: mock_player)

    // Act
    controller.togglePlayback(
        role: .source,
        text: "  \n",
        languageIdentifier: "en"
    )

    // Assert
    #expect(controller.activeRole == nil)
    #expect(mock_player.playRequests.isEmpty)
}

@Test @MainActor
func test_togglePlayback_when_languageIsUnsupported_then_doesNotPlay() {
    // Arrange
    let mock_player = SpeechPlayerMock(supportedLanguageIdentifiers: [])
    let controller = TranslationSpeechController(player: mock_player)

    // Act
    controller.togglePlayback(
        role: .source,
        text: "Hello",
        languageIdentifier: "en"
    )

    // Assert
    #expect(controller.activeRole == nil)
    #expect(mock_player.playRequests.isEmpty)
}

@MainActor
private final class SpeechPlayerMock: SpeechPlaying {
    struct Request: Equatable {
        let text: String
        let languageIdentifier: String
    }

    enum Event: Equatable {
        case play(text: String, languageIdentifier: String)
        case stop
    }

    private let supportedLanguageIdentifiers: Set<String>
    private(set) var playRequests: [Request] = []
    private(set) var stopCallCount = 0
    private(set) var events: [Event] = []
    private var completions: [@MainActor () -> Void] = []

    init(supportedLanguageIdentifiers: Set<String>) {
        self.supportedLanguageIdentifiers = supportedLanguageIdentifiers
    }

    func supports(languageIdentifier: String) -> Bool {
        supportedLanguageIdentifiers.contains(languageIdentifier)
    }

    func play(
        text: String,
        languageIdentifier: String,
        completion: @escaping @MainActor () -> Void
    ) {
        playRequests.append(
            Request(text: text, languageIdentifier: languageIdentifier)
        )
        events.append(
            .play(text: text, languageIdentifier: languageIdentifier)
        )
        completions.append(completion)
    }

    func stop() {
        stopCallCount += 1
        events.append(.stop)
    }

    func completePlayback(at index: Int) throws {
        let completion = try #require(completions[safe: index])
        completion()
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
