import AppKit

extension ImageViewerNSView {
    static func fitMagnification(
        imageSize: NSSize,
        viewportSize: NSSize,
        fitMode: FitMode,
        minimumMagnification: CGFloat,
        maximumMagnification: CGFloat
    ) -> CGFloat {
        guard imageSize.width > 0,
              imageSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0 else {
            return 1.0
        }

        let widthScale = viewportSize.width / imageSize.width
        let heightScale = viewportSize.height / imageSize.height
        let fitScale: CGFloat
        switch fitMode {
        case .height:
            fitScale = heightScale
        case .width:
            fitScale = widthScale
        case .all:
            fitScale = min(widthScale, heightScale)
        }
        return min(max(fitScale, minimumMagnification), maximumMagnification)
    }

    static func commandWheelMagnification(
        currentMagnification: CGFloat,
        delta: CGFloat,
        minimumMagnification: CGFloat,
        maximumMagnification: CGFloat
    ) -> CGFloat {
        guard currentMagnification > 0 else { return minimumMagnification }

        let factor = pow(1.01, delta)
        return min(max(currentMagnification * factor, minimumMagnification), maximumMagnification)
    }

    static func pinchMagnification(
        currentMagnification: CGFloat,
        delta: CGFloat,
        minimumMagnification: CGFloat,
        maximumMagnification: CGFloat
    ) -> CGFloat {
        guard currentMagnification > 0 else { return minimumMagnification }

        let factor = exp(delta * 1.2)
        return min(max(currentMagnification * factor, minimumMagnification), maximumMagnification)
    }
}
