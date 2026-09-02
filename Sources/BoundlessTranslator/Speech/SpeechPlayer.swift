import Foundation

@MainActor
protocol SpeechPlaying: AnyObject {
    func supports(languageIdentifier: String) -> Bool

    func play(
        text: String,
        languageIdentifier: String,
        completion: @escaping @MainActor () -> Void
    )

    func stop()
}
