import Combine
import Foundation

@MainActor
final class TranslationCoordinator: ObservableObject {
    @Published private(set) var request: TranslationRequest?
    @Published private(set) var status: TranslationStatus = .idle

    func submit(
        _ selectedText: SelectedText,
        sourceLanguageIdentifier: String,
        targetLanguageIdentifier: String,
        sourceLanguageWasDetected: Bool = false
    ) {
        request = TranslationRequest(
            text: selectedText.value,
            sourceLanguageIdentifier: sourceLanguageIdentifier,
            targetLanguageIdentifier: targetLanguageIdentifier,
            sourceLanguageWasDetected: sourceLanguageWasDetected
        )
        status = .translating
    }

    func updateSourceLanguage(_ languageIdentifier: String) {
        guard let request else {
            return
        }

        resubmit(
            request,
            sourceLanguageIdentifier: languageIdentifier,
            targetLanguageIdentifier: request.targetLanguageIdentifier,
            sourceLanguageWasDetected: false
        )
    }

    func updateTargetLanguage(_ languageIdentifier: String) {
        guard let request else {
            return
        }

        resubmit(
            request,
            sourceLanguageIdentifier: request.sourceLanguageIdentifier,
            targetLanguageIdentifier: languageIdentifier,
            sourceLanguageWasDetected: request.sourceLanguageWasDetected
        )
    }

    func retry() {
        guard let request else {
            return
        }

        resubmit(
            request,
            sourceLanguageIdentifier: request.sourceLanguageIdentifier,
            targetLanguageIdentifier: request.targetLanguageIdentifier,
            sourceLanguageWasDetected: request.sourceLanguageWasDetected
        )
    }

    func translate(
        _ request: TranslationRequest,
        using runner: any TranslationRunning
    ) async {
        guard self.request?.id == request.id else {
            return
        }

        do {
            let output = try await runner.translate(request)
            guard self.request?.id == request.id else {
                return
            }
            status = .translated(output)
        } catch {
            guard self.request?.id == request.id else {
                return
            }
            status = .failed(TranslationFailure(error: error))
        }
    }

    private func resubmit(
        _ request: TranslationRequest,
        sourceLanguageIdentifier: String,
        targetLanguageIdentifier: String,
        sourceLanguageWasDetected: Bool
    ) {
        self.request = TranslationRequest(
            text: request.text,
            sourceLanguageIdentifier: sourceLanguageIdentifier,
            targetLanguageIdentifier: targetLanguageIdentifier,
            sourceLanguageWasDetected: sourceLanguageWasDetected
        )
        status = .translating
    }
}
