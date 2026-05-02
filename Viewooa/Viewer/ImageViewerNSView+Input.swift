import AppKit

extension ImageViewerNSView {
    static let interactiveNavigationPageGap: CGFloat = 28
    private static let interactiveNavigationAnimationKey = "Viewooa.interactiveNavigation.transform"

    func configureViewerInfrastructure() {
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

        addSubview(interactiveNavigationStripView)
        interactiveNavigationStripView.addSubview(scrollView)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidEndLiveMagnify),
            name: NSScrollView.didEndLiveMagnifyNotification,
            object: scrollView
        )
    }

    func configureHandlers(for view: RotatingImageView) {
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

    @discardableResult
    func handlePointerDrag(_ phase: PointerDragPhase, event: NSEvent) -> Bool {
        pointerDragCoordinator.handle(
            phase,
            event: event,
            canPan: canPanVisibleRect,
            onPan: { [weak self] previousLocation, currentLocation in
                self?.panVisibleRect(from: previousLocation, to: currentLocation)
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
        case .interactiveNavigation(let offset):
            applyInteractiveNavigationOffset(offset)
            return true
        case .finishInteractiveNavigation(let direction):
            finishInteractiveNavigation(direction)
            return true
        case .consumeGesture:
            return true
        case .scrollContent:
            return false
        }
    }

    @discardableResult
    func handleTrackpadMagnify(_ event: NSEvent) -> Bool {
        guard displayedImage != nil else { return false }

        return trackpadScrollCoordinator.handleMagnify(
            event: event,
            currentMagnification: scrollView.magnification,
            minimumMagnification: minimumAllowedMagnification,
            maximumMagnification: scrollView.maxMagnification,
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
            minimumMagnification: minimumAllowedMagnification,
            maximumMagnification: scrollView.maxMagnification,
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
    func finishCommandWheelZoomGesture(animated: Bool = true) -> Bool {
        let hadGesture = commandWheelZoomCoordinator.finish()
        return snapBackToMinimumZoomIfNeeded(animated: animated) || hadGesture
    }

    func handleAnchoredMagnificationChange(_ magnification: CGFloat, locationInWindow: NSPoint) {
        guard !zoomAnimator.isApplyingProgrammaticMagnification else { return }

        let clampedScale = clampMagnificationToViewerPolicy(magnification)
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
    func presentPostProcessingMenu(event: NSEvent) -> Bool {
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

    func handleKeyDown(_ event: NSEvent) -> Bool {
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

    func handleKeyUp(_ event: NSEvent) -> Bool {
        keyboardCoordinator.handleKeyUp(event) { onNavigationHoldChange?($0) }
    }

    func scrollHandlingResult(
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

    func applyInteractiveNavigationOffset(_ offset: CGFloat) {
        guard abs(offset) >= 0.5 else { return }

        if interactiveNavigationPrimaryFrame == nil {
            interactiveNavigationPrimaryFrame = interactiveNavigationPageFrame
        }
        layoutInteractiveNavigationPreview(offset: offset)
        interactiveNavigationStripView.wantsLayer = true
        interactiveNavigationAnimationGeneration += 1
        interactiveNavigationStripView.layer?.removeAnimation(forKey: Self.interactiveNavigationAnimationKey)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        interactiveNavigationStripView.layer?.transform = CATransform3DMakeTranslation(offset, 0, 0)
        CATransaction.commit()
    }

    func finishInteractiveNavigation(_ direction: NavigationDirection?) {
        let currentOffset = interactiveNavigationStripView.layer?.presentation()?.transform.m41
            ?? interactiveNavigationStripView.layer?.transform.m41
            ?? 0
        let previewDirection = direction ?? (currentOffset < 0 ? .next : .previous)
        let currentPreviewFrame = interactiveNavigationPreviewFrame(
            direction: previewDirection,
            offset: 0
        )
        let pageTravel = currentPreviewFrame?.pageTravel ?? interactiveNavigationPageTravel(direction: previewDirection)
        let targetOffset: CGFloat
        if let direction {
            targetOffset = direction == .next ? -pageTravel : pageTravel
        } else {
            targetOffset = 0
        }

        currentPreviewFrame?.view.frame = currentPreviewFrame?.frame ?? .zero
        currentPreviewFrame?.view.isHidden = false
        currentPreviewFrame?.oppositeView.isHidden = true

        interactiveNavigationStripView.wantsLayer = true
        guard let layer = interactiveNavigationStripView.layer else { return }

        interactiveNavigationAnimationGeneration += 1
        let animationGeneration = interactiveNavigationAnimationGeneration
        let duration = direction == nil ? 0.26 : 0.24
        let targetTransform = CATransform3DMakeTranslation(targetOffset, 0, 0)
        let destinationURL = direction.flatMap(interactiveNavigationDestinationURL)
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = layer.presentation()?.transform ?? layer.transform
        animation.toValue = targetTransform
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.18, 1.0)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.transform = targetTransform
        layer.add(animation, forKey: Self.interactiveNavigationAnimationKey)
        CATransaction.commit()

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self, self.interactiveNavigationAnimationGeneration == animationGeneration else {
                return
            }
            if direction != nil, let destinationURL {
                self.pendingInteractiveNavigationDestinationURL = destinationURL
            }

            if let direction {
                self.onNavigateRequest?(direction)
            } else if abs(currentOffset) > 0.5 {
                self.documentContainerView.needsDisplay = true
            }

            guard direction != nil, destinationURL != nil else {
                self.completeInteractiveNavigationTransition()
                return
            }
        }
    }

    func layoutInteractiveNavigationPreview(offset: CGFloat) {
        let direction: NavigationDirection = offset < 0 ? .next : .previous
        guard let previewFrame = interactiveNavigationPreviewFrame(
            direction: direction,
            offset: 0
        ) else {
            hideInteractiveNavigationPreviews()
            return
        }

        previewFrame.view.frame = previewFrame.frame
        previewFrame.view.isHidden = false
        previewFrame.oppositeView.isHidden = true
    }

    private struct InteractiveNavigationPreviewFrame {
        let view: RotatingImageView
        let oppositeView: RotatingImageView
        let frame: NSRect
        let baseFrame: NSRect
        let pageDelta: CGFloat
        let pageTravel: CGFloat
    }

    private func interactiveNavigationPreviewFrame(
        direction: NavigationDirection,
        offset: CGFloat
    ) -> InteractiveNavigationPreviewFrame? {
        let previewView = direction == .next ? nextPreviewImageView : previousPreviewImageView
        let oppositeView = direction == .next ? previousPreviewImageView : nextPreviewImageView
        guard previewView.image != nil else { return nil }

        let primaryFrame = interactiveNavigationPrimaryFrame
            ?? interactiveNavigationPageFrame
        let baseFrame = interactiveNavigationPreviewBaseFrame(
            for: previewView,
            primaryFrame: primaryFrame
        )
        let pageDelta = interactiveNavigationPageDelta(
            direction: direction,
            primaryFrame: primaryFrame,
            previewFrame: baseFrame
        )

        return interactiveNavigationPreviewFrame(
            direction: direction,
            offset: offset,
            baseFrame: baseFrame,
            pageDelta: pageDelta,
            view: previewView,
            oppositeView: oppositeView
        )
    }

    private func interactiveNavigationPreviewFrame(
        direction: NavigationDirection,
        offset: CGFloat,
        baseFrame: NSRect,
        pageDelta: CGFloat
    ) -> InteractiveNavigationPreviewFrame {
        let previewView = direction == .next ? nextPreviewImageView : previousPreviewImageView
        let oppositeView = direction == .next ? previousPreviewImageView : nextPreviewImageView
        return interactiveNavigationPreviewFrame(
            direction: direction,
            offset: offset,
            baseFrame: baseFrame,
            pageDelta: pageDelta,
            view: previewView,
            oppositeView: oppositeView
        )
    }

    private func interactiveNavigationPreviewFrame(
        direction: NavigationDirection,
        offset: CGFloat,
        baseFrame: NSRect,
        pageDelta: CGFloat,
        view: RotatingImageView,
        oppositeView: RotatingImageView
    ) -> InteractiveNavigationPreviewFrame {
        return InteractiveNavigationPreviewFrame(
            view: view,
            oppositeView: oppositeView,
            frame: baseFrame.offsetBy(dx: pageDelta + offset, dy: 0),
            baseFrame: baseFrame,
            pageDelta: pageDelta,
            pageTravel: abs(pageDelta)
        )
    }

    private func interactiveNavigationPageDelta(
        direction: NavigationDirection,
        primaryFrame: NSRect? = nil,
        previewFrame: NSRect? = nil
    ) -> CGFloat {
        let frame = primaryFrame
            ?? interactiveNavigationPageFrame
        let preview = previewFrame ?? .zero

        switch direction {
        case .next:
            return frame.maxX + Self.interactiveNavigationPageGap - preview.minX
        case .previous:
            return frame.minX - Self.interactiveNavigationPageGap - preview.maxX
        }
    }

    private func interactiveNavigationPageTravel(direction: NavigationDirection) -> CGFloat {
        abs(interactiveNavigationPageDelta(direction: direction))
    }

    private var interactiveNavigationPageFrame: NSRect {
        scrollView.frame
    }

    private func interactiveNavigationPreviewBaseFrame(
        for previewView: RotatingImageView,
        primaryFrame: NSRect
    ) -> NSRect {
        let previewSize = previewView.displayedImageSize
        guard previewSize.width > 0,
              previewSize.height > 0 else {
            return .zero
        }

        let magnification = max(interactiveNavigationPreviewMagnification(for: previewSize), 0.0001)
        let scaledSize = NSSize(
            width: previewSize.width * magnification,
            height: previewSize.height * magnification
        )
        return NSRect(
            x: primaryFrame.midX - (scaledSize.width / 2),
            y: primaryFrame.midY - (scaledSize.height / 2),
            width: scaledSize.width,
            height: scaledSize.height
        )
    }

    func hideInteractiveNavigationPreviews() {
        previousPreviewImageView.isHidden = true
        nextPreviewImageView.isHidden = true
    }

    func completePendingInteractiveNavigationIfNeeded(appliedImageURL: URL?) {
        guard let pendingInteractiveNavigationDestinationURL else { return }

        if appliedImageURL == pendingInteractiveNavigationDestinationURL {
            completeInteractiveNavigationTransition()
        } else {
            cancelInteractiveNavigationTransition()
        }
    }

    private func interactiveNavigationDestinationURL(for direction: NavigationDirection) -> URL? {
        switch direction {
        case .previous:
            return previousPreviewURL
        case .next:
            return nextPreviewURL
        }
    }

    private func cancelInteractiveNavigationTransition() {
        pendingInteractiveNavigationDestinationURL = nil
        completeInteractiveNavigationTransition()
    }

    private func completeInteractiveNavigationTransition() {
        pendingInteractiveNavigationDestinationURL = nil
        interactiveNavigationStripView.layer?.removeAnimation(forKey: Self.interactiveNavigationAnimationKey)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        interactiveNavigationStripView.layer?.transform = CATransform3DIdentity
        CATransaction.commit()
        hideInteractiveNavigationPreviews()
        interactiveNavigationPrimaryFrame = nil
    }

    private func interactiveNavigationPreviewMagnification(for imageSize: NSSize) -> CGFloat {
        switch viewportState.zoomMode {
        case .fit(let fitMode):
            return Self.fitMagnification(
                imageSize: imageSize,
                viewportSize: viewportSizeForLayout,
                fitMode: fitMode,
                minimumMagnification: scrollView.minMagnification,
                maximumMagnification: scrollView.maxMagnification
            )
        case .custom:
            return scrollView.magnification
        case .actualSize:
            return 1.0
        }
    }
}
