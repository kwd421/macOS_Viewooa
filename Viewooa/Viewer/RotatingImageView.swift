import AppKit
import CoreImage

final class RotatingImageView: NSImageView {
    var doubleClickHandler: ((NSEvent) -> Bool)?
    var dragHandler: ((PointerDragPhase, NSEvent) -> Bool)?
    var contextMenuHandler: ((NSEvent) -> Bool)?
    var postProcessingOptions: Set<ImagePostProcessingOption> = [] {
        didSet {
            guard postProcessingOptions != oldValue else { return }
            cachedProcessedImage = nil
            cachedProcessedOptions = nil
            needsDisplay = true
        }
    }
    var rotationQuarterTurns = 0 {
        didSet {
            needsDisplay = true
        }
    }

    override var image: NSImage? {
        didSet {
            if image !== oldValue {
                cachedProcessedImage = nil
                cachedProcessedOptions = nil
            }
        }
    }

    private var cachedProcessedImage: NSImage?
    private var cachedProcessedOptions: Set<ImagePostProcessingOption>?
    private static let ciContext = CIContext(options: [.cacheIntermediates: true])

    var displayedImageSize: NSSize {
        guard let image else { return .zero }

        return Self.displayedSize(
            for: Self.pixelAccuratePointSize(
                for: image,
                backingScaleFactor: effectiveBackingScaleFactor
            ),
            quarterTurns: rotationQuarterTurns
        )
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let image = processedImage() else { return }

        let normalizedQuarterTurns = Self.normalizedQuarterTurnsValue(rotationQuarterTurns)
        guard normalizedQuarterTurns != 0 else {
            image.draw(
                in: bounds,
                from: NSRect(origin: .zero, size: image.size),
                operation: .sourceOver,
                fraction: 1.0,
                respectFlipped: true,
                hints: nil
            )
            return
        }

        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        switch normalizedQuarterTurns {
        case 1:
            transform.translateX(by: 0, yBy: bounds.height)
            transform.rotate(byDegrees: -90)
        case 2:
            transform.translateX(by: bounds.width, yBy: bounds.height)
            transform.rotate(byDegrees: 180)
        case 3:
            transform.translateX(by: bounds.width, yBy: 0)
            transform.rotate(byDegrees: 90)
        default:
            break
        }
        transform.concat()
        image.draw(
            in: NSRect(origin: .zero, size: image.size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: true,
            hints: nil
        )
        NSGraphicsContext.restoreGraphicsState()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(enclosingScrollView)

        if ImageViewerClickActivation.isDoubleClickActivation(clickCount: event.clickCount),
           doubleClickHandler?(event) == true {
            return
        }

        if ImageViewerClickActivation.isMultiClickContinuation(clickCount: event.clickCount) {
            return
        }

        _ = dragHandler?(.began, event)

        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        if dragHandler?(.changed, event) == true {
            return
        }

        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if dragHandler?(.ended, event) == true {
            return
        }

        super.mouseUp(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        window?.makeFirstResponder(enclosingScrollView)

        if contextMenuHandler?(event) == true {
            return
        }

        super.rightMouseDown(with: event)
    }

    private static func displayedSize(for imageSize: NSSize, quarterTurns: Int) -> NSSize {
        let normalizedQuarterTurns = normalizedQuarterTurnsValue(quarterTurns)
        if normalizedQuarterTurns.isMultiple(of: 2) {
            return imageSize
        }

        return NSSize(width: imageSize.height, height: imageSize.width)
    }

    private var effectiveBackingScaleFactor: CGFloat {
        max(1, window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1)
    }

    private static func pixelAccuratePointSize(for image: NSImage, backingScaleFactor: CGFloat) -> NSSize {
        guard backingScaleFactor > 0,
              let pixelSize = pixelSize(for: image) else {
            return image.size
        }

        return NSSize(
            width: CGFloat(pixelSize.width) / backingScaleFactor,
            height: CGFloat(pixelSize.height) / backingScaleFactor
        )
    }

    private static func pixelSize(for image: NSImage) -> NSSize? {
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return NSSize(width: cgImage.width, height: cgImage.height)
        }

        let bitmapRepresentation = image.representations
            .compactMap { $0 as? NSBitmapImageRep }
            .max { lhs, rhs in
                lhs.pixelsWide * lhs.pixelsHigh < rhs.pixelsWide * rhs.pixelsHigh
            }

        guard let bitmapRepresentation else { return nil }
        return NSSize(
            width: bitmapRepresentation.pixelsWide,
            height: bitmapRepresentation.pixelsHigh
        )
    }

    private static func normalizedQuarterTurnsValue(_ quarterTurns: Int) -> Int {
        ((quarterTurns % 4) + 4) % 4
    }

    private func processedImage() -> NSImage? {
        guard let image else { return nil }
        guard !postProcessingOptions.isEmpty else { return image }
        guard !postProcessingOptions.isEmpty else { return image }

        if cachedProcessedOptions == postProcessingOptions,
           let cachedProcessedImage {
            return cachedProcessedImage
        }

        guard let preparedImage = Self.preparedCIImage(from: image) else {
            return image
        }
        var outputImage = preparedImage.image
        let colorSpace = preparedImage.colorSpace
        let originalExtent = outputImage.extent

        if postProcessingOptions.contains(.denoise),
           let filter = CIFilter(name: "CINoiseReduction") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            filter.setValue(0.02, forKey: "inputNoiseLevel")
            filter.setValue(0.45, forKey: "inputSharpness")
            outputImage = filter.outputImage ?? outputImage
        }

        if postProcessingOptions.contains(.smooth),
           let filter = CIFilter(name: "CIGaussianBlur") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            filter.setValue(0.8, forKey: kCIInputRadiusKey)
            outputImage = (filter.outputImage ?? outputImage).cropped(to: originalExtent)
        }

        if postProcessingOptions.contains(.contrast),
           let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            filter.setValue(1.15, forKey: kCIInputContrastKey)
            filter.setValue(1.0, forKey: kCIInputSaturationKey)
            outputImage = filter.outputImage ?? outputImage
        }

        if postProcessingOptions.contains(.sharpen),
           let filter = CIFilter(name: "CISharpenLuminance") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            filter.setValue(0.55, forKey: kCIInputSharpnessKey)
            outputImage = filter.outputImage ?? outputImage
        }

        guard let cgImage = Self.ciContext.createCGImage(
            outputImage,
            from: originalExtent,
            format: .RGBA8,
            colorSpace: colorSpace
        ) else {
            return image
        }

        let processedImage = NSImage(cgImage: cgImage, size: image.size)
        cachedProcessedImage = processedImage
        cachedProcessedOptions = postProcessingOptions
        return processedImage
    }

    private struct PreparedCIImage {
        let image: CIImage
        let colorSpace: CGColorSpace
    }

    private static func preparedCIImage(from image: NSImage) -> PreparedCIImage? {
        let fallbackColorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let colorSpace = cgImage.colorSpace ?? fallbackColorSpace
            let ciImage = CIImage(cgImage: cgImage, options: [.colorSpace: colorSpace])
            return PreparedCIImage(image: ciImage, colorSpace: colorSpace)
        }

        guard let data = image.tiffRepresentation else { return nil }
        guard let ciImage = CIImage(data: data, options: [.colorSpace: fallbackColorSpace]) else { return nil }
        return PreparedCIImage(image: ciImage, colorSpace: fallbackColorSpace)
    }
}
