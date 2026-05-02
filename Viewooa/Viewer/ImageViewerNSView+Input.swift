import AppKit

extension ImageViewerNSView {
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

        addSubview(scrollView)

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

}
