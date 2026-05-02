import AppKit

extension ViewerState {
    func toggleActualSize() {
        if case .actualSize = zoomMode {
            fitToWindow()
        } else {
            zoomMode = .actualSize
            showZoomPercentage(for: 1.0)
        }
    }

    func zoomIn() {
        setZoomModeWithPercentage(.custom(clampedZoomScale(currentZoomScale * ViewerZoom.step)))
    }

    func zoomOut() {
        setZoomModeWithPercentage(.custom(clampedZoomScale(currentZoomScale / ViewerZoom.step)))
    }

    func fitToWindow(_ fitMode: FitMode? = nil) {
        zoomMode = .fit(fitMode ?? preferredFitMode)
        fitRequestID += 1
        showZoomPercentage(for: fitMagnification)
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
        min(max(scale, minimumAllowedZoomScale), ViewerZoom.maximumScale)
    }

    var minimumAllowedZoomScale: CGFloat {
        ViewerZoom.minimumAllowedScale(fitMagnification: fitMagnification)
    }

    func setZoomModeFromViewer(_ zoomMode: ZoomMode) {
        setZoomModeWithPercentage(zoomMode)
    }

    private func setZoomModeWithPercentage(_ zoomMode: ZoomMode) {
        self.zoomMode = zoomMode
        showZoomPercentage(for: zoomMode.percentageScale(fallbackFitScale: fitMagnification))
    }

    func showZoomPercentage(for scale: CGFloat) {
        guard scale.isFinite, scale > 0 else { return }

        zoomPercentageText = "\(Int((scale * 100).rounded()))%"
        isZoomPercentageVisible = true
        zoomPercentageDismissTask?.cancel()
        zoomPercentageDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(850))
            guard !Task.isCancelled else { return }
            isZoomPercentageVisible = false
        }
    }
}

private extension ZoomMode {
    func percentageScale(fallbackFitScale: CGFloat) -> CGFloat {
        switch self {
        case .fit(_):
            fallbackFitScale
        case .actualSize:
            1.0
        case let .custom(scale):
            scale
        }
    }
}
