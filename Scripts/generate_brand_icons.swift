#!/usr/bin/swift

import AppKit
import Foundation

private enum IconError: Error {
    case bitmapCreationFailed
    case pngEncodingFailed
}

private let projectRoot = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath)
private let resourcesDirectory = projectRoot.appending(path: "Resources", directoryHint: .isDirectory)

private func renderPNG(
    pixelSize: Int,
    draw: (_ size: CGFloat) -> Void
) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw IconError.bitmapCreationFailed
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize).fill()
    draw(CGFloat(pixelSize))
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw IconError.pngEncodingFailed
    }
    return data
}

private func drawTranslatorMark(in rect: NSRect, color: NSColor, lineWidth: CGFloat) {
    let mark = NSBezierPath()
    mark.lineWidth = lineWidth
    mark.lineCapStyle = .round
    mark.lineJoinStyle = .round

    let crossbarY = rect.minY + (rect.height * 0.68)
    mark.move(to: NSPoint(x: rect.minX + (rect.width * 0.24), y: crossbarY))
    mark.line(to: NSPoint(x: rect.maxX - (rect.width * 0.24), y: crossbarY))
    mark.move(to: NSPoint(x: rect.midX, y: crossbarY))
    mark.line(to: NSPoint(x: rect.midX, y: rect.minY + (rect.height * 0.25)))

    color.setStroke()
    mark.stroke()
}

private func drawAppIcon(size: CGFloat) {
    let scale = size / 1024
    let iconRect = NSRect(x: 72 * scale, y: 72 * scale, width: 880 * scale, height: 880 * scale)
    let background = NSBezierPath(roundedRect: iconRect, xRadius: 210 * scale, yRadius: 210 * scale)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.16, green: 0.55, blue: 0.98, alpha: 1),
        NSColor(red: 0.08, green: 0.32, blue: 0.86, alpha: 1)
    ])
    gradient?.draw(in: background, angle: -90)

    let highlightRect = NSRect(x: iconRect.minX, y: iconRect.midY, width: iconRect.width, height: iconRect.height / 2)
    NSGraphicsContext.saveGraphicsState()
    background.addClip()
    NSGradient(colors: [NSColor.white.withAlphaComponent(0.18), NSColor.clear])?
        .draw(in: highlightRect, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    let markRect = iconRect.insetBy(dx: 150 * scale, dy: 150 * scale)
    drawTranslatorMark(in: markRect, color: .white, lineWidth: 92 * scale)
}

private func createAppIcon() throws {
    let variants: [(type: String, pixels: Int)] = [
        ("icp4", 16),
        ("ic11", 32),
        ("icp5", 32),
        ("ic12", 64),
        ("ic07", 128),
        ("ic13", 256),
        ("ic08", 256),
        ("ic14", 512),
        ("ic09", 512),
        ("ic10", 1024)
    ]

    var body = Data()
    for variant in variants {
        let png = try renderPNG(pixelSize: variant.pixels, draw: drawAppIcon)
        body.append(contentsOf: variant.type.utf8)
        body.appendBigEndian(UInt32(png.count + 8))
        body.append(png)
    }

    var icon = Data("icns".utf8)
    icon.appendBigEndian(UInt32(body.count + 8))
    icon.append(body)
    try icon.write(to: resourcesDirectory.appending(path: "AppIcon.icns"), options: .atomic)
}

try FileManager.default.createDirectory(at: resourcesDirectory, withIntermediateDirectories: true)
try createAppIcon()

private extension Data {
    mutating func appendBigEndian(_ value: UInt32) {
        var bigEndianValue = value.bigEndian
        Swift.withUnsafeBytes(of: &bigEndianValue) { bytes in
            append(contentsOf: bytes)
        }
    }
}
