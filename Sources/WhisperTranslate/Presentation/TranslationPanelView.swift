import SwiftUI
@preconcurrency import Translation

struct TranslationPanelView: View {
    @ObservedObject var coordinator: TranslationCoordinator
    @ObservedObject var panelState: TranslationPanelState

    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            sourceText
            Divider()
            content
        }
        .padding(18)
        .frame(minWidth: 420, minHeight: 260, alignment: .topLeading)
        .task {
            guard let request = coordinator.request else {
                return
            }
            configuration = TranslationConfigurationFactory.make(for: request)
        }
        .translationTask(configuration) { session in
            guard let request = await MainActor.run(body: {
                coordinator.request
            }) else {
                return
            }

            do {
                let response = try await session.translate(request.text)
                let output = TranslationOutput(
                    translatedText: response.targetText,
                    sourceLanguageIdentifier: response.sourceLanguage.minimalIdentifier,
                    targetLanguageIdentifier: response.targetLanguage.minimalIdentifier
                )
                coordinator.complete(.success(output), requestID: request.id)
            } catch {
                let failure = TranslationFailure(error: error)
                coordinator.complete(.failure(failure), requestID: request.id)
            }
        }
    }

    private var sourceText: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Original")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(coordinator.request?.text ?? "")
                .lineLimit(4)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "character.book.closed")
                .foregroundStyle(.tint)
            Text("Whisper Translate")
                .font(.headline)
            Spacer()
            Text(targetLanguageName)
                .font(.caption)
                .foregroundStyle(.secondary)
            PinButton(panelState: panelState)
        }
    }

    @ViewBuilder
    private var content: some View {
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
            ScrollView {
                Text(output.translatedText)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer(minLength: 0)
            Text("\(output.sourceLanguageIdentifier) → \(output.targetLanguageIdentifier)")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .failed(let failure):
            VStack(alignment: .leading, spacing: 8) {
                Label("Translation failed", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                Text(failure.message)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                if failure.canRetry {
                    Button("Try Again") {
                        configuration?.invalidate()
                    }
                }
            }
        }
    }

    private var targetLanguageName: String {
        let identifier = coordinator.request?.targetLanguageIdentifier
            ?? TranslationSettings.defaultTargetLanguageIdentifier
        return Locale.current.localizedString(
            forIdentifier: identifier
        ) ?? identifier
    }
}

private struct PinButton: View {
    @ObservedObject var panelState: TranslationPanelState

    @State private var isHovering = false

    var body: some View {
        Button {
            panelState.togglePin()
        } label: {
            Image(systemName: panelState.isPinned ? "pin.fill" : "pin")
                .foregroundStyle(panelState.isPinned ? Color.accentColor : Color.secondary)
                .frame(width: 26, height: 26)
                .background(
                    isHovering ? Color.primary.opacity(0.08) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(panelState.isPinned ? "Unpin Translation" : "Pin Translation")
        .accessibilityLabel(panelState.isPinned ? "Unpin Translation" : "Pin Translation")
    }
}
