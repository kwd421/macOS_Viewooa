import AppKit

final class ImageViewerNSView: NSView {
    enum NavigationDirection: Equatable {
        case previous
        case next
    }

    private let scrollView = NavigationAwareScrollView()
    private let documentContainerView = DoubleClickAwareView()
    private var viewportState = ImageViewportState()
    private let commandWheelZoomCoordinator = ImageViewerCommandWheelZoomCoordinator()
    private let trackpadScrollCoordinator = ImageViewerTrackpadScrollCoordinator()
    private let pointerDragCoordinator = ImageViewerPointerDragCoordinator()
    private let pointerLockController = ImageViewerPointerLockController()
    private var lastAppliedFitRequestID = 0
    private var lastFitMode: FitMode = .all
    private let keyboardCoordinator = ImageViewerKeyboardCoordinator()
    private let postProcessingMenuPresenter = ImageViewerPostProcessingMenuPresenter()
    private let verticalAutoScrollCoordinator = ImageViewerVerticalAutoScrollCoordinator()
    private var postProcessingOptions: Set<ImagePostProcessingOption> = []
    private lazy var imageStack = ImageViewerImageStack(
        containerView: documentContainerView,
        configureHandlers: { [weak self] view in
            self?.configureHandlers(for: view)
        }
    )
    private lazy var viewportPresenter = ImageViewerViewportPresenter(
        scrollView: scrollView,
        documentContainerView: documentContainerView,
        imageStack: imageStack
    )
    private lazy var zoomAnimator = ImageViewerZoomAnimator(scrollView: scrollView)

    var onZoomModeChange: ((ZoomMode) -> Void)?
    var onViewportMetricsChange: ((CGFloat, CGFloat, Bool) -> Void)?
    var onNavigateRequest: ((NavigationDirection) -> Void)?
    var onToggleMetadataRequest: (() -> Void)?
    var onNavigationHoldChange: ((Bool) -> Void)?
    var onPostProcessingToggle: ((ImagePostProcessingOption) -> Void)?
    var onPostProcessingClear: (() -> Void)?
    var onVerticalSlideshowReachedEnd: (() -> Void)?
    var onFitZoomOutRequest: (() -> Bool)?
    var displayedImage: NSImage? { imageStack.displayedImage }
    var displayedImageSize: NSSize {
        viewportPresenter.displayedContentSize(pageLayout: viewportState.pageLayout)
    }
    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.05
        scrollView.maxMagnification = 8.0
        _ = imageStack
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
            pointerLockController.end()
            keyboardCoordinator.endHold { onNavigationHoldChange?($0) }
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
            imageStack.loadImages(
                resolvedImage: resolvedImage,
                resolvedImages: resolvedImages,
                currentImageURL: imageURL,
                imageURLs: displayURLs
            )
        }

        if didChangeImage || didChangeRotation {
            imageStack.updateRotation(rotationQuarterTurns)
        }

        if newState.postProcessingOptions != viewportState.postProcessingOptions {
            self.postProcessingOptions = postProcessingOptions
            imageStack.updatePostProcessingOptions(postProcessingOptions)
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

        let targetOrigin = Self.centeredVisibleRectOrigin(
            containerSize: Self.documentContainerSize(
                imageSize: imageSize,
                viewportSize: viewportSize,
                magnification: clampedScale
            ),
            viewportSize: viewportSizeForLayout,
            magnification: clampedScale
        )
        applyProgrammaticMagnification(
            clampedScale,
            centeredAt: viewportPresenter.containerCenterPoint,
            finalOrigin: targetOrigin
        )
    }

    private var viewportSizeForLayout: NSSize {
        viewportPresenter.viewportSizeForLayout
    }

    func handleMagnificationChange(
        _ magnification: CGFloat,
        isUserInitiated: Bool,
        centeredImagePoint: NSPoint? = nil
    ) {
        let clampedScale = min(max(magnification, scrollView.minMagnification), scrollView.maxMagnification)

        if isUserInitiated {
            guard !zoomAnimator.isApplyingProgrammaticMagnification else { return }

            let zoomMode = ZoomMode.custom(clampedScale)
            viewportState.zoomMode = zoomMode
            updateViewportPresentation(for: clampedScale)
            let targetDocumentPoint = centeredDocumentPoint(for: centeredImagePoint)
            if abs(scrollView.magnification - clampedScale) > 0.0001 {
                zoomAnimator.performProgrammaticMagnification {
                    scrollView.setMagnification(
                        clampedScale,
                        centeredAt: targetDocumentPoint
                    )
                }
            }
            if centeredImagePoint != nil {
                centerVisibleRect(on: targetDocumentPoint, for: clampedScale)
            }
            onZoomModeChange?(zoomMode)
            return
        }

        updateViewportPresentation(for: clampedScale)
        let targetDocumentPoint = centeredDocumentPoint(for: centeredImagePoint)
        let targetOrigin = centeredImagePoint.map { _ in
            Self.visibleRectOrigin(
                centeredOn: targetDocumentPoint,
                containerSize: documentContainerView.bounds.size,
                viewportSize: viewportSizeForLayout,
                magnification: clampedScale
            )
        }
        applyProgrammaticMagnification(
            clampedScale,
            centeredAt: targetDocumentPoint,
            finalOrigin: targetOrigin
        )
    }

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

    private func handleDoubleClick(event: NSEvent) -> Bool {
        handleDoubleClick(anchoredAtDocumentPoint: documentPoint(forWindowLocation: event.locationInWindow))
    }

    private func imagePoint(for event: NSEvent) -> NSPoint {
        imagePoint(forWindowLocation: event.locationInWindow)
    }

    private func imagePoint(forWindowLocation locationInWindow: NSPoint) -> NSPoint {
        let convertedPoint = imageStack.convertWindowPointToPrimaryImage(locationInWindow)
        return Self.clampedPoint(convertedPoint, to: imageStack.primaryImageBounds)
    }

    private func centeredDocumentPoint(for imagePoint: NSPoint?) -> NSPoint {
        guard let imagePoint else { return viewportPresenter.containerCenterPoint }
        return Self.documentPoint(forImagePoint: imagePoint, imageFrame: imageStack.primaryImageFrame)
    }

    private func documentPoint(forWindowLocation locationInWindow: NSPoint) -> NSPoint {
        let convertedPoint = documentContainerView.convert(locationInWindow, from: nil)
        return Self.clampedPoint(convertedPoint, to: documentContainerView.bounds)
    }

    private func currentContentFrame() -> NSRect {
        viewportPresenter.currentContentFrame(displayedImageSize: displayedImageSize)
    }

    private func setZoomModeFromUserInput(_ zoomMode: ZoomMode, centeredAt imagePoint: NSPoint? = nil) {
        viewportState.zoomMode = zoomMode
        switch zoomMode {
        case let .fit(fitMode):
            applyZoomMode(.fit(fitMode))
        case .actualSize:
            handleMagnificationChange(1.0, isUserInitiated: false, centeredImagePoint: imagePoint)
        case let .custom(scale):
            handleMagnificationChange(scale, isUserInitiated: false, centeredImagePoint: imagePoint)
        }
        onZoomModeChange?(zoomMode)
    }

    private func setZoomModeFromUserInput(
        _ zoomMode: ZoomMode,
        anchoredContentOffset contentOffset: NSPoint,
        anchorUnitPoint: NSPoint
    ) {
        viewportState.zoomMode = zoomMode
        switch zoomMode {
        case let .fit(fitMode):
            applyZoomMode(.fit(fitMode))
        case .actualSize:
            applyAnchoredProgrammaticMagnification(
                1.0,
                contentOffset: contentOffset,
                anchorUnitPoint: anchorUnitPoint
            )
        case let .custom(scale):
            applyAnchoredProgrammaticMagnification(
                scale,
                contentOffset: contentOffset,
                anchorUnitPoint: anchorUnitPoint
            )
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
            guard !zoomAnimator.isApplyingProgrammaticMagnification else { return }

            let zoomMode = ZoomMode.custom(clampedScale)
            viewportState.zoomMode = zoomMode
            updateViewportPresentation(for: clampedScale)
            let targetDocumentPoint = documentPoint ?? viewportPresenter.containerCenterPoint
            if abs(scrollView.magnification - clampedScale) > 0.0001 {
                zoomAnimator.performProgrammaticMagnification {
                    scrollView.setMagnification(
                        clampedScale,
                        centeredAt: targetDocumentPoint
                    )
                }
            }
            if documentPoint != nil {
                centerVisibleRect(on: targetDocumentPoint, for: clampedScale)
            }
            onZoomModeChange?(zoomMode)
            return
        }

        updateViewportPresentation(for: clampedScale)
        let targetDocumentPoint = documentPoint ?? viewportPresenter.containerCenterPoint
        let targetOrigin = documentPoint.map { _ in
            Self.visibleRectOrigin(
                centeredOn: targetDocumentPoint,
                containerSize: documentContainerView.bounds.size,
                viewportSize: viewportSizeForLayout,
                magnification: clampedScale
            )
        }
        applyProgrammaticMagnification(
            clampedScale,
            centeredAt: targetDocumentPoint,
            finalOrigin: targetOrigin
        )
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
        let targetOrigin = Self.centeredVisibleRectOrigin(
            containerSize: Self.documentContainerSize(
                imageSize: displayedImageSize,
                viewportSize: viewportSizeForLayout,
                magnification: fitScale
            ),
            viewportSize: viewportSizeForLayout,
            magnification: fitScale
        )
        viewportState.zoomMode = targetZoomMode

        guard animated else {
            updateViewportPresentation(for: fitScale)
            zoomAnimator.applyProgrammaticMagnification(
                fitScale,
                centeredAt: viewportPresenter.containerCenterPoint,
                finalOrigin: targetOrigin,
                canAnimateInWindow: false,
                updatePresentation: { [weak self] in
                    self?.updateViewportPresentation(for: $0)
                }
            )
            onZoomModeChange?(targetZoomMode)
            return true
        }

        applyProgrammaticMagnification(
            fitScale,
            centeredAt: viewportPresenter.containerCenterPoint,
            finalOrigin: targetOrigin
        )
        onZoomModeChange?(targetZoomMode)

        return true
    }

    @discardableResult
    private func handlePointerDrag(_ phase: PointerDragPhase, event: NSEvent) -> Bool {
        pointerDragCoordinator.handle(
            phase,
            event: event,
            canPan: canPanVisibleRect,
            onPan: { [weak self] previousLocation, currentLocation in
                self?.panVisibleRect(from: previousLocation, to: currentLocation)
            },
            onPointerLockBegin: { [weak self] startLocation in
                guard let self else { return }
                pointerLockController.begin(atWindowLocation: startLocation, in: window)
            },
            onPointerLockEnd: { [weak self] in
                self?.pointerLockController.end()
            }
        )
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

        return trackpadScrollCoordinator.handleMagnify(
            event: event,
            currentMagnification: scrollView.magnification,
            minimumMagnification: scrollView.minMagnification,
            maximumMagnification: scrollView.maxMagnification,
            isCurrentlyFit: viewportState.zoomMode.isFit,
            requestFitZoomOut: { [weak self] in
                self?.onFitZoomOutRequest?() == true
            },
            applyMagnification: { [weak self] magnification, locationInWindow in
                self?.handleAnchoredMagnificationChange(magnification, locationInWindow: locationInWindow)
            },
            finishGesture: { [weak self] in
                _ = self?.finishTrackpadMagnifyGesture()
            }
        )
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

        return commandWheelZoomCoordinator.handleZoom(
            verticalDelta: verticalDelta,
            horizontalDelta: horizontalDelta,
            locationInWindow: locationInWindow,
            phase: phase,
            momentumPhase: momentumPhase,
            currentMagnification: scrollView.magnification,
            minimumMagnification: scrollView.minMagnification,
            maximumMagnification: scrollView.maxMagnification,
            isCurrentlyFit: viewportState.zoomMode.isFit,
            requestFitZoomOut: { [weak self] in
                self?.onFitZoomOutRequest?() == true
            },
            applyMagnification: { [weak self] magnification, locationInWindow in
                if let locationInWindow {
                    self?.handleAnchoredMagnificationChange(magnification, locationInWindow: locationInWindow)
                } else {
                    self?.handleMagnificationChange(magnification, isUserInitiated: true)
                }
            },
            finishGesture: { [weak self] in
                _ = self?.finishCommandWheelZoomGesture()
            }
        )
    }

    @discardableResult
    private func finishCommandWheelZoomGesture(animated: Bool = true) -> Bool {
        let hadGesture = commandWheelZoomCoordinator.finish()
        return snapBackToFitIfNeeded(animated: animated) || hadGesture
    }

    private func handleAnchoredMagnificationChange(_ magnification: CGFloat, locationInWindow: NSPoint) {
        guard !zoomAnimator.isApplyingProgrammaticMagnification else { return }

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

        zoomAnimator.performProgrammaticMagnification {
            if abs(scrollView.magnification - clampedScale) > 0.0001 {
                scrollView.setMagnification(clampedScale, centeredAt: updatedDocumentPoint)
            }
            scrollView.contentView.scroll(to: targetOrigin)
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }

        onZoomModeChange?(zoomMode)
    }

    @discardableResult
    private func presentPostProcessingMenu(event: NSEvent) -> Bool {
        guard displayedImage != nil else { return false }

        postProcessingMenuPresenter.present(
            in: self,
            atWindowLocation: event.locationInWindow,
            options: postProcessingOptions,
            onToggle: { [weak self] option in
                self?.onPostProcessingToggle?(option)
            },
            onClear: { [weak self] in
                self?.onPostProcessingClear?()
            }
        )
        return true
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        keyboardCoordinator.handleKeyDown(
            event,
            onToggleMetadata: { [weak self] in
                self?.onToggleMetadataRequest?()
            },
            onNavigate: { [weak self] direction in
                self?.onNavigateRequest?(direction)
            },
            onHoldChange: { [weak self] isHolding in
                self?.onNavigationHoldChange?(isHolding)
            }
        )
    }

    private func handleKeyUp(_ event: NSEvent) -> Bool {
        keyboardCoordinator.handleKeyUp(event) { onNavigationHoldChange?($0) }
    }

    private func scrollHandlingResult(
        verticalDelta: CGFloat,
        horizontalDelta: CGFloat,
        isTrackpad: Bool,
        phase: NSEvent.Phase,
        momentumPhase: NSEvent.Phase
    ) -> ImageViewerScrollHandlingResult {
        if isTrackpad {
            return trackpadScrollCoordinator.handlingResult(
                verticalDelta: verticalDelta,
                horizontalDelta: horizontalDelta,
                phase: phase,
                momentumPhase: momentumPhase,
                isVerticallyScrollable: isImageScrollableVertically,
                isHorizontallyScrollable: isImageScrollableHorizontally
            )
        }

        return ImageViewerTrackpadScrollCoordinator.mouseHandlingResult(
            verticalDelta: verticalDelta,
            horizontalDelta: horizontalDelta,
            isEntireImageVisible: isEntireImageVisible,
            isVerticallyScrollable: isImageScrollableVertically
        )
    }

    private var currentFitMagnification: CGFloat {
        viewportPresenter.currentFitMagnification(
            displayedImageSize: displayedImageSize,
            fitMode: lastFitMode
        )
    }

    private func updateViewportPresentation(for displayedMagnification: CGFloat) {
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

    private func applyProgrammaticMagnification(
        _ magnification: CGFloat,
        centeredAt documentPoint: NSPoint,
        finalOrigin: NSPoint? = nil
    ) {
        zoomAnimator.applyProgrammaticMagnification(
            magnification,
            centeredAt: documentPoint,
            finalOrigin: finalOrigin,
            canAnimateInWindow: window != nil,
            updatePresentation: { [weak self] in
                self?.updateViewportPresentation(for: $0)
            }
        )
    }

    private func applyAnchoredProgrammaticMagnification(
        _ magnification: CGFloat,
        contentOffset: NSPoint,
        anchorUnitPoint: NSPoint
    ) {
        zoomAnimator.applyAnchoredProgrammaticMagnification(
            magnification,
            contentOffset: contentOffset,
            anchorUnitPoint: anchorUnitPoint,
            canAnimateInWindow: window != nil,
            updatePresentation: { [weak self] in
                self?.updateViewportPresentation(for: $0)
            },
            targetForMagnification: { [weak self] currentMagnification in
                guard let self else {
                    return (documentPoint: .zero, origin: .zero)
                }
                return self.anchoredZoomTarget(
                    contentOffset: contentOffset,
                    anchorUnitPoint: anchorUnitPoint,
                    magnification: currentMagnification
                )
            }
        )
    }

    private func anchoredZoomTarget(
        contentOffset: NSPoint,
        anchorUnitPoint: NSPoint,
        magnification: CGFloat
    ) -> (documentPoint: NSPoint, origin: NSPoint) {
        let updatedDocumentPoint = Self.documentPoint(
            contentOffset: contentOffset,
            contentFrame: currentContentFrame()
        )
        let targetOrigin = Self.visibleRectOrigin(
            anchoring: updatedDocumentPoint,
            at: anchorUnitPoint,
            containerSize: documentContainerView.bounds.size,
            viewportSize: viewportSizeForLayout,
            magnification: magnification
        )

        return (updatedDocumentPoint, targetOrigin)
    }

    private var isEntireImageVisible: Bool {
        viewportPresenter.isEntireImageVisible(displayedImageSize: displayedImageSize)
    }

    private var isImageScrollableHorizontally: Bool {
        viewportPresenter.imageScrollability(displayedImageSize: displayedImageSize).horizontal
    }

    private var isImageScrollableVertically: Bool {
        viewportPresenter.imageScrollability(displayedImageSize: displayedImageSize).vertical
    }

    private func centerVisibleRect(for magnification: CGFloat) {
        viewportPresenter.centerVisibleRect(for: magnification)
    }

    private func centerVisibleRect(on documentPoint: NSPoint, for magnification: CGFloat) {
        viewportPresenter.centerVisibleRect(on: documentPoint, for: magnification)
    }

    private var canPanVisibleRect: Bool {
        isImageScrollableHorizontally || isImageScrollableVertically
    }

    private func panVisibleRect(from previousLocation: NSPoint, to currentLocation: NSPoint) {
        viewportPresenter.panVisibleRect(from: previousLocation, to: currentLocation)
    }

    private func setVerticalAutoScrollScreenSpeed(_ screenSpeed: CGFloat) {
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

    private func performVerticalAutoScroll(elapsed: TimeInterval, screenSpeed: CGFloat) -> Bool {
        viewportPresenter.performVerticalAutoScroll(elapsed: elapsed, screenSpeed: screenSpeed)
    }

}
