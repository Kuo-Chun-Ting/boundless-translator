import AppKit
import ImageIO
import VisionKit

@MainActor
final class LiveTextImageView: NSView {
    typealias AnalysisProvider = @MainActor (NSImage) async throws -> ImageAnalysis?

    let imageView = NSImageView()
    let overlayView = ImageAnalysisOverlayView()

    var selectedText: String {
        overlayView.selectedText
    }

    var hasActiveTextSelection: Bool {
        overlayView.hasActiveTextSelection
    }

    private let analysisProvider: AnalysisProvider
    private var analysisTask: Task<Void, Never>?
    private var imageGeneration = 0

    convenience override init(frame frameRect: NSRect) {
        let analyzer = ImageAnalyzer()
        self.init(frame: frameRect) { image in
            guard ImageAnalyzer.isSupported else {
                return nil
            }
            return try await analyzer.analyze(
                image,
                orientation: .up,
                configuration: ImageAnalyzer.Configuration([.text])
            )
        }
    }

    convenience init(analysisProvider: @escaping AnalysisProvider) {
        self.init(frame: .zero, analysisProvider: analysisProvider)
    }

    init(
        frame frameRect: NSRect,
        analysisProvider: @escaping AnalysisProvider
    ) {
        self.analysisProvider = analysisProvider
        super.init(frame: frameRect)
        configureSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        analysisTask?.cancel()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateBackgroundColor()
    }

    func display(_ image: NSImage) {
        imageGeneration += 1
        let generation = imageGeneration
        analysisTask?.cancel()
        overlayView.resetSelection()
        overlayView.analysis = nil
        imageView.image = image
        imageView.setAccessibilityIdentifier("imageWorkspace.loading")

        analysisTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            do {
                let analysis = try await analysisProvider(image)
                guard
                    !Task.isCancelled,
                    generation == imageGeneration
                else {
                    return
                }
                overlayView.analysis = analysis
                imageView.setAccessibilityIdentifier(
                    analysis == nil
                        ? "imageWorkspace.unavailable"
                        : "imageWorkspace.liveText"
                )
            } catch {
                guard generation == imageGeneration else {
                    return
                }
                overlayView.analysis = nil
                imageView.setAccessibilityIdentifier("imageWorkspace.unavailable")
            }
        }
    }

    func clearSelection() {
        overlayView.resetSelection()
    }

    private func configureSubviews() {
        wantsLayer = true
        updateBackgroundColor()

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.setAccessibilityIdentifier("imageWorkspace.loading")
        imageView.translatesAutoresizingMaskIntoConstraints = false

        overlayView.trackingImageView = imageView
        overlayView.preferredInteractionTypes = .textSelection
        overlayView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        imageView.addSubview(overlayView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])
    }

    private func updateBackgroundColor() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        }
    }

}
