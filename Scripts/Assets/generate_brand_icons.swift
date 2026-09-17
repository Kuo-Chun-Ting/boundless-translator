#!/usr/bin/swift

import Foundation

private enum IconError: Error {
    case sourceImageMissing(URL)
    case commandFailed(String)
}

private struct IconVariant {
    let sourceName: String
    let outputName: String
}

private struct IconFile {
    let name: String
    let pixels: Int
    let pointSize: String
    let scale: String
}

private let projectRoot = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first
        ?? FileManager.default.currentDirectoryPath
)
private let designDirectory = projectRoot.appending(path: "Design", directoryHint: .isDirectory)
private let iconVariants = [
    IconVariant(
        sourceName: "BoundlessTranslator-Ghost-AppIcon-Transparent-1024.png",
        outputName: "BoundlessTranslator-Ghost-AppIcon-Transparent.icns"
    )
]
private let iconFiles = [
    IconFile(name: "icon_16x16.png", pixels: 16, pointSize: "16x16", scale: "1x"),
    IconFile(name: "icon_16x16@2x.png", pixels: 32, pointSize: "16x16", scale: "2x"),
    IconFile(name: "icon_32x32.png", pixels: 32, pointSize: "32x32", scale: "1x"),
    IconFile(name: "icon_32x32@2x.png", pixels: 64, pointSize: "32x32", scale: "2x"),
    IconFile(name: "icon_128x128.png", pixels: 128, pointSize: "128x128", scale: "1x"),
    IconFile(name: "icon_128x128@2x.png", pixels: 256, pointSize: "128x128", scale: "2x"),
    IconFile(name: "icon_256x256.png", pixels: 256, pointSize: "256x256", scale: "1x"),
    IconFile(name: "icon_256x256@2x.png", pixels: 512, pointSize: "256x256", scale: "2x"),
    IconFile(name: "icon_512x512.png", pixels: 512, pointSize: "512x512", scale: "1x"),
    IconFile(name: "icon_512x512@2x.png", pixels: 1024, pointSize: "512x512", scale: "2x")
]

private func createAppIcons() throws {
    for variant in iconVariants {
        try createAppIcon(variant)
    }
}

private func createAppIcon(_ variant: IconVariant) throws {
    let sourceURL = designDirectory.appending(path: variant.sourceName)
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
        throw IconError.sourceImageMissing(sourceURL)
    }

    let temporaryDirectory = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
        .appending(path: "BoundlessTranslator-AppIcon-\(UUID().uuidString)", directoryHint: .isDirectory)
    let catalogURL = temporaryDirectory.appending(path: "Assets.xcassets", directoryHint: .isDirectory)
    let iconsetURL = catalogURL.appending(path: "AppIcon.appiconset", directoryHint: .isDirectory)
    let outputDirectory = temporaryDirectory.appending(path: "Output", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

    try writeManifest(to: iconsetURL)
    for iconFile in iconFiles {
        try resize(sourceURL, to: iconFile, in: iconsetURL)
    }
    try package(catalogURL, in: outputDirectory)
    try writeCombinedIcon(
        compiledIconURL: outputDirectory.appending(path: "AppIcon.icns"),
        iconsetURL: iconsetURL,
        outputURL: designDirectory.appending(path: variant.outputName)
    )
}

private func writeManifest(to iconsetURL: URL) throws {
    let images = iconFiles.map { iconFile in
        [
            "filename": iconFile.name,
            "idiom": "mac",
            "scale": iconFile.scale,
            "size": iconFile.pointSize
        ]
    }
    let manifest: [String: Any] = [
        "images": images,
        "info": ["author": "xcode", "version": 1]
    ]
    let data = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: iconsetURL.appending(path: "Contents.json"), options: .atomic)
}

private func resize(_ sourceURL: URL, to iconFile: IconFile, in iconsetURL: URL) throws {
    let outputURL = iconsetURL.appending(path: iconFile.name)
    try run(
        "/usr/bin/sips",
        arguments: [
            "-z", String(iconFile.pixels), String(iconFile.pixels),
            sourceURL.path,
            "--out", outputURL.path
        ]
    )
}

private func package(_ catalogURL: URL, in outputDirectory: URL) throws {
    let partialInfoURL = outputDirectory.appending(path: "PartialInfo.plist")
    try run(
        "/usr/bin/xcrun",
        arguments: [
            "actool",
            "--compile", outputDirectory.path,
            "--platform", "macosx",
            "--minimum-deployment-target", "15.0",
            "--app-icon", "AppIcon",
            "--output-partial-info-plist", partialInfoURL.path,
            catalogURL.path
        ]
    )
}

private func writeCombinedIcon(compiledIconURL: URL, iconsetURL: URL, outputURL: URL) throws {
    let compiledIcon = try Data(contentsOf: compiledIconURL)
    var body = compiledIcon.chunks(matching: ["ic04", "ic07", "ic11", "ic13"])
    let additionalChunks = [
        ("ic12", "icon_32x32@2x.png"),
        ("ic08", "icon_256x256.png"),
        ("ic14", "icon_256x256@2x.png"),
        ("ic09", "icon_512x512.png"),
        ("ic10", "icon_512x512@2x.png")
    ]
    for chunk in additionalChunks {
        body.appendIconChunk(
            type: chunk.0,
            image: try Data(contentsOf: iconsetURL.appending(path: chunk.1))
        )
    }

    var icon = Data("icns".utf8)
    icon.appendBigEndian(UInt32(body.count + 8))
    icon.append(body)
    try icon.write(to: outputURL, options: .atomic)
}

private func run(_ executable: String, arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = FileHandle.nullDevice
    process.environment = ProcessInfo.processInfo.environment.merging(
        ["DEVELOPER_DIR": "/Applications/Xcode.app/Contents/Developer"],
        uniquingKeysWith: { _, newValue in newValue }
    )
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw IconError.commandFailed(executable)
    }
}

try FileManager.default.createDirectory(at: designDirectory, withIntermediateDirectories: true)
try createAppIcons()

private extension Data {
    func chunks(matching expectedTypes: Set<String>) -> Data {
        var result = Data()
        var offset = 8
        while offset + 8 <= count {
            let type = String(data: self[offset..<(offset + 4)], encoding: .ascii) ?? ""
            let chunkSize = Int(bigEndianUInt32(at: offset + 4))
            guard chunkSize >= 8, offset + chunkSize <= count else { break }
            if expectedTypes.contains(type) {
                result.append(self[offset..<(offset + chunkSize)])
            }
            offset += chunkSize
        }
        return result
    }

    func bigEndianUInt32(at offset: Int) -> UInt32 {
        self[offset..<(offset + 4)].reduce(UInt32(0)) { value, byte in
            (value << 8) | UInt32(byte)
        }
    }

    mutating func appendIconChunk(type: String, image: Data) {
        append(contentsOf: type.utf8)
        appendBigEndian(UInt32(image.count + 8))
        append(image)
    }

    mutating func appendBigEndian(_ value: UInt32) {
        var bigEndianValue = value.bigEndian
        Swift.withUnsafeBytes(of: &bigEndianValue) { bytes in
            append(contentsOf: bytes)
        }
    }
}
