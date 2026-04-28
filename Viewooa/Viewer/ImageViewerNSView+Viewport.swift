import AppKit

extension ImageViewerNSView {
    var currentFitMagnification: CGFloat {
        viewportPresenter.currentFitMagnification(
            displayedImageSize: displayedImageSize,
            fitMode: lastFitMode
        )
    }

    func updateViewportPresentation(for displayedMagnification: CGFloat) {
        viewportPresenter.updatePresentation(
            displayedMagnification: displayedMagnification,
            pageLayout: viewportState.pageLayout
        )

        onViewportMetricsChange?(
            displayedMagnification,
            currentFitMagnification,
            isEntireImageVisible
        )
    }

    func applyProgrammaticMagnification(
        _ magnification: CGFloat,
        centeredAt documentPoint: NSPoint,
        finalOrigin: NSPoint? = nil
    ) {
        zoomAnimator.applyProgrammaticMagnification(
            magnification,
            centeredAt: documentPoint,
            finalOrigin: finalOrigin,
            canAnimateInWindow: window != nil,
            updatePresentation: { [weak self] in
                self?.updateViewportPresentation(for: $0)
            }
        )
    }

    func applyAnchoredProgrammaticMagnification(
        _ magnification: CGFloat,
        contentOffset: NSPoint,
        anchorUnitPoint: NSPoint
    ) {
        zoomAnimator.applyAnchoredProgrammaticMagnification(
            magnification,
            contentOffset: contentOffset,
            anchorUnitPoint: anchorUnitPoint,
            canAnimateInWindow: window != nil,
            updatePresentation: { [weak self] in
                self?.updateViewportPresentation(for: $0)
            },
            targetForMagnification: { [weak self] currentMagnification in
                guard let self else {
                    return (documentPoint: .zero, origin: .zero)
                }
                return self.anchoredZoomTarget(
                    contentOffset: contentOffset,
                    anchorUnitPoint: anchorUnitPoint,
                    magnification: currentMagnification
                )
            }
        )
    }

    func anchoredZoomTarget(
        contentOffset: NSPoint,
        anchorUnitPoint: NSPoint,
        magnification: CGFloat
    ) -> (documentPoint: NSPoint, origin: NSPoint) {
        let updatedDocumentPoint = Self.documentPoint(
            contentOffset: contentOffset,
            contentFrame: currentContentFrame()
        )
        let targetOrigin = Self.visibleRectOrigin(
            anchoring: updatedDocumentPoint,
            at: anchorUnitPoint,
            containerSize: documentContainerView.bounds.size,
            viewportSize: viewportSizeForLayout,
            magnification: magnification
        )

        return (updatedDocumentPoint, targetOrigin)
    }

    var isEntireImageVisible: Bool {
        viewportPresenter.isEntireImageVisible(displayedImageSize: displayedImageSize)
    }

    var isImageScrollableHorizontally: Bool {
        viewportPresenter.imageScrollability(displayedImageSize: displayedImageSize).horizontal
    }

    var isImageScrollableVertically: Bool {
        viewportPresenter.imageScrollability(displayedImageSize: displayedImageSize).vertical
    }

    func centerVisibleRect(for magnification: CGFloat) {
        viewportPresenter.centerVisibleRect(for: magnification)
    }

    func centerVisibleRect(on documentPoint: NSPoint, for magnification: CGFloat) {
        viewportPresenter.centerVisibleRect(on: documentPoint, for: magnification)
    }

    var canPanVisibleRect: Bool {
        isImageScrollableHorizontally || isImageScrollableVertically
    }

    func panVisibleRect(from previousLocation: NSPoint, to currentLocation: NSPoint) {
        viewportPresenter.panVisibleRect(from: previousLocation, to: currentLocation)
    }

    func setVerticalAutoScrollScreenSpeed(_ screenSpeed: CGFloat) {
        verticalAutoScrollCoordinator.setScreenSpeed(
            screenSpeed,
            isEnabled: viewportState.pageLayout == .verticalStrip,
            onStep: { [weak self] elapsed, screenSpeed in
                self?.performVerticalAutoScroll(elapsed: elapsed, screenSpeed: screenSpeed) ?? false
            },
            onReachedEnd: { [weak self] in
                self?.onVerticalSlideshowReachedEnd?()
            }
        )
    }

    func performVerticalAutoScroll(elapsed: TimeInterval, screenSpeed: CGFloat) -> Bool {
        viewportPresenter.performVerticalAutoScroll(elapsed: elapsed, screenSpeed: screenSpeed)
    }
}
