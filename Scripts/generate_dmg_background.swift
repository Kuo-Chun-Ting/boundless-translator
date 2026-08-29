#!/usr/bin/env swift

import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: generate_dmg_background.swift <output-path>\n".utf8))
    exit(1)
}

let canvasSize = NSSize(width: 640, height: 360)
let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize.width),
    pixelsHigh: Int(canvasSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
bitmap.size = canvasSize

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

NSColor(srgbRed: 0.965, green: 0.965, blue: 0.975, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()

let arrowColor = NSColor(srgbRed: 0.36, green: 0.50, blue: 0.78, alpha: 0.92)
arrowColor.setStroke()
arrowColor.setFill()

let shaft = NSBezierPath()
shaft.lineWidth = 7
shaft.lineCapStyle = .round
shaft.move(to: NSPoint(x: 270, y: 180))
shaft.line(to: NSPoint(x: 360, y: 180))
shaft.stroke()

let arrowHead = NSBezierPath()
arrowHead.move(to: NSPoint(x: 360, y: 195))
arrowHead.line(to: NSPoint(x: 382, y: 180))
arrowHead.line(to: NSPoint(x: 360, y: 165))
arrowHead.close()
arrowHead.fill()

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("Could not create DMG background PNG.\n".utf8))
    exit(1)
}

let outputURL = URL(fileURLWithPath: arguments[1])
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try pngData.write(to: outputURL, options: .atomic)

print("Generated \(outputURL.path)")
