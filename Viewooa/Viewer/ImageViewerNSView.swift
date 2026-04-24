import AppKit
import CoreImage

private enum PointerDragPhase {
    case began
    case changed
    case ended
}

private final class NavigationAwareScrollView: NSScrollView {
    var scrollHandler: ((NSEvent) -> Bool)?
    var magnifyHandler: ((NSEvent) -> Bool)?
    var doubleClickHandler: ((NSEvent) -> Bool)?
    var keyDownHandler: ((NSEvent) -> Bool)?
    var keyUpHandler: ((NSEvent) -> Bool)?
    var dragHandler: ((PointerDragPhase, NSEvent) -> Bool)?
    var contextMenuHandler: ((NSEvent) -> Bool)?

    override var acceptsFirstResponder: Bool { true }

    override func scrollWheel(with event: NSEvent) {
        if scrollHandler?(event) == true {
            return
        }

        super.scrollWheel(with: event)
    }

    override func magnify(with event: NSEvent) {
        if magnifyHandler?(event) == true {
            return
        }

        super.magnify(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)

        if event.clickCount == 2, doubleClickHandler?(event) == true {
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
        window?.makeFirstResponder(self)

        if contextMenuHandler?(event) == true {
            return
        }

        super.rightMouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if keyDownHandler?(event) == true {
            return
        }

        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        if keyUpHandler?(event) == true {
            return
        }

        super.keyUp(with: event)
    }
}

private final class DoubleClickAwareView: NSView {
    var doubleClickHandler: ((NSEvent) -> Bool)?
    var dragHandler: ((PointerDragPhase, NSEvent) -> Bool)?
    var contextMenuHandler: ((NSEvent) -> Bool)?

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(enclosingScrollView)

        if event.clickCount == 2, doubleClickHandler?(event) == true {
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
}

private final class RotatingImageView: NSImageView {
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

        return Self.displayedSize(for: image.size, quarterTurns: rotationQuarterTurns)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let image = processedImage() else { return }

        let previousInterpolation = NSGraphicsContext.current?.imageInterpolation
        if postProcessingOptions.contains(.actualSizeRepair) {
            NSGraphicsContext.current?.imageInterpolation = .high
        }
        defer {
            if let previousInterpolation {
                NSGraphicsContext.current?.imageInterpolation = previousInterpolation
            }
        }

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

    private static func displayedSize(for imageSize: NSSize, quarterTurns: Int) -> NSSize {
        let normalizedQuarterTurns = normalizedQuarterTurnsValue(quarterTurns)
        if normalizedQuarterTurns.isMultiple(of: 2) {
            return imageSize
        }

        return NSSize(width: imageSize.height, height: imageSize.width)
    }

    private static func normalizedQuarterTurnsValue(_ quarterTurns: Int) -> Int {
        ((quarterTurns % 4) + 4) % 4
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(enclosingScrollView)

        if event.clickCount == 2, doubleClickHandler?(event) == true {
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

    private func processedImage() -> NSImage? {
        guard let image else { return nil }
        guard !postProcessingOptions.isEmpty else { return image }
        let pixelProcessingOptions = postProcessingOptions.subtracting([.actualSizeRepair])
        guard !pixelProcessingOptions.isEmpty else { return image }

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

        if pixelProcessingOptions.contains(.denoise),
           let filter = CIFilter(name: "CINoiseReduction") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            filter.setValue(0.02, forKey: "inputNoiseLevel")
            filter.setValue(0.45, forKey: "inputSharpness")
            outputImage = filter.outputImage ?? outputImage
        }

        if pixelProcessingOptions.contains(.smooth),
           let filter = CIFilter(name: "CIGaussianBlur") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            filter.setValue(0.8, forKey: kCIInputRadiusKey)
            outputImage = (filter.outputImage ?? outputImage).cropped(to: originalExtent)
        }

        if pixelProcessingOptions.contains(.contrast),
           let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            filter.setValue(1.15, forKey: kCIInputContrastKey)
            filter.setValue(1.0, forKey: kCIInputSaturationKey)
            outputImage = filter.outputImage ?? outputImage
        }

        if pixelProcessingOptions.contains(.sharpen),
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

final class ImageViewerNSView: NSView {
    enum NavigationDirection: Equatable {
        case previous
        case next
    }

    private let scrollView = NavigationAwareScrollView()
    private let documentContainerView = DoubleClickAwareView()
    private let imageView = RotatingImageView()
    private var imageViews: [RotatingImageView] = []
    private var viewportState = ImageViewportState()
    private var isApplyingProgrammaticMagnification = false
    private var hasNavigatedDuringCurrentTrackpadGesture = false
    private var commandWheelZoomGesture: CommandWheelZoomGesture?
    private var commandWheelZoomEndTask: Task<Void, Never>?
    private var accumulatedTrackpadHorizontalDelta: CGFloat = 0
    private var accumulatedTrackpadVerticalDelta: CGFloat = 0
    private var dragStartLocationInWindow: NSPoint?
    private var lastDragLocationInWindow: NSPoint?
    private var hasDraggedVisibleRect = false
    private var lastAppliedFitRequestID = 0
    private var lastFitMode: FitMode = .all
    private var navigationKeyHoldTask: Task<Void, Never>?
    private var activeNavigationKeyCode: UInt16?
    private var isNavigationKeyHoldIndicatorVisible = false
    private var postProcessingOptions: Set<ImagePostProcessingOption> = []
    private var verticalAutoScrollTask: Task<Void, Never>?
    private var verticalAutoScrollScreenSpeed: CGFloat = 0
    private var lastVerticalAutoScrollDate: Date?

    var onZoomModeChange: ((ZoomMode) -> Void)?
    var onViewportMetricsChange: ((CGFloat, CGFloat, Bool) -> Void)?
    var onNavigateRequest: ((NavigationDirection) -> Void)?
    var onToggleMetadataRequest: (() -> Void)?
    var onNavigationHoldChange: ((Bool) -> Void)?
    var onPostProcessingToggle: ((ImagePostProcessingOption) -> Void)?
    var onPostProcessingClear: (() -> Void)?
    var onVerticalSlideshowReachedEnd: (() -> Void)?
    var onFitZoomOutRequest: (() -> Bool)?
    var displayedImage: NSImage? { imageView.image }
    var displayedImageSize: NSSize {
        Self.displayedContentSize(
            imageSizes: imageViews.map(\.displayedImageSize),
            pageLayout: viewportState.pageLayout
        )
    }
    override var acceptsFirstResponder: Bool { true }

    private struct CommandWheelZoomGesture {
        let startedAtFit: Bool
        var firstSignificantDelta: CGFloat?
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        imageView.imageScaling = .scaleNone

        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.05
        scrollView.maxMagnification = 8.0
        imageViews = [imageView]
        documentContainerView.addSubview(imageView)
        configureHandlers(for: imageView)
        scrollView.documentView = documentContainerView
        scrollView.scrollHandler = { [weak self] event in
            self?.handleScrollGesture(
                verticalDelta: event.scrollingDeltaY,
                horizontalDelta: event.scrollingDeltaX,
                isTrackpad: event.hasPreciseScrollingDeltas,
                phase: event.phase,
                momentumPhase: event.momentumPhase,
                modifierFlags: event.modifierFlags,
                locationInWindow: event.locationInWindow
            ) ?? false
        }
        scrollView.magnifyHandler = { [weak self] event in
            self?.handleTrackpadMagnify(event) ?? false
        }
        scrollView.doubleClickHandler = { [weak self] event in
            self?.handleDoubleClick(event: event) ?? false
        }
        scrollView.keyDownHandler = { [weak self] event in
            self?.handleKeyDown(event) ?? false
        }
        scrollView.keyUpHandler = { [weak self] event in
            self?.handleKeyUp(event) ?? false
        }
        scrollView.dragHandler = { [weak self] phase, event in
            self?.handlePointerDrag(phase, event: event) ?? false
        }
        scrollView.contextMenuHandler = { [weak self] event in
            self?.presentPostProcessingMenu(event: event) ?? false
        }
        documentContainerView.doubleClickHandler = { [weak self] event in
            self?.handleDoubleClick(event: event) ?? false
        }
        documentContainerView.dragHandler = { [weak self] phase, event in
            self?.handlePointerDrag(phase, event: event) ?? false
        }
        documentContainerView.contextMenuHandler = { [weak self] event in
            self?.presentPostProcessingMenu(event: event) ?? false
        }

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
        navigationKeyHoldTask?.cancel()
        verticalAutoScrollTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    override func layout() {
        super.layout()
        scrollView.frame = bounds

        if case let .fit(fitMode) = viewportState.zoomMode {
            applyZoomMode(.fit(fitMode))
        } else {
            updateViewportPresentation(for: scrollView.magnification)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            endNavigationKeyHold()
            return
        }
        window?.makeFirstResponder(scrollView)
    }

    func apply(
        resolvedImage: NSImage?,
        resolvedImages: [NSImage]? = nil,
        imageURL: URL?,
        imageURLs: [URL]? = nil,
        zoomMode: ZoomMode,
        rotationQuarterTurns: Int,
        pageLayout: ViewerPageLayout = .single,
        fitRequestID: Int = 0,
        postProcessingOptions: Set<ImagePostProcessingOption> = [],
        verticalAutoScrollScreenSpeed: CGFloat = 0
    ) {
        let displayURLs = imageURLs ?? imageURL.map { [$0] } ?? []
        let newState = ImageViewportState(
            imageURL: imageURL,
            imageURLs: displayURLs,
            zoomMode: zoomMode,
            rotationQuarterTurns: rotationQuarterTurns,
            pageLayout: pageLayout,
            postProcessingOptions: postProcessingOptions
        )
        let shouldForceFit = zoomMode.isFit && fitRequestID != lastAppliedFitRequestID

        let didChangeImage = newState.imageURL != viewportState.imageURL
            || newState.imageURLs != viewportState.imageURLs
            || newState.pageLayout != viewportState.pageLayout
        let didChangeRotation = newState.rotationQuarterTurns != viewportState.rotationQuarterTurns
        let shouldApplyZoom = shouldForceFit
            || newState.zoomMode != viewportState.zoomMode
            || newState.imageURL != viewportState.imageURL
            || newState.imageURLs != viewportState.imageURLs
            || newState.rotationQuarterTurns != viewportState.rotationQuarterTurns
            || newState.pageLayout != viewportState.pageLayout

        if didChangeImage {
            loadImages(
                resolvedImage: resolvedImage,
                resolvedImages: resolvedImages,
                currentImageURL: imageURL,
                imageURLs: displayURLs
            )
        }

        if didChangeImage || didChangeRotation {
            updateImageRotation(rotationQuarterTurns)
        }

        if newState.postProcessingOptions != viewportState.postProcessingOptions {
            updatePostProcessingOptions(postProcessingOptions)
        }

        viewportState = newState
        if shouldApplyZoom {
            applyZoomMode(zoomMode)
        }

        lastAppliedFitRequestID = fitRequestID
        setVerticalAutoScrollScreenSpeed(verticalAutoScrollScreenSpeed)
    }

    private func configureHandlers(for view: RotatingImageView) {
        view.doubleClickHandler = { [weak self] event in
            self?.handleDoubleClick(event: event) ?? false
        }
        view.dragHandler = { [weak self] phase, event in
            self?.handlePointerDrag(phase, event: event) ?? false
        }
        view.contextMenuHandler = { [weak self] event in
            self?.presentPostProcessingMenu(event: event) ?? false
        }
        view.postProcessingOptions = postProcessingOptions
    }

    private func configureImageViewCount(_ count: Int) {
        let requiredCount = max(1, count)

        while imageViews.count < requiredCount {
            let view = RotatingImageView()
            view.imageScaling = .scaleNone
            configureHandlers(for: view)
            imageViews.append(view)
            documentContainerView.addSubview(view)
        }

        while imageViews.count > requiredCount {
            imageViews.removeLast().removeFromSuperview()
        }
    }

    private func loadImages(resolvedImage: NSImage?, resolvedImages: [NSImage]?, currentImageURL: URL?, imageURLs: [URL]) {
        guard !imageURLs.isEmpty else {
            configureImageViewCount(1)
            imageViews.forEach { imageView in
                imageView.image = nil
                imageView.frame = .zero
            }
            documentContainerView.frame = .zero
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

    private func updateImageRotation(_ rotationQuarterTurns: Int) {
        for imageView in imageViews {
            imageView.rotationQuarterTurns = rotationQuarterTurns
            imageView.frame = NSRect(origin: imageView.frame.origin, size: imageView.displayedImageSize)
        }
    }

    private func updatePostProcessingOptions(_ options: Set<ImagePostProcessingOption>) {
        postProcessingOptions = options
        for imageView in imageViews {
            imageView.postProcessingOptions = options
        }
    }

    private func applyZoomMode(_ zoomMode: ZoomMode) {
        switch zoomMode {
        case let .fit(fitMode):
            applyFitMagnification(fitMode)
        case .actualSize:
            handleMagnificationChange(1.0, isUserInitiated: false)
        case let .custom(scale):
            handleMagnificationChange(scale, isUserInitiated: false)
        }
    }

    private func applyFitMagnification(_ fitMode: FitMode) {
        lastFitMode = fitMode
        let imageSize = displayedImageSize
        let viewportSize = viewportSizeForLayout

        guard imageSize.width > 0,
              imageSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0 else {
            return
        }

        let clampedScale = Self.fitMagnification(
            imageSize: imageSize,
            viewportSize: viewportSize,
            fitMode: fitMode,
            minimumMagnification: scrollView.minMagnification,
            maximumMagnification: scrollView.maxMagnification
        )

        updateViewportPresentation(for: clampedScale)
        isApplyingProgrammaticMagnification = true
        if abs(scrollView.magnification - clampedScale) > 0.0001 {
            scrollView.setMagnification(clampedScale, centeredAt: containerCenterPoint)
        }
        centerVisibleRect(for: clampedScale)
        isApplyingProgrammaticMagnification = false
    }

    private var containerCenterPoint: NSPoint {
        NSPoint(x: documentContainerView.bounds.midX, y: documentContainerView.bounds.midY)
    }

    private var viewportSizeForLayout: NSSize {
        let boundsSize = scrollView.bounds.size
        if boundsSize.width > 0, boundsSize.height > 0 {
            return boundsSize
        }

        return scrollView.contentSize
    }

    func handleMagnificationChange(
        _ magnification: CGFloat,
        isUserInitiated: Bool,
        centeredImagePoint: NSPoint? = nil
    ) {
        let clampedScale = min(max(magnification, scrollView.minMagnification), scrollView.maxMagnification)

        if isUserInitiated {
            guard !isApplyingProgrammaticMagnification else { return }

            let zoomMode = ZoomMode.custom(clampedScale)
            viewportState.zoomMode = zoomMode
            updateViewportPresentation(for: clampedScale)
            let targetDocumentPoint = centeredDocumentPoint(for: centeredImagePoint)
            if abs(scrollView.magnification - clampedScale) > 0.0001 {
                isApplyingProgrammaticMagnification = true
                scrollView.setMagnification(
                    clampedScale,
                    centeredAt: targetDocumentPoint
                )
                isApplyingProgrammaticMagnification = false
            }
            if centeredImagePoint != nil {
                centerVisibleRect(on: targetDocumentPoint, for: clampedScale)
            }
            onZoomModeChange?(zoomMode)
            return
        }

        updateViewportPresentation(for: clampedScale)
        let targetDocumentPoint = centeredDocumentPoint(for: centeredImagePoint)
        if abs(scrollView.magnification - clampedScale) > 0.0001 {
            isApplyingProgrammaticMagnification = true
            scrollView.setMagnification(
                clampedScale,
                centeredAt: targetDocumentPoint
            )
            isApplyingProgrammaticMagnification = false
        }
        if centeredImagePoint != nil {
            centerVisibleRect(on: targetDocumentPoint, for: clampedScale)
        }
    }

    @discardableResult
    func handleDoubleClick(centeredAt imagePoint: NSPoint? = nil) -> Bool {
        handleDoubleClick(centeredAtDocumentPoint: centeredDocumentPoint(for: imagePoint))
    }

    @discardableResult
    private func handleDoubleClick(centeredAtDocumentPoint documentPoint: NSPoint? = nil) -> Bool {
        guard displayedImage != nil else { return false }

        dragStartLocationInWindow = nil
        lastDragLocationInWindow = nil
        hasDraggedVisibleRect = false

        switch viewportState.zoomMode {
        case .fit(_):
            setZoomModeFromUserInput(.actualSize, centeredAtDocumentPoint: documentPoint)
        case .actualSize, .custom:
            setZoomModeFromUserInput(.fit(lastFitMode), centeredAtDocumentPoint: nil)
        }

        return true
    }

    private func handleDoubleClick(event: NSEvent) -> Bool {
        handleDoubleClick(centeredAtDocumentPoint: documentPoint(forWindowLocation: event.locationInWindow))
    }

    private func imagePoint(for event: NSEvent) -> NSPoint {
        imagePoint(forWindowLocation: event.locationInWindow)
    }

    private func imagePoint(forWindowLocation locationInWindow: NSPoint) -> NSPoint {
        let convertedPoint = imageView.convert(locationInWindow, from: nil)
        return Self.clampedPoint(convertedPoint, to: imageView.bounds)
    }

    private func centeredDocumentPoint(for imagePoint: NSPoint?) -> NSPoint {
        guard let imagePoint else { return containerCenterPoint }
        return Self.documentPoint(forImagePoint: imagePoint, imageFrame: imageView.frame)
    }

    private func documentPoint(forWindowLocation locationInWindow: NSPoint) -> NSPoint {
        let convertedPoint = documentContainerView.convert(locationInWindow, from: nil)
        return Self.clampedPoint(convertedPoint, to: documentContainerView.bounds)
    }

    private func currentContentFrame() -> NSRect {
        Self.centeredImageFrame(
            imageSize: displayedImageSize,
            containerSize: documentContainerView.bounds.size
        )
    }

    private func setZoomModeFromUserInput(_ zoomMode: ZoomMode, centeredAt imagePoint: NSPoint? = nil) {
        setZoomModeFromUserInput(zoomMode, centeredAtDocumentPoint: centeredDocumentPoint(for: imagePoint))
    }

    private func setZoomModeFromUserInput(_ zoomMode: ZoomMode, centeredAtDocumentPoint documentPoint: NSPoint? = nil) {
        viewportState.zoomMode = zoomMode
        switch zoomMode {
        case let .fit(fitMode):
            applyZoomMode(.fit(fitMode))
        case .actualSize:
            handleMagnificationChange(1.0, isUserInitiated: false, centeredDocumentPoint: documentPoint)
        case let .custom(scale):
            handleMagnificationChange(scale, isUserInitiated: false, centeredDocumentPoint: documentPoint)
        }
        onZoomModeChange?(zoomMode)
    }

    private func handleMagnificationChange(
        _ magnification: CGFloat,
        isUserInitiated: Bool,
        centeredDocumentPoint documentPoint: NSPoint?
    ) {
        let clampedScale = min(max(magnification, scrollView.minMagnification), scrollView.maxMagnification)

        if isUserInitiated {
            guard !isApplyingProgrammaticMagnification else { return }

            let zoomMode = ZoomMode.custom(clampedScale)
            viewportState.zoomMode = zoomMode
            updateViewportPresentation(for: clampedScale)
            let targetDocumentPoint = documentPoint ?? containerCenterPoint
            if abs(scrollView.magnification - clampedScale) > 0.0001 {
                isApplyingProgrammaticMagnification = true
                scrollView.setMagnification(
                    clampedScale,
                    centeredAt: targetDocumentPoint
                )
                isApplyingProgrammaticMagnification = false
            }
            if documentPoint != nil {
                centerVisibleRect(on: targetDocumentPoint, for: clampedScale)
            }
            onZoomModeChange?(zoomMode)
            return
        }

        updateViewportPresentation(for: clampedScale)
        let targetDocumentPoint = documentPoint ?? containerCenterPoint
        if abs(scrollView.magnification - clampedScale) > 0.0001 {
            isApplyingProgrammaticMagnification = true
            scrollView.setMagnification(
                clampedScale,
                centeredAt: targetDocumentPoint
            )
            isApplyingProgrammaticMagnification = false
        }
        if documentPoint != nil {
            centerVisibleRect(on: targetDocumentPoint, for: clampedScale)
        }
    }

    @objc
    private func scrollViewDidEndLiveMagnify(_ notification: Notification) {
        finishTrackpadMagnifyGesture()
    }

    @discardableResult
    func finishTrackpadMagnifyGesture(animated: Bool = true) -> Bool {
        if snapBackToFitIfNeeded(animated: animated) {
            return true
        }

        handleMagnificationChange(scrollView.magnification, isUserInitiated: true)
        return true
    }

    @discardableResult
    func snapBackToFitIfNeeded(animated: Bool = true) -> Bool {
        guard displayedImage != nil else { return false }

        let fitScale = currentFitMagnification
        guard fitScale.isFinite,
              scrollView.magnification < fitScale - 0.0001 else {
            return false
        }

        let targetZoomMode = ZoomMode.fit(lastFitMode)
        viewportState.zoomMode = targetZoomMode
        updateViewportPresentation(for: fitScale)
        centerVisibleRect(for: fitScale)

        isApplyingProgrammaticMagnification = true
        guard animated else {
            if abs(scrollView.magnification - fitScale) > 0.0001 {
                scrollView.setMagnification(fitScale, centeredAt: containerCenterPoint)
            }
            finishFitSnapBack(targetZoomMode: targetZoomMode, fitScale: fitScale)
            return true
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.32
            context.allowsImplicitAnimation = true
            scrollView.animator().setMagnification(fitScale, centeredAt: containerCenterPoint)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            self.finishFitSnapBack(targetZoomMode: targetZoomMode, fitScale: fitScale)
        }

        return true
    }

    private func finishFitSnapBack(targetZoomMode: ZoomMode, fitScale: CGFloat) {
        centerVisibleRect(for: fitScale)
        isApplyingProgrammaticMagnification = false
        onZoomModeChange?(targetZoomMode)
    }

    @discardableResult
    private func handlePointerDrag(_ phase: PointerDragPhase, event: NSEvent) -> Bool {
        switch phase {
        case .began:
            guard canPanVisibleRect else {
                dragStartLocationInWindow = nil
                lastDragLocationInWindow = nil
                hasDraggedVisibleRect = false
                return false
            }

            dragStartLocationInWindow = event.locationInWindow
            lastDragLocationInWindow = event.locationInWindow
            hasDraggedVisibleRect = false
            return true
        case .changed:
            guard let dragStartLocationInWindow,
                  let lastDragLocationInWindow else { return false }

            let currentLocation = event.locationInWindow
            if !hasDraggedVisibleRect,
               !Self.isBeyondClickDragTolerance(from: dragStartLocationInWindow, to: currentLocation) {
                return false
            }

            panVisibleRect(from: lastDragLocationInWindow, to: currentLocation)
            self.lastDragLocationInWindow = currentLocation
            hasDraggedVisibleRect = true
            return true
        case .ended:
            guard lastDragLocationInWindow != nil else { return false }

            let didDrag = hasDraggedVisibleRect
            dragStartLocationInWindow = nil
            lastDragLocationInWindow = nil
            hasDraggedVisibleRect = false
            return didDrag
        }
    }

    func handleScrollGesture(
        verticalDelta: CGFloat,
        horizontalDelta: CGFloat,
        isTrackpad: Bool = false,
        phase: NSEvent.Phase = [],
        momentumPhase: NSEvent.Phase = [],
        modifierFlags: NSEvent.ModifierFlags = [],
        locationInWindow: NSPoint? = nil
    ) -> Bool {
        if modifierFlags.contains(.command) {
            return handleCommandWheelZoom(
                verticalDelta: verticalDelta,
                horizontalDelta: horizontalDelta,
                locationInWindow: locationInWindow,
                phase: phase,
                momentumPhase: momentumPhase
            )
        }

        switch scrollHandlingResult(
            verticalDelta: verticalDelta,
            horizontalDelta: horizontalDelta,
            isTrackpad: isTrackpad,
            phase: phase,
            momentumPhase: momentumPhase
        ) {
        case .navigate(let direction):
            onNavigateRequest?(direction)
            return true
        case .consumeGesture:
            return true
        case .scrollContent:
            return false
        }
    }

    @discardableResult
    private func handleTrackpadMagnify(_ event: NSEvent) -> Bool {
        guard displayedImage != nil else { return false }

        let isEndingGesture = Self.isEndingMagnifyGesture(phase: event.phase)
        guard abs(event.magnification) >= 0.001 else {
            if isEndingGesture {
                return finishTrackpadMagnifyGesture()
            }

            return true
        }

        if event.magnification < 0,
           viewportState.zoomMode.isFit,
           onFitZoomOutRequest?() == true {
            return true
        }

        hasNavigatedDuringCurrentTrackpadGesture = true
        let nextMagnification = Self.pinchMagnification(
            currentMagnification: scrollView.magnification,
            delta: event.magnification,
            minimumMagnification: scrollView.minMagnification,
            maximumMagnification: scrollView.maxMagnification
        )
        handleAnchoredMagnificationChange(nextMagnification, locationInWindow: event.locationInWindow)

        if isEndingGesture {
            finishTrackpadMagnifyGesture()
        }

        return true
    }

    @discardableResult
    func handleCommandWheelZoom(
        verticalDelta: CGFloat,
        horizontalDelta: CGFloat,
        locationInWindow: NSPoint? = nil,
        phase: NSEvent.Phase = [],
        momentumPhase: NSEvent.Phase = []
    ) -> Bool {
        guard displayedImage != nil else { return false }

        beginCommandWheelZoomGestureIfNeeded(phase: phase)
        let isEndingGesture = Self.isEndingScrollGesture(phase: phase, momentumPhase: momentumPhase)
        let zoomDelta = abs(verticalDelta) >= abs(horizontalDelta) ? verticalDelta : -horizontalDelta
        guard abs(zoomDelta) >= 0.1 else {
            if isEndingGesture {
                finishCommandWheelZoomGesture()
            }
            return true
        }

        if commandWheelZoomGesture?.firstSignificantDelta == nil {
            commandWheelZoomGesture?.firstSignificantDelta = zoomDelta
        }

        if zoomDelta < 0,
           commandWheelZoomGesture?.startedAtFit == true,
           commandWheelZoomGesture?.firstSignificantDelta.map({ $0 < 0 }) == true,
           viewportState.zoomMode.isFit,
           onFitZoomOutRequest?() == true {
            resetCommandWheelZoomGesture()
            return true
        }

        let nextMagnification = Self.commandWheelMagnification(
            currentMagnification: scrollView.magnification,
            delta: zoomDelta,
            minimumMagnification: scrollView.minMagnification,
            maximumMagnification: scrollView.maxMagnification
        )
        if let locationInWindow {
            handleAnchoredMagnificationChange(nextMagnification, locationInWindow: locationInWindow)
        } else {
            handleMagnificationChange(nextMagnification, isUserInitiated: true)
        }

        if isEndingGesture {
            finishCommandWheelZoomGesture()
        } else {
            scheduleCommandWheelZoomEnd()
        }
        return true
    }

    @discardableResult
    private func finishCommandWheelZoomGesture(animated: Bool = true) -> Bool {
        let hadGesture = commandWheelZoomGesture != nil
        resetCommandWheelZoomGesture()
        return snapBackToFitIfNeeded(animated: animated) || hadGesture
    }

    private func beginCommandWheelZoomGestureIfNeeded(phase: NSEvent.Phase) {
        if phase.contains(.began) || phase.contains(.mayBegin) || commandWheelZoomGesture == nil {
            commandWheelZoomEndTask?.cancel()
            commandWheelZoomEndTask = nil
            commandWheelZoomGesture = CommandWheelZoomGesture(
                startedAtFit: viewportState.zoomMode.isFit,
                firstSignificantDelta: nil
            )
        }
    }

    private func scheduleCommandWheelZoomEnd() {
        commandWheelZoomEndTask?.cancel()
        commandWheelZoomEndTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            self?.finishCommandWheelZoomGesture()
        }
    }

    private func resetCommandWheelZoomGesture() {
        commandWheelZoomEndTask?.cancel()
        commandWheelZoomEndTask = nil
        commandWheelZoomGesture = nil
    }

    private func handleAnchoredMagnificationChange(_ magnification: CGFloat, locationInWindow: NSPoint) {
        guard !isApplyingProgrammaticMagnification else { return }

        let clampedScale = min(max(magnification, scrollView.minMagnification), scrollView.maxMagnification)
        let currentDocumentPoint = documentPoint(forWindowLocation: locationInWindow)
        let contentFrameBeforeZoom = currentContentFrame()
        let anchoredContentOffset = Self.anchoredContentOffset(
            documentPoint: currentDocumentPoint,
            contentFrame: contentFrameBeforeZoom
        )
        let anchorUnitPoint = Self.anchorUnitPoint(
            anchorDocumentPoint: currentDocumentPoint,
            visibleRect: scrollView.contentView.bounds
        )
        let zoomMode = ZoomMode.custom(clampedScale)

        viewportState.zoomMode = zoomMode
        updateViewportPresentation(for: clampedScale)

        let updatedDocumentPoint = Self.documentPoint(
            contentOffset: anchoredContentOffset,
            contentFrame: currentContentFrame()
        )
        let targetOrigin = Self.visibleRectOrigin(
            anchoring: updatedDocumentPoint,
            at: anchorUnitPoint,
            containerSize: documentContainerView.bounds.size,
            viewportSize: viewportSizeForLayout,
            magnification: clampedScale
        )

        isApplyingProgrammaticMagnification = true
        if abs(scrollView.magnification - clampedScale) > 0.0001 {
            scrollView.setMagnification(clampedScale, centeredAt: updatedDocumentPoint)
        }
        scrollView.contentView.scroll(to: targetOrigin)
        scrollView.reflectScrolledClipView(scrollView.contentView)
        isApplyingProgrammaticMagnification = false

        onZoomModeChange?(zoomMode)
    }

    @discardableResult
    private func presentPostProcessingMenu(event: NSEvent) -> Bool {
        guard displayedImage != nil else { return false }

        let menu = NSMenu(title: "Post Processing")
        for option in ImagePostProcessingOption.allCases {
            let item = NSMenuItem(title: option.title, action: #selector(togglePostProcessingMenuItem(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = option.rawValue
            item.state = postProcessingOptions.contains(option) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let clearItem = NSMenuItem(title: "Clear All", action: #selector(clearPostProcessingMenuItem(_:)), keyEquivalent: "")
        clearItem.target = self
        clearItem.isEnabled = !postProcessingOptions.isEmpty
        menu.addItem(clearItem)

        let point = convert(event.locationInWindow, from: nil)
        menu.popUp(positioning: nil, at: point, in: self)
        return true
    }

    @objc
    private func togglePostProcessingMenuItem(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let option = ImagePostProcessingOption(rawValue: rawValue) else { return }

        onPostProcessingToggle?(option)
    }

    @objc
    private func clearPostProcessingMenuItem(_ sender: NSMenuItem) {
        onPostProcessingClear?()
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        if event.keyCode == 48 {
            onToggleMetadataRequest?()
            return true
        }

        guard let direction = Self.navigationDirection(forKeyCode: event.keyCode) else {
            return false
        }

        if !event.isARepeat {
            beginNavigationKeyHold(for: event.keyCode)
        }
        onNavigateRequest?(direction)
        return true
    }

    private func handleKeyUp(_ event: NSEvent) -> Bool {
        guard Self.navigationDirection(forKeyCode: event.keyCode) != nil else {
            return false
        }

        if activeNavigationKeyCode == event.keyCode {
            endNavigationKeyHold()
        }
        return true
    }

    private func beginNavigationKeyHold(for keyCode: UInt16) {
        activeNavigationKeyCode = keyCode
        navigationKeyHoldTask?.cancel()
        isNavigationKeyHoldIndicatorVisible = false
        navigationKeyHoldTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            isNavigationKeyHoldIndicatorVisible = true
            onNavigationHoldChange?(true)
        }
    }

    private func endNavigationKeyHold() {
        navigationKeyHoldTask?.cancel()
        navigationKeyHoldTask = nil
        activeNavigationKeyCode = nil

        if isNavigationKeyHoldIndicatorVisible {
            isNavigationKeyHoldIndicatorVisible = false
            onNavigationHoldChange?(false)
        }
    }

    private enum ScrollHandlingResult: Equatable {
        case navigate(NavigationDirection)
        case consumeGesture
        case scrollContent
    }

    private func scrollHandlingResult(
        verticalDelta: CGFloat,
        horizontalDelta: CGFloat,
        isTrackpad: Bool,
        phase: NSEvent.Phase,
        momentumPhase: NSEvent.Phase
    ) -> ScrollHandlingResult {
        if isTrackpad {
            resetTrackpadGestureIfNeeded(phase: phase, momentumPhase: momentumPhase)
            accumulatedTrackpadHorizontalDelta += horizontalDelta
            accumulatedTrackpadVerticalDelta += verticalDelta
            return trackpadScrollHandlingResult(
                verticalDelta: verticalDelta,
                horizontalDelta: horizontalDelta
            )
        }

        return mouseScrollHandlingResult(verticalDelta: verticalDelta, horizontalDelta: horizontalDelta)
    }

    private func mouseScrollHandlingResult(verticalDelta: CGFloat, horizontalDelta: CGFloat) -> ScrollHandlingResult {
        if abs(verticalDelta) > abs(horizontalDelta),
           !isEntireImageVisible,
           !isImageScrollableVertically {
            return .consumeGesture
        }

        guard isEntireImageVisible else {
            return .scrollContent
        }

        guard abs(verticalDelta) > abs(horizontalDelta), abs(verticalDelta) >= 0.5 else {
            return .scrollContent
        }

        return verticalDelta > 0 ? .navigate(.previous) : .navigate(.next)
    }

    private func trackpadScrollHandlingResult(verticalDelta: CGFloat, horizontalDelta: CGFloat) -> ScrollHandlingResult {
        if hasNavigatedDuringCurrentTrackpadGesture {
            return .consumeGesture
        }

        let horizontalGesture = abs(accumulatedTrackpadHorizontalDelta)
        let verticalGesture = abs(accumulatedTrackpadVerticalDelta)
        if horizontalGesture >= 24, horizontalGesture > verticalGesture * 1.35 {
            hasNavigatedDuringCurrentTrackpadGesture = true
            return accumulatedTrackpadHorizontalDelta > 0 ? .navigate(.previous) : .navigate(.next)
        }

        if abs(verticalDelta) >= 0.5, !isImageScrollableVertically {
            return .consumeGesture
        }

        if abs(horizontalDelta) >= 0.5, !isImageScrollableHorizontally {
            return .consumeGesture
        }

        guard abs(verticalDelta) >= 0.5 || abs(horizontalDelta) >= 0.5 else {
            return .scrollContent
        }

        return .scrollContent
    }

    private func resetTrackpadGestureIfNeeded(phase: NSEvent.Phase, momentumPhase: NSEvent.Phase) {
        if phase.contains(.began) || phase.contains(.mayBegin) {
            hasNavigatedDuringCurrentTrackpadGesture = false
            accumulatedTrackpadHorizontalDelta = 0
            accumulatedTrackpadVerticalDelta = 0
        }

        if phase.contains(.ended)
            || phase.contains(.cancelled)
            || momentumPhase.contains(.ended)
            || momentumPhase.contains(.cancelled) {
            hasNavigatedDuringCurrentTrackpadGesture = false
            accumulatedTrackpadHorizontalDelta = 0
            accumulatedTrackpadVerticalDelta = 0
        }
    }

    private var currentFitMagnification: CGFloat {
        Self.fitMagnification(
            imageSize: displayedImageSize,
            viewportSize: viewportSizeForLayout,
            fitMode: lastFitMode,
            minimumMagnification: scrollView.minMagnification,
            maximumMagnification: scrollView.maxMagnification
        )
    }

    private func updateViewportPresentation(for displayedMagnification: CGFloat) {
        let imageSize = displayedImageSize
        let viewportSize = viewportSizeForLayout
        let containerSize = Self.documentContainerSize(
            imageSize: imageSize,
            viewportSize: viewportSize,
            magnification: displayedMagnification
        )

        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        documentContainerView.frame = NSRect(origin: .zero, size: containerSize)
        let imageFrames = Self.imageFrames(
            imageSizes: imageViews.map(\.displayedImageSize),
            containerSize: containerSize,
            pageLayout: viewportState.pageLayout
        )
        for (index, frame) in imageFrames.enumerated() where index < imageViews.count {
            imageViews[index].frame = frame
        }

        onViewportMetricsChange?(
            displayedMagnification,
            currentFitMagnification,
            isEntireImageVisible
        )
    }

    private var isEntireImageVisible: Bool {
        let imageSize = displayedImageSize
        let viewportSize = viewportSizeForLayout

        guard imageSize.width > 0,
              imageSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0 else {
            return true
        }

        let scaledWidth = imageSize.width * scrollView.magnification
        let scaledHeight = imageSize.height * scrollView.magnification
        return scaledWidth <= viewportSize.width + 0.0001
            && scaledHeight <= viewportSize.height + 0.0001
    }

    private var isImageScrollableHorizontally: Bool {
        Self.imageScrollability(
            imageSize: displayedImageSize,
            viewportSize: viewportSizeForLayout,
            magnification: scrollView.magnification
        ).horizontal
    }

    private var isImageScrollableVertically: Bool {
        Self.imageScrollability(
            imageSize: displayedImageSize,
            viewportSize: viewportSizeForLayout,
            magnification: scrollView.magnification
        ).vertical
    }

    private func centerVisibleRect(for magnification: CGFloat) {
        let centeredOrigin = Self.centeredVisibleRectOrigin(
            containerSize: documentContainerView.bounds.size,
            viewportSize: viewportSizeForLayout,
            magnification: magnification
        )

        scrollView.contentView.scroll(to: centeredOrigin)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func centerVisibleRect(on documentPoint: NSPoint, for magnification: CGFloat) {
        let centeredOrigin = Self.visibleRectOrigin(
            centeredOn: documentPoint,
            containerSize: documentContainerView.bounds.size,
            viewportSize: viewportSizeForLayout,
            magnification: magnification
        )

        scrollView.contentView.scroll(to: centeredOrigin)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private var canPanVisibleRect: Bool {
        isImageScrollableHorizontally || isImageScrollableVertically
    }

    private func panVisibleRect(from previousLocation: NSPoint, to currentLocation: NSPoint) {
        let dragDelta = NSPoint(
            x: currentLocation.x - previousLocation.x,
            y: currentLocation.y - previousLocation.y
        )
        let nextOrigin = Self.pannedVisibleRectOrigin(
            currentOrigin: scrollView.contentView.bounds.origin,
            documentSize: documentContainerView.bounds.size,
            viewportSize: viewportSizeForLayout,
            magnification: scrollView.magnification,
            dragDelta: dragDelta
        )

        scrollView.contentView.scroll(to: nextOrigin)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func setVerticalAutoScrollScreenSpeed(_ screenSpeed: CGFloat) {
        let clampedSpeed = max(screenSpeed, 0)
        guard abs(verticalAutoScrollScreenSpeed - clampedSpeed) > 0.01 else { return }

        verticalAutoScrollScreenSpeed = clampedSpeed
        updateVerticalAutoScrollTimer()
    }

    private func updateVerticalAutoScrollTimer() {
        verticalAutoScrollTask?.cancel()
        verticalAutoScrollTask = nil
        lastVerticalAutoScrollDate = nil

        guard verticalAutoScrollScreenSpeed > 0, viewportState.pageLayout == .verticalStrip else { return }

        verticalAutoScrollTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.performVerticalAutoScroll()
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func performVerticalAutoScroll() {
        guard verticalAutoScrollScreenSpeed > 0 else { return }

        let now = Date()
        let elapsed = lastVerticalAutoScrollDate.map { now.timeIntervalSince($0) } ?? (1.0 / 60.0)
        lastVerticalAutoScrollDate = now

        let currentOrigin = scrollView.contentView.bounds.origin
        let nextOrigin = Self.verticalAutoScrollOrigin(
            currentOrigin: currentOrigin,
            documentSize: documentContainerView.bounds.size,
            viewportSize: viewportSizeForLayout,
            magnification: scrollView.magnification,
            screenPointDelta: verticalAutoScrollScreenSpeed * elapsed
        )

        guard abs(nextOrigin.y - currentOrigin.y) > 0.0001 || abs(nextOrigin.x - currentOrigin.x) > 0.0001 else {
            setVerticalAutoScrollScreenSpeed(0)
            onVerticalSlideshowReachedEnd?()
            return
        }

        scrollView.contentView.scroll(to: nextOrigin)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

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
