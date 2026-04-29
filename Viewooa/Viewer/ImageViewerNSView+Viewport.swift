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
        finalOrigin: NSPoint? = nil,
        animated: Bool = true,
        originForMagnification: (@MainActor (CGFloat) -> NSPoint)? = nil
    ) {
        zoomAnimator.applyProgrammaticMagnification(
            magnification,
            centeredAt: documentPoint,
            finalOrigin: finalOrigin,
            canAnimateInWindow: animated && window != nil,
            originForMagnification: originForMagnification,
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
        let target = anchoredZoomTarget(
            contentOffset: contentOffset,
            anchorUnitPoint: anchorUnitPoint,
            magnification: magnification,
            usingContainerSize: Self.documentContainerSize(
                imageSize: displayedImageSize,
                viewportSize: viewportSizeForLayout,
                magnification: magnification
            )
        )
        applyProgrammaticMagnification(
            magnification,
            centeredAt: target.documentPoint,
            finalOrigin: target.origin,
            originForMagnification: { [weak self] currentMagnification in
                guard let self else { return target.origin }
                return self.anchoredZoomTarget(
                    contentOffset: contentOffset,
                    anchorUnitPoint: anchorUnitPoint,
                    magnification: currentMagnification,
                    usingContainerSize: Self.documentContainerSize(
                        imageSize: self.displayedImageSize,
                        viewportSize: self.viewportSizeForLayout,
                        magnification: currentMagnification
                    )
                ).origin
            }
        )
    }

    func applyVisibleCenterProgrammaticMagnification(_ magnification: CGFloat) {
        let visibleCenter = viewportPresenter.visibleDocumentCenterPoint
        let contentOffset = Self.anchoredContentOffset(
            documentPoint: visibleCenter,
            contentFrame: currentContentFrame()
        )
        applyAnchoredProgrammaticMagnification(
            magnification,
            contentOffset: contentOffset,
            anchorUnitPoint: NSPoint(x: 0.5, y: 0.5)
        )
    }

    func applyImageCenterProgrammaticMagnification(_ magnification: CGFloat) {
        let contentFrame = currentContentFrame()
        let contentCenter = NSPoint(x: contentFrame.midX, y: contentFrame.midY)
        let contentOffset = Self.anchoredContentOffset(
            documentPoint: contentCenter,
            contentFrame: contentFrame
        )
        applyAnchoredProgrammaticMagnification(
            magnification,
            contentOffset: contentOffset,
            anchorUnitPoint: NSPoint(x: 0.5, y: 0.5)
        )
    }

    func centeredOrigin(for documentPoint: NSPoint, magnification: CGFloat) -> NSPoint {
        Self.visibleRectOrigin(
            centeredOn: documentPoint,
            containerSize: Self.documentContainerSize(
                imageSize: displayedImageSize,
                viewportSize: viewportSizeForLayout,
                magnification: magnification
            ),
            viewportSize: viewportSizeForLayout,
            magnification: magnification
        )
    }

    func anchoredZoomTarget(
        contentOffset: NSPoint,
        anchorUnitPoint: NSPoint,
        magnification: CGFloat,
        usingContainerSize targetContainerSize: NSSize? = nil
    ) -> (documentPoint: NSPoint, origin: NSPoint) {
        let containerSize = targetContainerSize ?? documentContainerView.bounds.size
        let updatedDocumentPoint = Self.documentPoint(
            contentOffset: contentOffset,
            contentFrame: Self.centeredImageFrame(
                imageSize: displayedImageSize,
                containerSize: containerSize
            )
        )
        let targetOrigin = Self.visibleRectOrigin(
            anchoring: updatedDocumentPoint,
            at: anchorUnitPoint,
            containerSize: containerSize,
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
