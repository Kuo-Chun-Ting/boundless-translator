#!/usr/bin/env swift
import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

struct Sample: Decodable {
    let text: String
    let ocrImage: String?
}

let directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let samples = try JSONDecoder().decode([Sample].self, from: Data(contentsOf: directory.appendingPathComponent("languages.json")))
let output = directory.appendingPathComponent("OCR")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

for sample in samples {
    guard let name = sample.ocrImage else { continue }
    let text = NSAttributedString(string: sample.text, attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Helvetica" as CFString, 36, nil),
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0, alpha: 1)
    ])
    let line = CTLineCreateWithAttributedString(text)
    let width = Int(ceil(CTLineGetTypographicBounds(line, nil, nil, nil))) + 80
    let context = CGContext(
        data: nil, width: width, height: 140, bitsPerComponent: 8,
        bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: 140))
    context.textPosition = CGPoint(x: 40, y: 50)
    CTLineDraw(line, context)
    let destination = CGImageDestinationCreateWithURL(output.appendingPathComponent(name) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    precondition(CGImageDestinationFinalize(destination))
}
