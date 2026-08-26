import SwiftUI
@preconcurrency import Translation

struct TranslationPanelView: View {
    @ObservedObject var coordinator: TranslationCoordinator
    @ObservedObject var panelState: TranslationPanelState

    let supportedLanguages: [Locale.Language]
    let layout: TranslationPanelLayout
    let onPreferredSizeChange: @MainActor (CGSize) -> Void

    init(
        coordinator: TranslationCoordinator,
        panelState: TranslationPanelState,
        supportedLanguages: [Locale.Language],
        layout: TranslationPanelLayout = TranslationPanelLayout(),
        onPreferredSizeChange: @escaping @MainActor (CGSize) -> Void = { _ in }
    ) {
        self.coordinator = coordinator
        self.panelState = panelState
        self.supportedLanguages = supportedLanguages
        self.layout = layout
        self.onPreferredSizeChange = onPreferredSizeChange
    }

    var body: some View {
        VStack(spacing: 0) {
            TranslationPanelToolbar(
                panelState: panelState
            )
            Divider()
            TranslationLanguageBar(
                coordinator: coordinator,
                supportedLanguages: supportedLanguages
            )
            Divider()
            HStack(spacing: 0) {
                sourceContent
                Divider()
                targetContent
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }
        .frame(
            minWidth: metrics.size.width,
            maxWidth: .infinity,
            minHeight: metrics.size.height,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(Color(nsColor: .windowBackgroundColor))
        .ignoresSafeArea(.container, edges: .top)
        .onChange(of: metrics.size, initial: true) { _, newSize in
            onPreferredSizeChange(newSize)
        }
        .background {
            if let request = coordinator.request {
                TranslationTaskHost(
                    request: request,
                    onComplete: { result, requestID in
                        coordinator.complete(result, requestID: requestID)
                    }
                )
                .id(request.id)
            }
        }
    }

    private var sourceContent: some View {
        ScrollView {
            Text(coordinator.request?.text ?? "")
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .columnFrame(height: metrics.contentHeight)
    }

    @ViewBuilder
    private var targetContent: some View {
        switch coordinator.status {
        case .idle:
            Text("Select text and press Command-Shift-T to translate it.")
                .foregroundStyle(.secondary)
                .columnFrame(height: metrics.contentHeight)
        case .translating:
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("Translating…")
                    .foregroundStyle(.secondary)
            }
            .columnFrame(height: metrics.contentHeight)
        case .translated(let output):
            ScrollView {
                Text(output.translatedText)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .columnFrame(height: metrics.contentHeight)
        case .failed(let failure):
            VStack(alignment: .leading, spacing: 8) {
                Label("Translation failed", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                Text(failure.message)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                if failure.canRetry {
                    Button("Try Again") {
                        coordinator.retry()
                    }
                }
            }
            .columnFrame(height: metrics.contentHeight)
        }
    }

    private var metrics: TranslationPanelMetrics {
        layout.metrics(
            sourceText: coordinator.request?.text ?? "",
            status: coordinator.status
        )
    }
}

private struct TranslationTaskHost: View {
    let request: TranslationRequest
    let onComplete: @MainActor (
        Result<TranslationOutput, TranslationFailure>,
        UUID
    ) -> Void

    @State private var configuration: TranslationSession.Configuration?

    init(
        request: TranslationRequest,
        onComplete: @escaping @MainActor (
            Result<TranslationOutput, TranslationFailure>,
            UUID
        ) -> Void
    ) {
        self.request = request
        self.onComplete = onComplete
        _configuration = State(
            initialValue: TranslationConfigurationFactory.make(for: request)
        )
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .translationTask(configuration) { session in
                do {
                    let response = try await session.translate(request.text)
                    let output = TranslationOutput(
                        translatedText: response.targetText,
                        sourceLanguageIdentifier: response.sourceLanguage.minimalIdentifier,
                        targetLanguageIdentifier: response.targetLanguage.minimalIdentifier
                    )
                    onComplete(.success(output), request.id)
                } catch {
                    onComplete(
                        .failure(TranslationFailure(error: error)),
                        request.id
                    )
                }
            }
    }
}

private extension View {
    func columnFrame(height: CGFloat) -> some View {
        frame(
            maxWidth: .infinity,
            minHeight: height,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(14)
    }
}
