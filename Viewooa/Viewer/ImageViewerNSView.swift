import AppKit

final class ImageViewerNSView: NSView {
    private let scrollView = NSScrollView()
    private let imageView = NSImageView()
    private var viewportState = ImageViewportState()
    private var isApplyingProgrammaticMagnification = false

    var onZoomModeChange: ((ZoomMode) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        imageView.imageScaling = .scaleNone

        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.05
        scrollView.maxMagnification = 8.0
        scrollView.documentView = imageView

        addSubview(scrollView)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidEndLiveMagnify),
            name: NSScrollView.didEndLiveMagnifyNotification,
            object: scrollView
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layout() {
        super.layout()
        scrollView.frame = bounds

        if viewportState.zoomMode == .fit {
            applyZoomMode(.fit)
        }
    }

    func apply(imageURL: URL?, zoomMode: ZoomMode, rotationQuarterTurns: Int) {
        let newState = ImageViewportState(
            imageURL: imageURL,
            zoomMode: zoomMode,
            rotationQuarterTurns: rotationQuarterTurns
        )

        if newState.imageURL != viewportState.imageURL
            || newState.rotationQuarterTurns != viewportState.rotationQuarterTurns {
            loadImage(at: imageURL, rotationQuarterTurns: rotationQuarterTurns)
        }

        if newState.zoomMode != viewportState.zoomMode
            || newState.imageURL != viewportState.imageURL
            || newState.rotationQuarterTurns != viewportState.rotationQuarterTurns {
            applyZoomMode(zoomMode)
        }

        viewportState = newState
    }

    private func loadImage(at imageURL: URL?, rotationQuarterTurns: Int) {
        guard let imageURL, let image = NSImage(contentsOf: imageURL) else {
            imageView.image = nil
            imageView.frame = .zero
            return
        }

        let displayImage = rotatedImage(image, quarterTurns: rotationQuarterTurns)
        imageView.image = displayImage
        imageView.frame = NSRect(origin: .zero, size: displayImage.size)
    }

    private func applyZoomMode(_ zoomMode: ZoomMode) {
        switch zoomMode {
        case .fit:
            applyFitMagnification()
        case .actualSize:
            handleMagnificationChange(1.0, isUserInitiated: false)
        case let .custom(scale):
            handleMagnificationChange(scale, isUserInitiated: false)
        }
    }

    private func applyFitMagnification() {
        let imageSize = imageView.image?.size ?? .zero
        let viewportSize = scrollView.contentView.bounds.size

        guard imageSize.width > 0,
              imageSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0 else {
            return
        }

        let widthScale = viewportSize.width / imageSize.width
        let heightScale = viewportSize.height / imageSize.height
        let fitScale = min(widthScale, heightScale, 1.0)
        let clampedScale = min(max(fitScale, scrollView.minMagnification), scrollView.maxMagnification)

        isApplyingProgrammaticMagnification = true
        scrollView.setMagnification(clampedScale, centeredAt: imageCenterPoint)
        isApplyingProgrammaticMagnification = false
    }

    private var imageCenterPoint: NSPoint {
        NSPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
    }

    func handleMagnificationChange(_ magnification: CGFloat, isUserInitiated: Bool) {
        let clampedScale = min(max(magnification, scrollView.minMagnification), scrollView.maxMagnification)

        if isUserInitiated {
            guard !isApplyingProgrammaticMagnification else { return }

            let zoomMode = ZoomMode.custom(clampedScale)
            viewportState.zoomMode = zoomMode
            onZoomModeChange?(zoomMode)
            return
        }

        guard abs(scrollView.magnification - clampedScale) > 0.0001 else { return }

        isApplyingProgrammaticMagnification = true
        scrollView.setMagnification(clampedScale, centeredAt: imageCenterPoint)
        isApplyingProgrammaticMagnification = false
    }

    @objc
    private func scrollViewDidEndLiveMagnify(_ notification: Notification) {
        handleMagnificationChange(scrollView.magnification, isUserInitiated: true)
    }

    private func rotatedImage(_ image: NSImage, quarterTurns: Int) -> NSImage {
        let normalizedQuarterTurns = ((quarterTurns % 4) + 4) % 4

        guard normalizedQuarterTurns != 0 else {
            return image
        }

        let rotatedSize: NSSize
        if normalizedQuarterTurns.isMultiple(of: 2) {
            rotatedSize = image.size
        } else {
            rotatedSize = NSSize(width: image.size.height, height: image.size.width)
        }

        let rotatedImage = NSImage(size: rotatedSize)
        rotatedImage.lockFocus()

        let transform = NSAffineTransform()
        switch normalizedQuarterTurns {
        case 1:
            transform.translateX(by: rotatedSize.width, yBy: 0)
            transform.rotate(byDegrees: 90)
        case 2:
            transform.translateX(by: rotatedSize.width, yBy: rotatedSize.height)
            transform.rotate(byDegrees: 180)
        case 3:
            transform.translateX(by: 0, yBy: rotatedSize.height)
            transform.rotate(byDegrees: 270)
        default:
            break
        }

        transform.concat()
        image.draw(
            in: NSRect(origin: .zero, size: image.size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1
        )
        rotatedImage.unlockFocus()

        return rotatedImage
    }
}
