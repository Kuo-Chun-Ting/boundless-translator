import AppKit
import SwiftUI

enum AppBrand {
    static let displayName = "Boundless Translator"
    static let iconFileName = "AppIcon.icns"
    static let menuBarIconRenderingMode: Image.TemplateRenderingMode = .original

    @MainActor
    static let spriteImage: NSImage = {
#if SWIFT_PACKAGE
        let bundle = Bundle.module
#else
        let bundle = Bundle.main
#endif
        let url = bundle.url(forResource: "BrandSprite", withExtension: "png")!
        return NSImage(contentsOf: url)!
    }()

    @MainActor
    static var iconImage: NSImage {
        NSApplication.shared.applicationIconImage
    }

    @MainActor
    static var menuBarIconImage: NSImage {
        let size = NSSize(width: 24, height: 24)
        let sourceImage = spriteImage
        let image = NSImage(size: size, flipped: false) { rect in
            sourceImage.draw(in: rect)
            return true
        }
        image.isTemplate = false
        return image
    }
}
