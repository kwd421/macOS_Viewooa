import AppKit

extension ImageViewerNSView {
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
