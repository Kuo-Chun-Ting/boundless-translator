import Foundation
import AppKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test
func test_infoPlistTemplate_when_readingPublicNames_then_usesBoundlessTranslator() throws {
    // Arrange
    let infoPlistURL = projectRootURL
        .appending(path: "Resources")
        .appending(path: "Info.plist")

    // Act
    let infoPlist = try String(contentsOf: infoPlistURL, encoding: .utf8)

    // Assert
    #expect(infoPlist.contains("<key>CFBundleDisplayName</key>\n\t<string>$(PRODUCT_NAME)</string>"))
    #expect(infoPlist.contains("<key>CFBundleName</key>\n\t<string>$(PRODUCT_NAME)</string>"))
    #expect(infoPlist.contains("<key>CFBundleExecutable</key>\n\t<string>$(EXECUTABLE_NAME)</string>"))
    #expect(infoPlist.contains("<key>CFBundleIdentifier</key>\n\t<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>"))
    #expect(infoPlist.contains("<key>CFBundleIconFile</key>\n\t<string>AppIcon.icns</string>"))
}

@Test
func test_errorDescription_when_accessibilityPermissionIsRequired_then_namesBoundlessTranslator() {
    // Arrange
    let error = SelectedTextReadError.accessibilityPermissionRequired

    // Act
    let message = error.errorDescription

    // Assert
    #expect(
        message == "Allow Boundless Translator in System Settings > Privacy & Security > Accessibility."
    )
}

@Test
func test_iconFileName_when_renderingBrandIcon_then_usesAppBundleIcon() {
    // Act
    let iconFileName = AppBrand.iconFileName

    // Assert
    #expect(iconFileName == "AppIcon.icns")
}

@Test
func test_brandResources_when_inspectingAssets_then_containsOnlySharedAppIcon() {
    // Arrange
    let resourcesURL = projectRootURL.appending(path: "Resources")

    // Act
    let appIconExists = FileManager.default.fileExists(
        atPath: resourcesURL.appending(path: "AppIcon.icns").path
    )
    let separateMenuBarIconExists = FileManager.default.fileExists(
        atPath: resourcesURL.appending(path: "MenuBarIconTemplate.png").path
    )
    let separateMenuBarIcon2xExists = FileManager.default.fileExists(
        atPath: resourcesURL.appending(path: "MenuBarIconTemplate@2x.png").path
    )

    // Assert
    #expect(appIconExists)
    #expect(!separateMenuBarIconExists)
    #expect(!separateMenuBarIcon2xExists)
}

@MainActor
@Test
func test_menuBarIconImage_when_renderingSharedSprite_then_hasStatusItemSize() {
    // Act
    let menuBarIconImage = AppBrand.menuBarIconImage

    // Assert
    #expect(menuBarIconImage.size == NSSize(width: 24, height: 24))
    #expect(!menuBarIconImage.isTemplate)
}

@Test(arguments: [false, true], [1, 2])
@MainActor
func test_menuBarIconImage_when_rendered_then_preservesTransparentBackground(isDark: Bool, scale: Int) throws {
    // Arrange
    let appearance = try #require(NSAppearance(named: isDark ? .darkAqua : .aqua))
    let sprite = try renderIcon(AppBrand.spriteImage, scale: scale, appearance: appearance)

    // Act
    let rendered = try renderIcon(AppBrand.menuBarIconImage, scale: scale, appearance: appearance)

    // Assert
    var transparentPixels = 0
    for y in 0..<sprite.pixelsHigh {
        for x in 0..<sprite.pixelsWide {
            let expectedAlpha = try #require(sprite.colorAt(x: x, y: y)).alphaComponent
            if expectedAlpha == 0 {
                transparentPixels += 1
                #expect(try #require(rendered.colorAt(x: x, y: y)).alphaComponent == 0)
            }
        }
    }
    #expect(transparentPixels > sprite.pixelsWide * sprite.pixelsHigh / 4)
    #expect(try #require(rendered.colorAt(x: rendered.pixelsWide / 2, y: rendered.pixelsHigh / 2)).alphaComponent > 0.5)
}

@Test
func test_menuBarIconRenderingMode_when_renderingBrandIcon_then_preservesOriginalColors() {
    // Act
    let renderingMode = AppBrand.menuBarIconRenderingMode

    // Assert
    #expect(renderingMode == .original)
}

@Test
@MainActor
func test_spriteImage_when_loaded_then_hasVisibleArtworkAndTransparentCorners() throws {
    // Arrange
    let image = AppBrand.spriteImage

    // Act
    let data = try #require(image.tiffRepresentation)
    let bitmap = try #require(NSBitmapImageRep(data: data))

    // Assert
    #expect(bitmap.hasAlpha)
    for (x, y) in [(0, 0), (bitmap.pixelsWide - 1, 0), (0, bitmap.pixelsHigh - 1),
                   (bitmap.pixelsWide - 1, bitmap.pixelsHigh - 1)] {
        #expect(try #require(bitmap.colorAt(x: x, y: y)).alphaComponent == 0)
    }
    #expect(try #require(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2)).alphaComponent > 0)
}

@MainActor
private func renderIcon(_ image: NSImage, scale: Int, appearance: NSAppearance) throws -> NSBitmapImageRep {
    let pixels = 24 * scale
    let bitmap = try #require(NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ))
    let context = try #require(NSGraphicsContext(bitmapImageRep: bitmap))
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = context
    let bounds = NSRect(x: 0, y: 0, width: pixels, height: pixels)
    context.cgContext.clear(bounds)
    appearance.performAsCurrentDrawingAppearance {
        image.draw(in: bounds)
    }
    return bitmap
}

private let projectRootURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
