import AppKit

extension ImageViewerNSView {
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
}
