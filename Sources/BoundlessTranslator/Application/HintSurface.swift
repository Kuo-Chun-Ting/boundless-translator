import SwiftUI

enum HintPresentation {
    case inline
    case callout
}

struct HintSurface: Shape {
    let presentation: HintPresentation

    func path(in rect: CGRect) -> Path {
        guard presentation == .callout else { return Path(rect) }
        let left = rect.minX + 8
        let right = rect.maxX
        let top = rect.minY
        let bottom = rect.maxY
        let radius: CGFloat = 12
        var path = Path()
        path.move(to: CGPoint(x: left + radius, y: top))
        path.addLine(to: CGPoint(x: right - radius, y: top))
        path.addQuadCurve(to: CGPoint(x: right, y: top + radius), control: CGPoint(x: right, y: top))
        path.addLine(to: CGPoint(x: right, y: bottom - radius))
        path.addQuadCurve(to: CGPoint(x: right - radius, y: bottom), control: CGPoint(x: right, y: bottom))
        path.addLine(to: CGPoint(x: left + radius, y: bottom))
        path.addQuadCurve(to: CGPoint(x: left, y: bottom - radius), control: CGPoint(x: left, y: bottom))
        path.addLine(to: CGPoint(x: left, y: bottom - 20))
        path.addLine(to: CGPoint(x: rect.minX, y: bottom - 28))
        path.addLine(to: CGPoint(x: left, y: bottom - 36))
        path.addLine(to: CGPoint(x: left, y: top + radius))
        path.addQuadCurve(to: CGPoint(x: left + radius, y: top), control: CGPoint(x: left, y: top))
        path.closeSubpath()
        return path
    }
}
