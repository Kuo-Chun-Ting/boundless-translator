import AppKit
import Combine
import SwiftUI

@MainActor
final class ScreenshotTranslationController {
    typealias DefinitionPresenter = @MainActor (NSView, String, CGPoint) -> Void

    let panel = ScreenshotTranslationPanel()
    let card = ScreenshotTranslationCard()
    let speech: TranslationSpeechController
    private let coordinator: TranslationCoordinator
    private let settings: TranslationSettings
    private let interfaceLanguageSettings: InterfaceLanguageSettings
    private let showNativeDefinition: DefinitionPresenter
    private weak var imageView: ImageTextView?
    private let taskHost: NSHostingView<ScreenshotTranslationTaskView>
    private var observations: Set<AnyCancellable> = []
    private var target: ImageTextPreviewTarget?

    var highlightedSourceBounds: CGRect? { panel.isVisible ? target?.bounds : nil }
    private var hoverTarget: ImageTextPreviewTarget?
    private var hoverTask: Task<Void, Never>?
    private var dismissalTask: Task<Void, Never>?
    private var preservesLookupCard = false
    private var cancelledTarget: ImageTextPreviewTarget?

    init(imageView: ImageTextView, settings: TranslationSettings,
         interfaceLanguageSettings: InterfaceLanguageSettings, engine: TranslationEngine,
         coordinator: TranslationCoordinator = TranslationCoordinator(),
         speechPlayer: any SpeechPlaying = AppleSpeechPlayer(),
         showDefinition: @escaping DefinitionPresenter = { view, text, point in
             view.showDefinition(for: NSAttributedString(string: text), at: point)
         }) {
        self.imageView = imageView
        self.settings = settings
        self.interfaceLanguageSettings = interfaceLanguageSettings
        self.coordinator = coordinator
        showNativeDefinition = showDefinition
        speech = TranslationSpeechController(player: speechPlayer)
        taskHost = NSHostingView(rootView: ScreenshotTranslationTaskView(coordinator: coordinator, engine: engine))
        imageView.addSubview(taskHost)
        panel.install(card)
        card.onSpeech = { [weak self] in self?.toggleSpeech() }
        card.onLookup = { [weak self] in self?.showDefinition() }
        card.onPointerEntered = { [weak self] in
            self?.preservesLookupCard = false
            self?.hoverTask?.cancel()
            self?.hoverTarget = nil
            self?.dismissalTask?.cancel()
        }
        card.onPointerExited = { [weak self] in self?.scheduleDismissal() }
        coordinator.$status.combineLatest(coordinator.$partialOutput).sink { [weak self] status, output in
            self?.render(status: status, output: output)
        }.store(in: &observations)
        coordinator.userDidCancel.sink { [weak self] in
            guard let self else { return }
            let cancelled = target
            dismiss()
            cancelledTarget = cancelled
        }.store(in: &observations)
        speech.$activeRole.sink { [weak self] role in
            self?.updateSpeech(playing: role != nil)
        }.store(in: &observations)
    }

    deinit {
        hoverTask?.cancel()
        dismissalTask?.cancel()
    }

    func hover(_ candidate: ImageTextPreviewTarget?) {
        guard imageView?.window?.attachedSheet == nil else { return }
        preservesLookupCard = false
        guard let candidate else {
            cancelledTarget = nil
            scheduleDismissal()
            return
        }
        dismissalTask?.cancel()
        guard candidate != hoverTarget else { return }
        hoverTask?.cancel()
        hoverTarget = candidate
        hoverTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
            self?.update(candidate)
        }
    }

    func update(_ candidate: ImageTextPreviewTarget?) {
        guard imageView?.window?.attachedSheet == nil else { return }
        if let candidate, let cancelledTarget,
           candidate.text == cancelledTarget.text, candidate.range == cancelledTarget.range { return }
        preservesLookupCard = false
        hoverTask?.cancel()
        dismissalTask?.cancel()
        guard let candidate, let selectedText = try? SelectedText(candidate.text) else {
            dismiss()
            return
        }
        guard target != candidate else { positionCard(); return }
        speech.stopPlayback()
        coordinator.cancel()
        target = candidate
        coordinator.submit(selectedText, sourceLanguageIdentifier: settings.sourceLanguageIdentifier,
                           targetLanguageIdentifier: settings.targetLanguageIdentifier)
        guard coordinator.request != nil, let window = imageView?.window else {
            dismiss()
            return
        }
        panel.appearance = window.appearance
        window.addChildWindow(panel, ordered: .above)
        positionCard()
        panel.orderFront(nil)
        imageView?.needsDisplay = true
    }

    func dismiss() {
        hoverTask?.cancel()
        dismissalTask?.cancel()
        hoverTarget = nil
        target = nil
        preservesLookupCard = false
        cancelledTarget = nil
        speech.stopPlayback()
        coordinator.cancel()
        panel.parent?.removeChildWindow(panel)
        panel.orderOut(nil)
        imageView?.needsDisplay = true
    }

    func scheduleDismissal() {
        guard !isPresentingSystemUI else { return }
        hoverTask?.cancel()
        hoverTarget = nil
        dismissalTask?.cancel()
        dismissalTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
            guard let self, !isPresentingSystemUI,
                  !panel.frame.contains(NSEvent.mouseLocation),
                  imageView?.hasActiveTextSelection != true else { return }
            dismiss()
        }
    }

    func showDefinition() {
        guard let target, let imageView else { return }
        dismissalTask?.cancel()
        hoverTask?.cancel()
        // AppKit owns Lookup. Keep its card until pointer events return to our content.
        preservesLookupCard = true
        let rect = imageView.viewRect(for: target.bounds)
        showNativeDefinition(imageView, target.text, CGPoint(x: rect.midX, y: rect.minY))
    }

    func toggleSpeech() {
        speech.togglePlayback(role: .source, text: coordinator.sourceText,
                              languageIdentifier: coordinator.sourceLanguageIdentifier ?? "")
    }

    func retry() { coordinator.retry() }

    func positionCard() {
        guard let target, let imageView, let window = imageView.window,
              let screen = window.screen ?? NSScreen.main else { return }
        let anchor = window.convertToScreen(imageView.convert(imageView.viewRect(for: target.bounds), to: nil))
        let contentSize = card.preferredSize(maximumHeight: min(390, screen.visibleFrame.height - 10))
        let frame = ImageTextPreviewPositioner.frame(anchor: anchor,
            size: CGSize(width: contentSize.width, height: contentSize.height + 10),
            visibleFrame: screen.visibleFrame)
        panel.setFrame(frame, display: true)
        panel.point(to: anchor)
    }

    private var isPresentingSystemUI: Bool {
        preservesLookupCard || imageView?.window?.attachedSheet != nil
    }

    private var localization: AppLocalization {
        AppLocalization(languageIdentifier: interfaceLanguageSettings.resolvedLanguageIdentifier)
    }

    private func render(status: TranslationStatus, output: TranslationOutput?) {
        card.render(status: status, output: output, localization: localization,
                    onRetry: { [weak self] in self?.retry() })
        let language = output?.sourceLanguageIdentifier ?? coordinator.request?.sourceLanguageIdentifier ?? ""
        card.updateSpeech(available: speech.canPlay(text: coordinator.sourceText, languageIdentifier: language),
                          playing: speech.activeRole != nil, localization: localization)
        positionCard()
    }

    private func updateSpeech(playing: Bool) {
        card.updateSpeech(available: speech.canPlay(text: coordinator.sourceText,
            languageIdentifier: coordinator.sourceLanguageIdentifier ?? ""),
            playing: playing, localization: localization)
    }
}

private struct ScreenshotTranslationTaskView: View {
    @ObservedObject var coordinator: TranslationCoordinator
    let engine: TranslationEngine

    var body: some View {
        if let request = coordinator.request {
            engine.makeTaskHost(request, coordinator).id(request.id)
        }
    }
}

@MainActor
final class ScreenshotTranslationPanel: NSPanel {

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = true
        acceptsMouseMovedEvents = true
        setAccessibilityIdentifier("screenshotPreview")
    }

    private weak var card: ScreenshotTranslationCard?
    private var glassHost: NSHostingView<ScreenshotTranslationGlass>?

    func install(_ content: ScreenshotTranslationCard) {
        card = content
        let host = NSHostingView(rootView: ScreenshotTranslationGlass(card: content))
        host.sizingOptions = []
        glassHost = host
        contentView = host
    }

    func point(to anchor: CGRect) {
        guard let card else { return }
        glassHost?.rootView = ScreenshotTranslationGlass(card: card,
            pointerX: anchor.midX - frame.minX, pointsUp: frame.midY < anchor.midY)
    }

    override func sendEvent(_ event: NSEvent) {
        super.sendEvent(event)
        if event.type == .mouseMoved || event.type == .cursorUpdate {
            let point = card?.superview?.convert(event.locationInWindow, from: nil) ?? .zero
            let view = card?.hitTest(point)
            switch view {
            case is NSButton: NSCursor.pointingHand.set()
            case is NSTextView: NSCursor.iBeam.set()
            default: NSCursor.arrow.set()
            }
        }
    }
}


private struct ScreenshotTranslationGlass: View {
    let card: ScreenshotTranslationCard
    var pointerX: CGFloat = 74
    var pointsUp = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let shape = ScreenshotTranslationBubble(pointerX: pointerX, pointsUp: pointsUp)
        let content = ScreenshotCardContent(card: card)
            .padding(pointsUp ? .top : .bottom, 10)
        if #available(macOS 26, *) {
            content.glassEffect(.regular.tint(.white.opacity(colorScheme == .dark ? 0.025 : 0.08)), in: shape)
        } else {
            content.background(.regularMaterial, in: shape)
        }
    }
}

private struct ScreenshotCardContent: NSViewRepresentable {
    let card: ScreenshotTranslationCard
    func makeNSView(context: Context) -> ScreenshotTranslationCard { card }
    func updateNSView(_ view: ScreenshotTranslationCard, context: Context) {}
}

struct ScreenshotTranslationBubble: Shape {
    var pointerX: CGFloat
    var pointsUp: Bool

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 10 else { return Path() }
        let radius = min(22, (rect.height - 10) / 2)
        let bottom = rect.maxY - 10
        let x = min(max(pointerX, radius + 12), rect.width - radius - 12) + rect.minX
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: bottom - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: bottom),
                          control: CGPoint(x: rect.maxX, y: bottom))
        path.addLine(to: CGPoint(x: x + 12, y: bottom))
        path.addQuadCurve(to: CGPoint(x: x + 8, y: bottom + 2), control: CGPoint(x: x + 10, y: bottom))
        path.addLine(to: CGPoint(x: x + 2, y: rect.maxY - 1))
        path.addQuadCurve(to: CGPoint(x: x - 2, y: rect.maxY - 1), control: CGPoint(x: x, y: rect.maxY + 1))
        path.addLine(to: CGPoint(x: x - 8, y: bottom + 2))
        path.addQuadCurve(to: CGPoint(x: x - 12, y: bottom), control: CGPoint(x: x - 10, y: bottom))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: bottom))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: bottom - radius),
                          control: CGPoint(x: rect.minX, y: bottom))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return pointsUp ? path.applying(CGAffineTransform(a: 1, b: 0, c: 0, d: -1,
                                                        tx: 0, ty: rect.minY + rect.maxY)) : path
    }
}
