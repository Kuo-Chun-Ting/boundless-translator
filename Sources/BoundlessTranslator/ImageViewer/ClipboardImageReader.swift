import AppKit

@MainActor
protocol ClipboardImageReading: AnyObject {
    func readImage() -> NSImage?
}

@MainActor
final class PasteboardClipboardImageReader: ClipboardImageReading {
    private let imageProvider: () -> NSImage?

    init(pasteboard: NSPasteboard = .general) {
        imageProvider = { NSImage(pasteboard: pasteboard) }
    }

    init(imageProvider: @escaping () -> NSImage?) {
        self.imageProvider = imageProvider
    }

    func readImage() -> NSImage? {
        imageProvider()
    }
}
