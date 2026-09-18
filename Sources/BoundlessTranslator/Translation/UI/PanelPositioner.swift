import CoreGraphics

struct WindowPositioner {
    let pointerOffset: CGFloat

    func origin(
        pointer: CGPoint,
        windowSize: CGSize,
        visibleFrame: CGRect
    ) -> CGPoint {
        let preferredOrigin = CGPoint(
            x: pointer.x + pointerOffset,
            y: pointer.y - windowSize.height - pointerOffset
        )
        return clampedOrigin(
            preferredOrigin,
            windowSize: windowSize,
            visibleFrame: visibleFrame
        )
    }

    func resizedOrigin(
        currentFrame: CGRect,
        newWindowSize: CGSize,
        visibleFrame: CGRect
    ) -> CGPoint {
        let preferredOrigin = CGPoint(
            x: currentFrame.minX,
            y: currentFrame.maxY - newWindowSize.height
        )
        return clampedOrigin(
            preferredOrigin,
            windowSize: newWindowSize,
            visibleFrame: visibleFrame
        )
    }

    private func clampedOrigin(
        _ preferredOrigin: CGPoint,
        windowSize: CGSize,
        visibleFrame: CGRect
    ) -> CGPoint {
        let maximumX = max(visibleFrame.minX, visibleFrame.maxX - windowSize.width)
        let maximumY = max(visibleFrame.minY, visibleFrame.maxY - windowSize.height)

        return CGPoint(
            x: min(max(preferredOrigin.x, visibleFrame.minX), maximumX),
            y: min(max(preferredOrigin.y, visibleFrame.minY), maximumY)
        )
    }
}
