import SwiftUI

struct TranslationWindowView: View {
    @ObservedObject var coordinator: TranslationCoordinator
    @ObservedObject var speechController: TranslationSpeechController
    @ObservedObject var interfaceLanguageSettings: InterfaceLanguageSettings

    let supportedLanguages: [Locale.Language]
    let engine: TranslationEngine
    let layout: TranslationWindowLayout
    let onPreferredSizeChange: @MainActor (CGSize) -> Void

    init(
        coordinator: TranslationCoordinator,
        speechController: TranslationSpeechController,
        interfaceLanguageSettings: InterfaceLanguageSettings,
        supportedLanguages: [Locale.Language],
        engine: TranslationEngine,
        layout: TranslationWindowLayout = TranslationWindowLayout(),
        onPreferredSizeChange: @escaping @MainActor (CGSize) -> Void = { _ in }
    ) {
        self.coordinator = coordinator
        self.speechController = speechController
        self.interfaceLanguageSettings = interfaceLanguageSettings
        self.supportedLanguages = supportedLanguages
        self.engine = engine
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
        .onChange(of: coordinator.request?.id) {
            speechController.stopPlayback()
        }
        .onChange(of: metrics.size, initial: true) { _, newSize in
            onPreferredSizeChange(newSize)
        }
        .background {
            if let request = coordinator.request {
                engine.makeTaskHost(request, coordinator)
                .id(request.id)
            }
        }
        .interfaceLanguage(interfaceLanguageSettings)
    }

    private var translationContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                languageControls(role: .source)
                languageControls(role: .target)
            }
            .padding(.vertical, TranslationWindowStyle.controlsVerticalPadding)
            .appControlSurface()

            HStack(alignment: .top, spacing: 0) {
                sourceContent
                targetContent
            }
            .background(Color(nsColor: .textBackgroundColor))
            .overlay {
                HStack(spacing: 0) { Divider() }
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                Divider().allowsHitTesting(false)
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }

    private func languageControls(
        role: TranslationLanguageRole
    ) -> some View {
        HStack(spacing: TranslationWindowStyle.speechControlSpacing) {
            TranslationLanguageMenu(
                coordinator: coordinator,
                supportedLanguages: supportedLanguages,
                role: role,
                localization: localization
            )
            .frame(maxWidth: .infinity)

            let speechContent = speechContent(for: role)
            TranslationSpeechButton(
                controller: speechController,
                role: role == .source ? .source : .target,
                text: speechContent.text,
                languageIdentifier: speechContent.languageIdentifier,
                localization: localization
            )
            .frame(width: TranslationWindowStyle.speechButtonSize, height: TranslationWindowStyle.speechButtonSize)
            .frame(
                width: TranslationWindowStyle.speechControlSize,
                height: TranslationWindowStyle.languageRowHeight
            )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: TranslationWindowStyle.languageRowHeight,
            alignment: .leading
        )
        .padding(.horizontal, TranslationWindowStyle.contentPadding)
    }

    private func speechContent(
        for role: TranslationLanguageRole
    ) -> (text: String, languageIdentifier: String) {
        switch role {
        case .source:
            guard let request = coordinator.request else {
                return ("", "")
            }
            let languageIdentifier: String
            if case .translated(let output) = coordinator.status {
                languageIdentifier = output.sourceLanguageIdentifier
            } else {
                languageIdentifier = request.sourceLanguageIdentifier
            }
            return (request.text, languageIdentifier)
        case .target:
            guard case .translated(let output) = coordinator.status else {
                return ("", "")
            }
            return (output.translatedText, output.targetLanguageIdentifier)
        }
    }

    private var sourceContent: some View {
        SelectableSourceTextView(
            text: coordinator.request?.text ?? "",
            localization: localization
        )
            .frame(
                maxWidth: .infinity,
                minHeight: metrics.contentHeight
                    + TranslationWindowStyle.contentPadding * 2,
                maxHeight: .infinity,
                alignment: .topLeading
            )
    }

    private var targetContent: some View {
        targetBody
            .columnFrame(height: metrics.contentHeight)
    }

    @ViewBuilder
    private var targetBody: some View {
        switch coordinator.status {
        case .idle:
            Text(verbatim: localization.string("panel.idle"))
                .foregroundStyle(.secondary)
        case .translating:
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text(verbatim: localization.string("panel.translating"))
                    .foregroundStyle(.secondary)
            }
        case .translated(let output):
            SelectableTranslationTextView(text: output.translatedText)
        case .failed(let failure):
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    localization.string("panel.failureTitle"),
                    systemImage: "exclamationmark.triangle"
                )
                    .foregroundStyle(.red)
                Text(verbatim: failure.message(localization: localization))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                if failure.canRetry {
                    Button(localization.string("panel.tryAgain")) {
                        coordinator.retry()
                    }
                    .appControlStyle()
                }
            }
        }
    }

    private var metrics: TranslationWindowMetrics {
        layout.metrics(
            sourceText: coordinator.request?.text ?? "",
            status: coordinator.status,
            localization: localization
        )
    }

    private var localization: AppLocalization {
        AppLocalization(
            languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier
        )
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
        .padding(TranslationWindowStyle.contentPadding)
    }
}
