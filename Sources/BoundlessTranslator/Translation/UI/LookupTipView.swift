import AppKit
import SwiftUI
import TipKit

struct LookupTip: Tip {
    let localization: AppLocalization

    var title: Text {
        Text(verbatim: localization.string("lookup.action"))
    }

    var message: Text? {
        Text(verbatim: localization.string("lookup.guidance"))
    }
}

struct LookupTipView: View {
    let tip: LookupTip
    let width: CGFloat
    let localization: AppLocalization

    var body: some View {
        HStack(spacing: 10) {
            Text(LookupActionOverlay.bookIcon)
                .font(.custom("Apple Color Emoji", size: 28))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                tip.title
                    .font(.headline)
                tip.message
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

            Button {
                tip.invalidate(reason: .tipClosed)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(localization.string("lookup.dismiss"))
            .accessibilityLabel(localization.string("lookup.dismiss"))
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(12)
        .frame(width: max(160, width))
        .padding(.bottom, LookupTipShape.tailHeight)
        .fixedSize(horizontal: false, vertical: true)
        .modifier(LookupTipMaterial())
        .accessibilityIdentifier("lookup.guidance")
    }
}

private struct LookupTipMaterial: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffect(.regular.interactive(), in: LookupTipShape())
        } else {
            content.background(.regularMaterial, in: LookupTipShape())
        }
    }
}

private struct LookupTipShape: Shape {
    static let tailHeight: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 12
        let bottom = rect.maxY - Self.tailHeight
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: bottom - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: bottom),
                          control: CGPoint(x: rect.maxX, y: bottom))
        path.addLine(to: CGPoint(x: rect.minX + 18, y: bottom))
        path.addLine(to: CGPoint(x: rect.minX + 3, y: rect.maxY - 1))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - 3),
                          control: CGPoint(x: rect.minX, y: rect.maxY + 1))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
