import AppKit

extension ImageViewerNSView {
    @discardableResult
    func handleDoubleClick(centeredAt imagePoint: NSPoint? = nil) -> Bool {
        guard displayedImage != nil else { return false }

        pointerDragCoordinator.reset()

        switch viewportState.zoomMode {
        case .fit(_):
            setZoomModeFromUserInput(.actualSize, centeredAt: imagePoint)
        case .actualSize, .custom:
            setZoomModeFromUserInput(.fit(lastFitMode), centeredAt: nil)
        }

        return true
    }

    @discardableResult
    func handleDoubleClick(anchoredAtDocumentPoint documentPoint: NSPoint) -> Bool {
        guard displayedImage != nil else { return false }

        pointerDragCoordinator.reset()

        let contentOffset = Self.anchoredContentOffset(
            documentPoint: documentPoint,
            contentFrame: currentContentFrame()
        )
        let anchorUnitPoint = Self.anchorUnitPoint(
            anchorDocumentPoint: documentPoint,
            visibleRect: scrollView.contentView.bounds
        )

        switch viewportState.zoomMode {
        case .fit(_):
            setZoomModeFromUserInput(
                .actualSize,
                anchoredContentOffset: contentOffset,
                anchorUnitPoint: anchorUnitPoint
            )
        case .actualSize, .custom:
            setZoomModeFromUserInput(.fit(lastFitMode), centeredAt: nil)
        }

        return true
    }

    func handleDoubleClick(event: NSEvent) -> Bool {
        handleDoubleClick(anchoredAtDocumentPoint: documentPoint(forWindowLocation: event.locationInWindow))
    }

    func imagePoint(for event: NSEvent) -> NSPoint {
        imagePoint(forWindowLocation: event.locationInWindow)
    }

    func imagePoint(forWindowLocation locationInWindow: NSPoint) -> NSPoint {
        let convertedPoint = imageStack.convertWindowPointToPrimaryImage(locationInWindow)
        return Self.clampedPoint(convertedPoint, to: imageStack.primaryImageBounds)
    }

    func centeredDocumentPoint(for imagePoint: NSPoint?) -> NSPoint {
        guard let imagePoint else { return viewportPresenter.containerCenterPoint }
        return Self.documentPoint(forImagePoint: imagePoint, imageFrame: imageStack.primaryImageFrame)
    }

    func documentPoint(forWindowLocation locationInWindow: NSPoint) -> NSPoint {
        let convertedPoint = documentContainerView.convert(locationInWindow, from: nil)
        return Self.clampedPoint(convertedPoint, to: documentContainerView.bounds)
    }

    func currentContentFrame() -> NSRect {
        viewportPresenter.currentContentFrame(displayedImageSize: displayedImageSize)
    }
}
