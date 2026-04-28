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

    static func isEndingMagnifyGesture(phase: NSEvent.Phase) -> Bool {
        phase.contains(.ended) || phase.contains(.cancelled)
    }

    static func isEndingScrollGesture(phase: NSEvent.Phase, momentumPhase: NSEvent.Phase) -> Bool {
        phase.contains(.ended)
            || phase.contains(.cancelled)
            || momentumPhase.contains(.ended)
            || momentumPhase.contains(.cancelled)
    }

    static func canPanVisibleRect(
        documentSize: NSSize,
        viewportSize: NSSize,
        magnification: CGFloat
    ) -> Bool {
        guard documentSize.width > 0,
              documentSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0,
              magnification > 0 else {
            return false
        }

        let visibleWidth = viewportSize.width / magnification
        let visibleHeight = viewportSize.height / magnification
        return documentSize.width > visibleWidth + 0.0001
            || documentSize.height > visibleHeight + 0.0001
    }

    static func imageScrollability(
        imageSize: NSSize,
        viewportSize: NSSize,
        magnification: CGFloat
    ) -> (horizontal: Bool, vertical: Bool) {
        guard imageSize.width > 0,
              imageSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0,
              magnification > 0 else {
            return (false, false)
        }

        let scaledWidth = imageSize.width * magnification
        let scaledHeight = imageSize.height * magnification
        return (
            horizontal: scaledWidth > viewportSize.width + 0.0001,
            vertical: scaledHeight > viewportSize.height + 0.0001
        )
    }

    static func displayedContentSize(imageSizes: [NSSize], pageLayout: ViewerPageLayout) -> NSSize {
        let sizes = imageSizes.filter { $0.width > 0 && $0.height > 0 }
        guard !sizes.isEmpty else { return .zero }

        switch pageLayout {
        case .single:
            return sizes[0]
        case .spread:
            return NSSize(
                width: sizes.reduce(0) { $0 + $1.width },
                height: sizes.map(\.height).max() ?? 0
            )
        case .verticalStrip:
            return NSSize(
                width: sizes.map(\.width).max() ?? 0,
                height: sizes.reduce(0) { $0 + $1.height }
            )
        }
    }

    static func imageFrames(imageSizes: [NSSize], containerSize: NSSize, pageLayout: ViewerPageLayout) -> [NSRect] {
        let contentSize = displayedContentSize(imageSizes: imageSizes, pageLayout: pageLayout)
        guard contentSize.width > 0, contentSize.height > 0 else {
            return imageSizes.map { _ in .zero }
        }

        let contentFrame = centeredImageFrame(imageSize: contentSize, containerSize: containerSize)

        switch pageLayout {
        case .single:
            return [contentFrame]
        case .spread:
            var nextX = contentFrame.minX
            return imageSizes.map { size in
                defer { nextX += size.width }
                return NSRect(
                    x: nextX,
                    y: contentFrame.midY - (size.height / 2),
                    width: size.width,
                    height: size.height
                )
            }
        case .verticalStrip:
            var nextY = contentFrame.maxY
            return imageSizes.map { size in
                nextY -= size.height
                return NSRect(
                    x: contentFrame.midX - (size.width / 2),
                    y: nextY,
                    width: size.width,
                    height: size.height
                )
            }
        }
    }

    static func pannedVisibleRectOrigin(
        currentOrigin: NSPoint,
        documentSize: NSSize,
        viewportSize: NSSize,
        magnification: CGFloat,
        dragDelta: NSPoint
    ) -> NSPoint {
        guard documentSize.width > 0,
              documentSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0,
              magnification > 0 else {
            return currentOrigin
        }

        let visibleWidth = viewportSize.width / magnification
        let visibleHeight = viewportSize.height / magnification
        let maximumX = max(0, documentSize.width - visibleWidth)
        let maximumY = max(0, documentSize.height - visibleHeight)
        let nextX = currentOrigin.x - (dragDelta.x / magnification)
        let nextY = currentOrigin.y - (dragDelta.y / magnification)

        return NSPoint(
            x: min(max(nextX, 0), maximumX),
            y: min(max(nextY, 0), maximumY)
        )
    }

    static func verticalAutoScrollOrigin(
        currentOrigin: NSPoint,
        documentSize: NSSize,
        viewportSize: NSSize,
        magnification: CGFloat,
        screenPointDelta: CGFloat
    ) -> NSPoint {
        guard documentSize.width > 0,
              documentSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0,
              magnification > 0 else {
            return currentOrigin
        }

        let visibleWidth = viewportSize.width / magnification
        let visibleHeight = viewportSize.height / magnification
        let maximumX = max(0, documentSize.width - visibleWidth)
        let maximumY = max(0, documentSize.height - visibleHeight)
        let nextY = currentOrigin.y - (screenPointDelta / magnification)

        return NSPoint(
            x: min(max(currentOrigin.x, 0), maximumX),
            y: min(max(nextY, 0), maximumY)
        )
    }

    static func isBeyondClickDragTolerance(from startLocation: NSPoint, to currentLocation: NSPoint) -> Bool {
        let deltaX = currentLocation.x - startLocation.x
        let deltaY = currentLocation.y - startLocation.y
        return (deltaX * deltaX) + (deltaY * deltaY) >= 16
    }

    static func clampedPoint(_ point: NSPoint, to rect: NSRect) -> NSPoint {
        NSPoint(
            x: min(max(point.x, rect.minX), rect.maxX),
            y: min(max(point.y, rect.minY), rect.maxY)
        )
    }

    static func documentPoint(forImagePoint imagePoint: NSPoint, imageFrame: NSRect) -> NSPoint {
        NSPoint(
            x: imageFrame.minX + imagePoint.x,
            y: imageFrame.minY + imagePoint.y
        )
    }

    static func anchoredContentOffset(documentPoint: NSPoint, contentFrame: NSRect) -> NSPoint {
        NSPoint(
            x: min(max(documentPoint.x - contentFrame.minX, 0), contentFrame.width),
            y: min(max(documentPoint.y - contentFrame.minY, 0), contentFrame.height)
        )
    }

    static func documentPoint(contentOffset: NSPoint, contentFrame: NSRect) -> NSPoint {
        NSPoint(
            x: contentFrame.minX + min(max(contentOffset.x, 0), contentFrame.width),
            y: contentFrame.minY + min(max(contentOffset.y, 0), contentFrame.height)
        )
    }

    static func navigationDirection(forKeyCode keyCode: UInt16) -> NavigationDirection? {
        switch keyCode {
        case 123:
            return .previous
        case 124:
            return .next
        default:
            return nil
        }
    }

    static func documentContainerSize(
        imageSize: NSSize,
        viewportSize: NSSize,
        magnification: CGFloat
    ) -> NSSize {
        guard imageSize.width > 0,
              imageSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0,
              magnification > 0 else {
            return .zero
        }

        let visibleDocumentWidth = viewportSize.width / magnification
        let visibleDocumentHeight = viewportSize.height / magnification

        return NSSize(
            width: max(imageSize.width, visibleDocumentWidth),
            height: max(imageSize.height, visibleDocumentHeight)
        )
    }

    static func centeredVisibleRectOrigin(
        containerSize: NSSize,
        viewportSize: NSSize,
        magnification: CGFloat
    ) -> NSPoint {
        guard containerSize.width > 0,
              containerSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0,
              magnification > 0 else {
            return .zero
        }

        let visibleDocumentWidth = viewportSize.width / magnification
        let visibleDocumentHeight = viewportSize.height / magnification

        return NSPoint(
            x: max(0, (containerSize.width - visibleDocumentWidth) / 2),
            y: max(0, (containerSize.height - visibleDocumentHeight) / 2)
        )
    }

    static func visibleRectOrigin(
        centeredOn documentPoint: NSPoint,
        containerSize: NSSize,
        viewportSize: NSSize,
        magnification: CGFloat
    ) -> NSPoint {
        guard containerSize.width > 0,
              containerSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0,
              magnification > 0 else {
            return .zero
        }

        let visibleDocumentWidth = viewportSize.width / magnification
        let visibleDocumentHeight = viewportSize.height / magnification
        let maximumX = max(0, containerSize.width - visibleDocumentWidth)
        let maximumY = max(0, containerSize.height - visibleDocumentHeight)

        return NSPoint(
            x: min(max(documentPoint.x - (visibleDocumentWidth / 2), 0), maximumX),
            y: min(max(documentPoint.y - (visibleDocumentHeight / 2), 0), maximumY)
        )
    }

    static func visibleRectOrigin(
        anchoring documentPoint: NSPoint,
        at unitPoint: NSPoint,
        containerSize: NSSize,
        viewportSize: NSSize,
        magnification: CGFloat
    ) -> NSPoint {
        guard containerSize.width > 0,
              containerSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0,
              magnification > 0 else {
            return .zero
        }

        let visibleDocumentWidth = viewportSize.width / magnification
        let visibleDocumentHeight = viewportSize.height / magnification
        let maximumX = max(0, containerSize.width - visibleDocumentWidth)
        let maximumY = max(0, containerSize.height - visibleDocumentHeight)
        let requestedX = documentPoint.x - (visibleDocumentWidth * unitPoint.x)
        let requestedY = documentPoint.y - (visibleDocumentHeight * unitPoint.y)

        return NSPoint(
            x: min(max(requestedX, 0), maximumX),
            y: min(max(requestedY, 0), maximumY)
        )
    }

    static func anchorUnitPoint(anchorDocumentPoint: NSPoint, visibleRect: NSRect) -> NSPoint {
        guard visibleRect.width > 0, visibleRect.height > 0 else {
            return NSPoint(x: 0.5, y: 0.5)
        }

        return NSPoint(
            x: min(max((anchorDocumentPoint.x - visibleRect.minX) / visibleRect.width, 0), 1),
            y: min(max((anchorDocumentPoint.y - visibleRect.minY) / visibleRect.height, 0), 1)
        )
    }

    static func centeredImageFrame(
        imageSize: NSSize,
        containerSize: NSSize
    ) -> NSRect {
        guard imageSize.width > 0,
              imageSize.height > 0,
              containerSize.width > 0,
              containerSize.height > 0 else {
            return .zero
        }

        return NSRect(
            x: (containerSize.width - imageSize.width) / 2,
            y: (containerSize.height - imageSize.height) / 2,
            width: imageSize.width,
            height: imageSize.height
        )
    }
}
