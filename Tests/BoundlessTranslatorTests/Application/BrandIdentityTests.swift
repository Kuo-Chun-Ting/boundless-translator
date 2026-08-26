import Foundation
import AppKit
import SwiftUI
import Testing
@testable import BoundlessTranslator

@Test
func test_infoPlist_when_readingPublicNames_then_usesBoundlessTranslator() throws {
    // Arrange
    let infoPlistURL = projectRootURL
        .appending(path: "Resources")
        .appending(path: "Info.plist")

    // Act
    let data = try Data(contentsOf: infoPlistURL)
    let appInfo = try PropertyListDecoder().decode(AppInfo.self, from: data)

    // Assert
    #expect(appInfo.displayName == "Boundless Translator")
    #expect(appInfo.bundleName == "Boundless Translator")
    #expect(appInfo.executableName == "BoundlessTranslator")
    #expect(appInfo.bundleIdentifier == "com.lillard.BoundlessTranslator")
    #expect(appInfo.iconFile == "AppIcon.icns")
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
    #expect(menuBarIconImage.size == NSSize(width: 18, height: 18))
    #expect(!menuBarIconImage.isTemplate)
}

@Test
func test_menuBarIconRenderingMode_when_renderingBrandIcon_then_preservesOriginalColors() {
    // Act
    let renderingMode = AppBrand.menuBarIconRenderingMode

    // Assert
    #expect(renderingMode == .original)
}

private struct AppInfo: Decodable {
    let displayName: String
    let bundleName: String
    let executableName: String
    let bundleIdentifier: String
    let iconFile: String

    private enum CodingKeys: String, CodingKey {
        case displayName = "CFBundleDisplayName"
        case bundleName = "CFBundleName"
        case executableName = "CFBundleExecutable"
        case bundleIdentifier = "CFBundleIdentifier"
        case iconFile = "CFBundleIconFile"
    }
}

private let projectRootURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
