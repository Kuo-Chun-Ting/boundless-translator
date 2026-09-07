@preconcurrency import AVFoundation

@MainActor
final class AppleSpeechPlayer: NSObject, SpeechPlaying, @preconcurrency AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var completions: [ObjectIdentifier: @MainActor () -> Void] = [:]

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func supports(languageIdentifier: String) -> Bool {
        voice(for: languageIdentifier) != nil
    }

    func play(
        text: String,
        languageIdentifier: String,
        completion: @escaping @MainActor () -> Void
    ) {
        guard let voice = voice(for: languageIdentifier) else {
            completion()
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        completions[ObjectIdentifier(utterance)] = completion
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        finish(utterance)
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        finish(utterance)
    }

    private func voice(for languageIdentifier: String) -> AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice(language: languageIdentifier)
    }

    private func finish(_ utterance: AVSpeechUtterance) {
        completions.removeValue(forKey: ObjectIdentifier(utterance))?()
    }
}
