import Combine
import Foundation

@MainActor
final class TranslationCoordinator: ObservableObject {
    @Published private(set) var request: TranslationRequest?
    @Published private(set) var status: TranslationStatus = .idle
    @Published private(set) var partialOutput: TranslationOutput?
    let userDidCancel = PassthroughSubject<Void, Never>()
    private let splitter: TranslationTextSplitter
    private let authorize: @MainActor () -> Bool
    private var activeTranslation: (id: UUID, cancel: @MainActor () -> Void)?

    var sourceText: String { request?.text ?? "" }

    var sourceLanguageIdentifier: String? {
        partialOutput?.sourceLanguageIdentifier ?? request?.sourceLanguageIdentifier
    }

    var targetLanguageIdentifier: String? { request?.targetLanguageIdentifier }

    init(
        splitter: TranslationTextSplitter = TranslationTextSplitter(),
        authorize: @escaping @MainActor () -> Bool = { true }
    ) {
        self.splitter = splitter
        self.authorize = authorize
    }

    func submit(
        _ selectedText: SelectedText,
        sourceLanguageIdentifier: String?,
        targetLanguageIdentifier: String
    ) {
        guard authorize() else { return }
        cancelActiveTranslation()
        request = TranslationRequest(
            text: selectedText.value,
            sourceLanguageIdentifier: sourceLanguageIdentifier,
            targetLanguageIdentifier: targetLanguageIdentifier
        )
        partialOutput = nil
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
            sourceLanguageIdentifier: sourceLanguageIdentifier,
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
            sourceLanguageIdentifier: sourceLanguageIdentifier,
            targetLanguageIdentifier: request.targetLanguageIdentifier,
            sourceLanguageWasDetected: request.sourceLanguageWasDetected
        )
    }

    func translate(
        _ request: TranslationRequest,
        using runner: any TranslationRunning,
        onCancel: @escaping @MainActor () -> Void = {}
    ) async {
        guard self.request?.id == request.id else {
            return
        }

        guard authorize() else {
            status = .idle
            return
        }

        activeTranslation = (request.id, onCancel)
        defer {
            if activeTranslation?.id == request.id {
                activeTranslation = nil
            }
        }

        do {
            let output = try await translateChunks(request, using: runner)
            try ensureCurrent(request)
            status = .translated(output)
        } catch CocoaError.userCancelled {
            guard self.request?.id == request.id else { return }
            status = .idle
            userDidCancel.send()
        } catch is CancellationError {
            guard self.request?.id == request.id else { return }
            status = .idle
        } catch {
            guard self.request?.id == request.id else {
                return
            }
            status = .failed(TranslationFailure(error: error))
        }
    }

    func cancel() {
        request = nil
        partialOutput = nil
        status = .idle
        cancelActiveTranslation()
    }

    private func translateChunks(
        _ request: TranslationRequest,
        using runner: any TranslationRunning
    ) async throws -> TranslationOutput {
        let splitting = Task.detached { [splitter] in
            try splitter.split(request.text, languageIdentifier: request.sourceLanguageIdentifier)
        }
        let chunks = try await withTaskCancellationHandler {
            try await splitting.value
        } onCancel: {
            splitting.cancel()
        }
        var translatedText = ""
        var separator = ""
        var output: TranslationOutput?
        for chunk in chunks {
            try ensureCurrent(request)
            let response = try await runner.translate(request.replacingText(with: chunk))
            try ensureCurrent(request)
            let translatedChunk = chunks.count > 1
                ? response.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                : response.translatedText
            translatedText += separator + translatedChunk
            separator = String(chunk.reversed().prefix(while: { $0.isWhitespace }).reversed())
            output = TranslationOutput(
                translatedText: translatedText,
                sourceLanguageIdentifier: response.sourceLanguageIdentifier,
                targetLanguageIdentifier: response.targetLanguageIdentifier
            )
            partialOutput = output
        }
        guard let output else { throw TranslationFailure.nothingToTranslate }
        return output
    }

    private func ensureCurrent(_ request: TranslationRequest) throws {
        try Task.checkCancellation()
        guard self.request?.id == request.id else { throw CancellationError() }
    }

    private func cancelActiveTranslation() {
        let cancel = activeTranslation?.cancel
        activeTranslation = nil
        cancel?()
    }

    private func resubmit(
        _ request: TranslationRequest,
        sourceLanguageIdentifier: String?,
        targetLanguageIdentifier: String,
        sourceLanguageWasDetected: Bool
    ) {
        guard authorize() else { return }
        cancelActiveTranslation()
        self.request = TranslationRequest(
            text: request.text,
            sourceLanguageIdentifier: sourceLanguageIdentifier,
            targetLanguageIdentifier: targetLanguageIdentifier,
            sourceLanguageWasDetected: sourceLanguageWasDetected
        )
        partialOutput = nil
        status = .translating
    }
}
