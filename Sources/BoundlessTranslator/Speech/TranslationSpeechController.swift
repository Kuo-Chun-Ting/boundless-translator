import Combine
import Foundation

enum TranslationSpeechRole: Equatable {
    case source
    case target
}

@MainActor
final class TranslationSpeechController: ObservableObject {
    @Published private(set) var activeRole: TranslationSpeechRole?

    private let player: any SpeechPlaying
    private var playbackID = UUID()

    init(player: any SpeechPlaying) {
        self.player = player
    }

    func togglePlayback(
        role: TranslationSpeechRole,
        text: String,
        languageIdentifier: String
    ) {
        guard canPlay(text: text, languageIdentifier: languageIdentifier) else {
            return
        }
        if activeRole == role {
            stopPlayback()
            return
        }
        if activeRole != nil {
            player.stop()
        }

        let newPlaybackID = UUID()
        playbackID = newPlaybackID
        activeRole = role
        player.play(
            text: text,
            languageIdentifier: languageIdentifier,
            completion: { [weak self] in
                guard self?.playbackID == newPlaybackID else {
                    return
                }
                self?.activeRole = nil
            }
        )
    }

    func canPlay(text: String, languageIdentifier: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && player.supports(languageIdentifier: languageIdentifier)
    }

    func stopPlayback() {
        playbackID = UUID()
        activeRole = nil
        player.stop()
    }
}
