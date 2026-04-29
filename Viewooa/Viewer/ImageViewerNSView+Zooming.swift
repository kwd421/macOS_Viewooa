import AppKit

extension ImageViewerNSView {
    func applyZoomMode(_ zoomMode: ZoomMode, animated: Bool = true) {
        switch zoomMode {
        case let .fit(fitMode):
            applyFitMagnification(fitMode, animated: animated)
        case .actualSize:
            applyImageCenterProgrammaticMagnification(1.0)
        case let .custom(scale):
            handleMagnificationChange(scale, isUserInitiated: false)
        }
    }

    func applyFitMagnification(_ fitMode: FitMode, animated: Bool = true) {
        lastFitMode = fitMode
        let imageSize = displayedImageSize
        let viewportSize = viewportSizeForLayout

        guard imageSize.width > 0,
              imageSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0 else {
            return
        }

        let clampedScale = Self.fitMagnification(
            imageSize: imageSize,
            viewportSize: viewportSize,
            fitMode: fitMode,
            minimumMagnification: scrollView.minMagnification,
            maximumMagnification: scrollView.maxMagnification
        )

        let targetOrigin = Self.centeredVisibleRectOrigin(
            containerSize: Self.documentContainerSize(
                imageSize: imageSize,
                viewportSize: viewportSize,
                magnification: clampedScale
            ),
            viewportSize: viewportSizeForLayout,
            magnification: clampedScale
        )
        applyProgrammaticMagnification(
            clampedScale,
            centeredAt: viewportPresenter.containerCenterPoint,
            finalOrigin: targetOrigin,
            animated: animated
        )
    }

    var viewportSizeForLayout: NSSize {
        viewportPresenter.viewportSizeForLayout
    }

    func handleMagnificationChange(
        _ magnification: CGFloat,
        isUserInitiated: Bool,
        centeredImagePoint: NSPoint? = nil
    ) {
        let clampedScale = min(max(magnification, scrollView.minMagnification), scrollView.maxMagnification)

        if isUserInitiated {
            guard !zoomAnimator.isApplyingProgrammaticMagnification else { return }

            let zoomMode = ZoomMode.custom(clampedScale)
            viewportState.zoomMode = zoomMode
            updateViewportPresentation(for: clampedScale)
            let targetDocumentPoint = centeredDocumentPoint(for: centeredImagePoint)
            if abs(scrollView.magnification - clampedScale) > 0.0001 {
                zoomAnimator.performProgrammaticMagnification {
                    scrollView.setMagnification(
                        clampedScale,
                        centeredAt: targetDocumentPoint
                    )
                }
            }
            if centeredImagePoint != nil {
                centerVisibleRect(on: targetDocumentPoint, for: clampedScale)
            }
            onZoomModeChange?(zoomMode)
            return
        }

        guard let centeredImagePoint else {
            applyVisibleCenterProgrammaticMagnification(clampedScale)
            return
        }

        let targetDocumentPoint = centeredDocumentPoint(for: centeredImagePoint)
        let targetOrigin = centeredOrigin(for: targetDocumentPoint, magnification: clampedScale)
        applyProgrammaticMagnification(
            clampedScale,
            centeredAt: targetDocumentPoint,
            finalOrigin: targetOrigin
        )
    }

    func setZoomModeFromUserInput(_ zoomMode: ZoomMode, centeredAt imagePoint: NSPoint? = nil) {
        viewportState.zoomMode = zoomMode
        switch zoomMode {
        case let .fit(fitMode):
            applyZoomMode(.fit(fitMode))
        case .actualSize:
            handleMagnificationChange(1.0, isUserInitiated: false, centeredImagePoint: imagePoint)
        case let .custom(scale):
            handleMagnificationChange(scale, isUserInitiated: false, centeredImagePoint: imagePoint)
        }
        onZoomModeChange?(zoomMode)
    }

    func setZoomModeFromUserInput(
        _ zoomMode: ZoomMode,
        anchoredContentOffset contentOffset: NSPoint,
        anchorUnitPoint: NSPoint
    ) {
        viewportState.zoomMode = zoomMode
        switch zoomMode {
        case let .fit(fitMode):
            applyZoomMode(.fit(fitMode))
        case .actualSize:
            applyAnchoredProgrammaticMagnification(
                1.0,
                contentOffset: contentOffset,
                anchorUnitPoint: anchorUnitPoint
            )
        case let .custom(scale):
            applyAnchoredProgrammaticMagnification(
                scale,
                contentOffset: contentOffset,
                anchorUnitPoint: anchorUnitPoint
            )
        }
        onZoomModeChange?(zoomMode)
    }

    func handleMagnificationChange(
        _ magnification: CGFloat,
        isUserInitiated: Bool,
        centeredDocumentPoint documentPoint: NSPoint?
    ) {
        let clampedScale = min(max(magnification, scrollView.minMagnification), scrollView.maxMagnification)

        if isUserInitiated {
            guard !zoomAnimator.isApplyingProgrammaticMagnification else { return }

            let zoomMode = ZoomMode.custom(clampedScale)
            viewportState.zoomMode = zoomMode
            updateViewportPresentation(for: clampedScale)
            let targetDocumentPoint = documentPoint ?? viewportPresenter.containerCenterPoint
            if abs(scrollView.magnification - clampedScale) > 0.0001 {
                zoomAnimator.performProgrammaticMagnification {
                    scrollView.setMagnification(
                        clampedScale,
                        centeredAt: targetDocumentPoint
                    )
                }
            }
            if documentPoint != nil {
                centerVisibleRect(on: targetDocumentPoint, for: clampedScale)
            }
            onZoomModeChange?(zoomMode)
            return
        }

        let targetDocumentPoint = documentPoint ?? viewportPresenter.containerCenterPoint
        let targetOrigin = centeredOrigin(for: targetDocumentPoint, magnification: clampedScale)
        applyProgrammaticMagnification(
            clampedScale,
            centeredAt: targetDocumentPoint,
            finalOrigin: targetOrigin
        )
    }

    @objc
    func scrollViewDidEndLiveMagnify(_ notification: Notification) {
        finishTrackpadMagnifyGesture()
    }

    @discardableResult
    func finishTrackpadMagnifyGesture(animated: Bool = true) -> Bool {
        if snapBackToFitIfNeeded(animated: animated) {
            return true
        }

        handleMagnificationChange(scrollView.magnification, isUserInitiated: true)
        return true
    }

    @discardableResult
    func snapBackToFitIfNeeded(animated: Bool = true) -> Bool {
        guard displayedImage != nil else { return false }

        let fitScale = currentFitMagnification
        guard fitScale.isFinite,
              scrollView.magnification < fitScale - 0.0001 else {
            return false
        }

        let targetZoomMode = ZoomMode.fit(lastFitMode)
        let targetOrigin = Self.centeredVisibleRectOrigin(
            containerSize: Self.documentContainerSize(
                imageSize: displayedImageSize,
                viewportSize: viewportSizeForLayout,
                magnification: fitScale
            ),
            viewportSize: viewportSizeForLayout,
            magnification: fitScale
        )
        viewportState.zoomMode = targetZoomMode

        guard animated else {
            updateViewportPresentation(for: fitScale)
            zoomAnimator.applyProgrammaticMagnification(
                fitScale,
                centeredAt: viewportPresenter.containerCenterPoint,
                finalOrigin: targetOrigin,
                canAnimateInWindow: false,
                updatePresentation: { [weak self] in
                    self?.updateViewportPresentation(for: $0)
                }
            )
            onZoomModeChange?(targetZoomMode)
            return true
        }

        applyProgrammaticMagnification(
            fitScale,
            centeredAt: viewportPresenter.containerCenterPoint,
            finalOrigin: targetOrigin
        )
        onZoomModeChange?(targetZoomMode)

        return true
    }

}
