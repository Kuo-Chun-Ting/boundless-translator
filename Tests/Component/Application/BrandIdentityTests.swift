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
func test_menuBarIconImage_when_renderingSharedAppIcon_then_hasStatusItemSize() {
    // Act
    let menuBarIconImage = AppBrand.menuBarIconImage

    // Assert
    #expect(menuBarIconImage.size == NSSize(width: 24, height: 24))
    #expect(!menuBarIconImage.isTemplate)
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

private let projectRootURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
