import CoreGraphics

struct PanelPositioner {
    let pointerOffset: CGFloat

    func origin(
        pointer: CGPoint,
        panelSize: CGSize,
        visibleFrame: CGRect
    ) -> CGPoint {
        let preferredOrigin = CGPoint(
            x: pointer.x + pointerOffset,
            y: pointer.y - panelSize.height - pointerOffset
        )
        let maximumX = max(visibleFrame.minX, visibleFrame.maxX - panelSize.width)
        let maximumY = max(visibleFrame.minY, visibleFrame.maxY - panelSize.height)

        return CGPoint(
            x: min(max(preferredOrigin.x, visibleFrame.minX), maximumX),
            y: min(max(preferredOrigin.y, visibleFrame.minY), maximumY)
        )
    }
}
