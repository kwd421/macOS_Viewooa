import AppKit

@MainActor
final class ImageViewerImageStack {
    private let containerView: DoubleClickAwareView
    private let configureHandlers: (RotatingImageView) -> Void
    private let primaryImageView = RotatingImageView()
    private var imageViews: [RotatingImageView] = []

    init(
        containerView: DoubleClickAwareView,
        configureHandlers: @escaping (RotatingImageView) -> Void
    ) {
        self.containerView = containerView
        self.configureHandlers = configureHandlers

        primaryImageView.imageScaling = .scaleNone
        imageViews = [primaryImageView]
        configureHandlers(primaryImageView)
        containerView.addSubview(primaryImageView)
    }

    var displayedImage: NSImage? {
        primaryImageView.image
    }

    var displayedImageSizes: [NSSize] {
        imageViews.map(\.displayedImageSize)
    }

    var primaryImageFrame: NSRect {
        primaryImageView.frame
    }

    var primaryImageBounds: NSRect {
        primaryImageView.bounds
    }

    func convertWindowPointToPrimaryImage(_ locationInWindow: NSPoint) -> NSPoint {
        primaryImageView.convert(locationInWindow, from: nil)
    }

    func loadImages(
        resolvedImage: NSImage?,
        resolvedImages: [NSImage]?,
        currentImageURL: URL?,
        imageURLs: [URL]
    ) {
        guard !imageURLs.isEmpty else {
            configureImageViewCount(1)
            imageViews.forEach { imageView in
                imageView.image = nil
                imageView.frame = .zero
            }
            containerView.frame = .zero
            return
        }

        configureImageViewCount(imageURLs.count)
        for (index, url) in imageURLs.enumerated() {
            let resolvedDisplayImage = resolvedImages?.indices.contains(index) == true ? resolvedImages?[index] : nil
            let sourceImage = resolvedDisplayImage ?? (url == currentImageURL ? resolvedImage : nil) ?? ImageFileLoader.loadDisplayImage(at: url)
            imageViews[index].image = sourceImage
            imageViews[index].frame = NSRect(origin: .zero, size: imageViews[index].displayedImageSize)
            imageViews[index].needsDisplay = true
        }
    }

    func updateRotation(_ rotationQuarterTurns: Int) {
        for imageView in imageViews {
            imageView.rotationQuarterTurns = rotationQuarterTurns
            imageView.frame = NSRect(origin: imageView.frame.origin, size: imageView.displayedImageSize)
        }
    }

    func updatePostProcessingOptions(_ options: Set<ImagePostProcessingOption>) {
        for imageView in imageViews {
            imageView.postProcessingOptions = options
        }
    }

    func applyFrames(_ frames: [NSRect]) {
        for (index, frame) in frames.enumerated() where index < imageViews.count {
            imageViews[index].frame = frame
        }
    }

    private func configureImageViewCount(_ count: Int) {
        let requiredCount = max(1, count)

        while imageViews.count < requiredCount {
            let view = RotatingImageView()
            view.imageScaling = .scaleNone
            configureHandlers(view)
            imageViews.append(view)
            containerView.addSubview(view)
        }

        while imageViews.count > requiredCount {
            imageViews.removeLast().removeFromSuperview()
        }
    }
}
