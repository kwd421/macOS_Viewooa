import AppKit

extension ViewerState {
    func toggleActualSize() {
        if case .actualSize = zoomMode {
            fitToWindow()
        } else {
            zoomMode = .actualSize
        }
    }

    func zoomIn() {
        zoomMode = .custom(clampedZoomScale(currentZoomScale * ViewerZoom.step))
    }

    func zoomOut() {
        zoomMode = .custom(clampedZoomScale(currentZoomScale / ViewerZoom.step))
    }

    func fitToWindow(_ fitMode: FitMode? = nil) {
        zoomMode = .fit(fitMode ?? preferredFitMode)
        fitRequestID += 1
    }

    func updateViewportMetrics(displayedMagnification: CGFloat, fitMagnification: CGFloat, isEntireImageVisible: Bool) {
        self.displayedMagnification = displayedMagnification
        self.fitMagnification = fitMagnification
        self.isEntireImageVisible = isEntireImageVisible
    }

    var currentZoomScale: CGFloat {
        switch zoomMode {
        case .fit(_):
            displayedMagnification
        case .actualSize:
            1.0
        case let .custom(scale):
            scale
        }
    }

    func clampedZoomScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, ViewerZoom.minimumScale), ViewerZoom.maximumScale)
    }
}
