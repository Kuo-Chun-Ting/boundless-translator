import AppKit

@MainActor
final class ImageTextView: NSView {
    typealias AnalysisProvider = @MainActor (NSImage) async throws -> ImageTextDocument?

    private(set) var image: NSImage?
    private(set) var document = ImageTextDocument(text: "", words: [])
    private(set) var selection: NSRange?
    var onAnalysisCompletion: ((ImageTextDocument?) -> Void)?
    var quickTranslation: ScreenshotTranslationController?
    private let analysisProvider: AnalysisProvider
    private var analysisTask: Task<Void, Never>?
    private var pointerDown: CGPoint?
    private var previousDragPoint = CGPoint.zero
    private var hasReachedText = false
    private var isDragging = false
    private var trackingArea: NSTrackingArea?

    var selectedText: String { document.text(in: selection) }
    var hasActiveTextSelection: Bool { selection?.length ?? 0 > 0 }
    var isSelectionEmphasized: Bool { NSApp.isActive && window?.isKeyWindow == true }
    override var acceptsFirstResponder: Bool { true }

    var imageRect: CGRect {
        guard let size = image?.size, size.width > 0, size.height > 0 else { return .zero }
        let scale = min(bounds.width / size.width, bounds.height / size.height)
        let fittedSize = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(
            x: bounds.midX - fittedSize.width / 2, y: bounds.midY - fittedSize.height / 2,
            width: fittedSize.width, height: fittedSize.height)
    }

    convenience override init(frame frameRect: NSRect) {
        self.init(frame: frameRect) { image in
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return nil
            }
            let size = image.size
            return try await Task.detached(priority: .userInitiated) {
                try ImageTextRecognizer.recognize(cgImage, size: size)
            }.value
        }
    }

    convenience init(analysisProvider: @escaping AnalysisProvider) {
        self.init(frame: .zero, analysisProvider: analysisProvider)
    }

    init(frame: NSRect, analysisProvider: @escaping AnalysisProvider) {
        self.analysisProvider = analysisProvider
        super.init(frame: frame)
        wantsLayer = true
        updateBackgroundColor()
        setAccessibilityElement(true)
        setAccessibilityRole(.image)
        setAccessibilityIdentifier("imageWorkspace.loading")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        analysisTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    func display(_ image: NSImage) {
        analysisTask?.cancel()
        self.image = image
        document = ImageTextDocument(text: "", words: [])
        clearSelection()
        setAccessibilityValue("")
        setAccessibilityIdentifier("imageWorkspace.loading")
        let provider = analysisProvider
        analysisTask = Task { @MainActor [weak self] in
            let result = try? await provider(image)
            guard let self, !Task.isCancelled else { return }
            document = result ?? ImageTextDocument(text: "", words: [])
            setAccessibilityValue(document.text)
            setAccessibilityIdentifier(
                result == nil ? "imageWorkspace.unavailable" : "imageWorkspace.text")
            refreshSelectionDisplay()
            onAnalysisCompletion?(result)
        }
    }

    func clearSelection() {
        quickTranslation?.dismiss()
        selection = nil
        endGesture()
        refreshSelectionDisplay()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        let center = NotificationCenter.default
        center.removeObserver(self)
        guard let window else { return }
        window.acceptsMouseMovedEvents = true
        for name in [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification] {
            center.addObserver(self, selector: #selector(focusChanged), name: name, object: window)
        }
        for name in [
            NSApplication.didBecomeActiveNotification, NSApplication.didResignActiveNotification,
        ] {
            center.addObserver(self, selector: #selector(focusChanged), name: name, object: nil)
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateBackgroundColor()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()
        image?.draw(in: imageRect)
        guard let selection, selection.length > 0 else {
            if let sourceBounds = quickTranslation?.highlightedSourceBounds {
                NSColor.gray.withAlphaComponent(0.22).setFill()
                let rect = viewRect(for: sourceBounds).insetBy(dx: -2, dy: -2)
                NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3).fill()
            }
            return
        }
        let color =
            isSelectionEmphasized
            ? NSColor.selectedContentBackgroundColor : NSColor.unemphasizedSelectedContentBackgroundColor
        color.withAlphaComponent(isSelectionEmphasized ? 0.30 : 0.38).setFill()
        let selected = document.selectionRegions.filter {
            NSIntersectionRange($0.range, selection).length > 0
        }
        for row in Dictionary(grouping: selected, by: \.line).values {
            let rect = row.dropFirst().reduce(row[0].bounds) { $0.union($1.bounds) }
            viewRect(for: rect).insetBy(dx: -1, dy: -2).fill()
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(
            rect: .zero, options: [.inVisibleRect, .activeInKeyWindow, .mouseMoved, .cursorUpdate, .mouseEnteredAndExited],
            owner: self
        )
        trackingArea = area
        addTrackingArea(area)
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .arrow)
        for region in document.selectionRegions {
            addCursorRect(viewRect(for: region.bounds), cursor: .iBeam)
        }
    }

    override func cursorUpdate(with event: NSEvent) { updateCursor(at: imagePoint(for: event)) }
    override func mouseMoved(with event: NSEvent) {
        let point = imagePoint(for: event)
        updateCursor(at: point)
        guard isSelectionEmphasized, pointerDown == nil else { return }
        let target = ImageTextPreviewTarget.make(document: document, selection: selection, point: point)
        if hasActiveTextSelection { quickTranslation?.update(target) }
        else { quickTranslation?.hover(target) }
    }

    override func mouseExited(with event: NSEvent) { quickTranslation?.scheduleDismissal() }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        quickTranslation?.positionCard()
    }

    override func mouseDown(with event: NSEvent) {
        quickTranslation?.dismiss()
        window?.makeFirstResponder(self)
        let point = imagePoint(for: event)
        pointerDown = point
        previousDragPoint = point
        hasReachedText = document.intersectsText(from: point, to: point)
        isDragging = false
        selection = event.clickCount == 2 ? document.word(at: point)?.range : nil
        needsDisplay = true
        updateCursor(at: point)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let pointerDown else { return }
        let point = imagePoint(for: event)
        guard isDragging || hypot(point.x - pointerDown.x, point.y - pointerDown.y) >= 3 else { return }
        isDragging = true
        hasReachedText = hasReachedText || document.intersectsText(from: previousDragPoint, to: point)
        previousDragPoint = point
        selection = hasReachedText ? document.range(from: pointerDown, to: point) : nil
        needsDisplay = true
        updateCursor(at: point)
    }

    override func mouseUp(with event: NSEvent) {
        endGesture()
        updateCursor(at: imagePoint(for: event))
        if hasActiveTextSelection {
            quickTranslation?.update(ImageTextPreviewTarget.make(
                document: document, selection: selection, point: imagePoint(for: event)))
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard window?.firstResponder === self,
            event.modifierFlags.intersection([.command, .shift, .option, .control]) == .command
        else {
            return super.performKeyEquivalent(with: event)
        }
        // Command-modified characters preserve shortcuts with input methods such as Zhuyin.
        switch event.characters?.lowercased() {
        case "c": copy(nil)
        case "a": selectAll(nil)
        default: return super.performKeyEquivalent(with: event)
        }
        return true
    }

    @objc func copy(_ sender: Any?) {
        guard !selectedText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedText, forType: .string)
    }

    override func selectAll(_ sender: Any?) {
        selection =
            document.text.isEmpty ? nil : NSRange(location: 0, length: document.text.utf16.count)
        needsDisplay = true
        quickTranslation?.update(ImageTextPreviewTarget.make(document: document, selection: selection, point: .zero))
    }

    func viewRect(for rect: CGRect) -> CGRect {
        guard let image, image.size.width > 0 else { return .zero }
        let scale = imageRect.width / image.size.width
        return CGRect(
            x: imageRect.minX + rect.minX * scale, y: imageRect.minY + rect.minY * scale,
            width: rect.width * scale, height: rect.height * scale)
    }

    func cursor(atImagePoint point: CGPoint) -> NSCursor {
        document.selectionRegions.contains { $0.bounds.contains(point) } ? .iBeam : .arrow
    }

    private func imagePoint(for event: NSEvent) -> CGPoint {
        guard let image, imageRect.width > 0 else { return .zero }
        let point = convert(event.locationInWindow, from: nil)
        let scale = imageRect.width / image.size.width
        return CGPoint(x: (point.x - imageRect.minX) / scale, y: (point.y - imageRect.minY) / scale)
    }

    @objc private func focusChanged() {
        if !isSelectionEmphasized { endGesture() }
        refreshSelectionDisplay()
    }

    private func refreshSelectionDisplay() {
        needsDisplay = true
        window?.invalidateCursorRects(for: self)
    }

    private func endGesture() {
        pointerDown = nil
        isDragging = false
        hasReachedText = false
    }

    private func updateCursor(at point: CGPoint) {
        guard isSelectionEmphasized else { return }
        cursor(atImagePoint: point).set()
    }

    private func updateBackgroundColor() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        }
    }
}
