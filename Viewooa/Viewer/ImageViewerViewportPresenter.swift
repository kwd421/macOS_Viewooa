import AppKit

@MainActor
final class ImageViewerViewportPresenter {
    private let scrollView: NavigationAwareScrollView
    private let documentContainerView: DoubleClickAwareView
    private let imageStack: ImageViewerImageStack

    init(
        scrollView: NavigationAwareScrollView,
        documentContainerView: DoubleClickAwareView,
        imageStack: ImageViewerImageStack
    ) {
        self.scrollView = scrollView
        self.documentContainerView = documentContainerView
        self.imageStack = imageStack
    }

    var viewportSizeForLayout: NSSize {
        let boundsSize = scrollView.bounds.size
        if boundsSize.width > 0, boundsSize.height > 0 {
            return boundsSize
        }

        return scrollView.contentSize
    }

    var containerCenterPoint: NSPoint {
        NSPoint(x: documentContainerView.bounds.midX, y: documentContainerView.bounds.midY)
    }

    func displayedContentSize(pageLayout: ViewerPageLayout) -> NSSize {
        ImageViewerNSView.displayedContentSize(
            imageSizes: imageStack.displayedImageSizes,
            pageLayout: pageLayout
        )
    }

    func currentContentFrame(displayedImageSize: NSSize) -> NSRect {
        ImageViewerNSView.centeredImageFrame(
            imageSize: displayedImageSize,
            containerSize: documentContainerView.bounds.size
        )
    }

    func currentFitMagnification(displayedImageSize: NSSize, fitMode: FitMode) -> CGFloat {
        ImageViewerNSView.fitMagnification(
            imageSize: displayedImageSize,
            viewportSize: viewportSizeForLayout,
            fitMode: fitMode,
            minimumMagnification: scrollView.minMagnification,
            maximumMagnification: scrollView.maxMagnification
        )
    }

    func updatePresentation(displayedMagnification: CGFloat, pageLayout: ViewerPageLayout) {
        let imageSize = displayedContentSize(pageLayout: pageLayout)
        let containerSize = ImageViewerNSView.documentContainerSize(
            imageSize: imageSize,
            viewportSize: viewportSizeForLayout,
            magnification: displayedMagnification
        )

        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        documentContainerView.frame = NSRect(origin: .zero, size: containerSize)
        imageStack.applyFrames(
            ImageViewerNSView.imageFrames(
                imageSizes: imageStack.displayedImageSizes,
                containerSize: containerSize,
                pageLayout: pageLayout
            )
        )
    }

    func isEntireImageVisible(displayedImageSize: NSSize) -> Bool {
        let viewportSize = viewportSizeForLayout

        guard displayedImageSize.width > 0,
              displayedImageSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0 else {
            return true
        }

        let scaledWidth = displayedImageSize.width * scrollView.magnification
        let scaledHeight = displayedImageSize.height * scrollView.magnification
        return scaledWidth <= viewportSize.width + 0.0001
            && scaledHeight <= viewportSize.height + 0.0001
    }

    func imageScrollability(displayedImageSize: NSSize) -> (horizontal: Bool, vertical: Bool) {
        ImageViewerNSView.imageScrollability(
            imageSize: displayedImageSize,
            viewportSize: viewportSizeForLayout,
            magnification: scrollView.magnification
        )
    }

    func centerVisibleRect(for magnification: CGFloat) {
        let centeredOrigin = ImageViewerNSView.centeredVisibleRectOrigin(
            containerSize: documentContainerView.bounds.size,
            viewportSize: viewportSizeForLayout,
            magnification: magnification
        )

        scroll(to: centeredOrigin)
    }

    func centerVisibleRect(on documentPoint: NSPoint, for magnification: CGFloat) {
        let centeredOrigin = ImageViewerNSView.visibleRectOrigin(
            centeredOn: documentPoint,
            containerSize: documentContainerView.bounds.size,
            viewportSize: viewportSizeForLayout,
            magnification: magnification
        )

        scroll(to: centeredOrigin)
    }

    func panVisibleRect(from previousLocation: NSPoint, to currentLocation: NSPoint) {
        let dragDelta = NSPoint(
            x: currentLocation.x - previousLocation.x,
            y: currentLocation.y - previousLocation.y
        )
        let nextOrigin = ImageViewerNSView.pannedVisibleRectOrigin(
            currentOrigin: scrollView.contentView.bounds.origin,
            documentSize: documentContainerView.bounds.size,
            viewportSize: viewportSizeForLayout,
            magnification: scrollView.magnification,
            dragDelta: dragDelta
        )

        scroll(to: nextOrigin)
    }

    func performVerticalAutoScroll(elapsed: TimeInterval, screenSpeed: CGFloat) -> Bool {
        guard screenSpeed > 0 else { return true }

        let currentOrigin = scrollView.contentView.bounds.origin
        let nextOrigin = ImageViewerNSView.verticalAutoScrollOrigin(
            currentOrigin: currentOrigin,
            documentSize: documentContainerView.bounds.size,
            viewportSize: viewportSizeForLayout,
            magnification: scrollView.magnification,
            screenPointDelta: screenSpeed * elapsed
        )

        guard abs(nextOrigin.y - currentOrigin.y) > 0.0001 || abs(nextOrigin.x - currentOrigin.x) > 0.0001 else {
            return false
        }

        scroll(to: nextOrigin)
        return true
    }

    private func scroll(to origin: NSPoint) {
        scrollView.contentView.scroll(to: origin)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
}
