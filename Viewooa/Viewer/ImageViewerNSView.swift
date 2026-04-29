import AppKit

final class ImageViewerNSView: NSView {
    enum NavigationDirection: Equatable {
        case previous
        case next
    }

    let scrollView = NavigationAwareScrollView()
    let documentContainerView = DoubleClickAwareView()
    var viewportState = ImageViewportState()
    let commandWheelZoomCoordinator = ImageViewerCommandWheelZoomCoordinator()
    let trackpadScrollCoordinator = ImageViewerTrackpadScrollCoordinator()
    let pointerDragCoordinator = ImageViewerPointerDragCoordinator()
    let pointerLockController = ImageViewerPointerLockController()
    var lastAppliedFitRequestID = 0
    var lastFitMode: FitMode = .all
    let keyboardCoordinator = ImageViewerKeyboardCoordinator()
    let postProcessingMenuPresenter = ImageViewerPostProcessingMenuPresenter()
    let verticalAutoScrollCoordinator = ImageViewerVerticalAutoScrollCoordinator()
    var postProcessingOptions: Set<ImagePostProcessingOption> = []
    lazy var imageStack = ImageViewerImageStack(
        containerView: documentContainerView,
        configureHandlers: { [weak self] view in
            self?.configureHandlers(for: view)
        }
    )
    lazy var viewportPresenter = ImageViewerViewportPresenter(
        scrollView: scrollView,
        documentContainerView: documentContainerView,
        imageStack: imageStack
    )
    lazy var zoomAnimator = ImageViewerZoomAnimator(scrollView: scrollView)

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
        configureViewerInfrastructure()
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
            applyZoomMode(.fit(fitMode), animated: false)
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
            let shouldAnimateZoom = !(didChangeImage && zoomMode.isFit)
            applyZoomMode(zoomMode, animated: shouldAnimateZoom)
        }

        lastAppliedFitRequestID = fitRequestID
        setVerticalAutoScrollScreenSpeed(verticalAutoScrollScreenSpeed)
    }

}
