import SwiftUI
@preconcurrency import Translation

struct TranslationPanelView: View {
    @ObservedObject var coordinator: TranslationCoordinator

    let supportedLanguages: [Locale.Language]
    let layout: TranslationPanelLayout
    let onPreferredSizeChange: @MainActor (CGSize) -> Void

    init(
        coordinator: TranslationCoordinator,
        supportedLanguages: [Locale.Language],
        layout: TranslationPanelLayout = TranslationPanelLayout(),
        onPreferredSizeChange: @escaping @MainActor (CGSize) -> Void = { _ in }
    ) {
        self.coordinator = coordinator
        self.supportedLanguages = supportedLanguages
        self.layout = layout
        self.onPreferredSizeChange = onPreferredSizeChange
    }

    var body: some View {
        translationContent
        .frame(
            minWidth: metrics.size.width,
            maxWidth: .infinity,
            minHeight: metrics.size.height,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: metrics.size, initial: true) { _, newSize in
            onPreferredSizeChange(newSize)
        }
        .background {
            if let request = coordinator.request {
                TranslationTaskHost(
                    request: request,
                    coordinator: coordinator
                )
                .id(request.id)
            }
        }
    }

    private var translationContent: some View {
        VStack(spacing: TranslationPanelStyle.contentSpacing) {
            HStack(spacing: TranslationPanelStyle.columnSpacing) {
                languageMenu(role: .source)
                languageMenu(role: .target)
            }

            HStack(
                alignment: .top,
                spacing: TranslationPanelStyle.columnSpacing
            ) {
                sourceContent
                targetContent
            }
        }
        .padding(.horizontal, TranslationPanelStyle.horizontalPadding)
        .padding(.bottom, TranslationPanelStyle.bottomPadding)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }

    private func languageMenu(
        role: TranslationLanguageRole
    ) -> some View {
        TranslationLanguageMenu(
            coordinator: coordinator,
            supportedLanguages: supportedLanguages,
            role: role
        )
        .frame(width: TranslationPanelStyle.languageMenuWidth)
        .frame(
            maxWidth: .infinity,
            minHeight: TranslationPanelStyle.languageRowHeight,
            alignment: .leading
        )
    }

    private var sourceContent: some View {
        SelectableSourceTextView(text: coordinator.request?.text ?? "")
            .frame(
                maxWidth: .infinity,
                minHeight: cardSurfaceHeight,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .translationCardSurface()
    }

    private var targetContent: some View {
        targetBody
            .columnFrame(height: metrics.contentHeight)
            .translationCardSurface()
    }

    @ViewBuilder
    private var targetBody: some View {
        switch coordinator.status {
        case .idle:
            Text("Select text and press Command-Shift-T to translate it.")
                .foregroundStyle(.secondary)
        case .translating:
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("Translating…")
                    .foregroundStyle(.secondary)
            }
        case .translated(let output):
            SelectableTranslationTextView(text: output.translatedText)
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
        }
    }

    private var cardSurfaceHeight: CGFloat {
        metrics.contentHeight
            + TranslationPanelStyle.cardContentPadding * 2
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
    let coordinator: TranslationCoordinator

    @State private var configuration: TranslationSession.Configuration?

    init(
        request: TranslationRequest,
        coordinator: TranslationCoordinator
    ) {
        self.request = request
        self.coordinator = coordinator
        _configuration = State(
            initialValue: TranslationConfigurationFactory.make(for: request)
        )
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .translationTask(configuration) { session in
                await coordinator.translate(
                    request,
                    using: AppleTranslationRunner(session: session)
                )
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
        .padding(TranslationPanelStyle.cardContentPadding)
    }

    func translationCardSurface() -> some View {
        background(TranslationCardSurface())
    }
}

private struct TranslationCardSurface: View {
    var body: some View {
        RoundedRectangle(
            cornerRadius: TranslationPanelStyle.cardCornerRadius,
            style: .continuous
        )
        .fill(Color(nsColor: TranslationPanelStyle.cardBackgroundColor))
    }
}
