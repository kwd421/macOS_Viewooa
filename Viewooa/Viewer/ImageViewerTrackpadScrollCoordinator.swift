import AppKit

enum ImageViewerScrollHandlingResult: Equatable {
    case navigate(ImageViewerNSView.NavigationDirection)
    case consumeGesture
    case scrollContent
}

final class ImageViewerTrackpadScrollCoordinator {
    private var hasNavigatedDuringCurrentGesture = false
    private var accumulatedHorizontalDelta: CGFloat = 0
    private var accumulatedVerticalDelta: CGFloat = 0

    func consumeCurrentGesture() {
        hasNavigatedDuringCurrentGesture = true
    }

    @MainActor
    @discardableResult
    func handleMagnify(
        event: NSEvent,
        currentMagnification: CGFloat,
        minimumMagnification: CGFloat,
        maximumMagnification: CGFloat,
        isCurrentlyFit: Bool,
        requestFitZoomOut: () -> Bool,
        applyMagnification: (CGFloat, NSPoint) -> Void,
        finishGesture: () -> Void
    ) -> Bool {
        let isEndingGesture = ImageViewerNSView.isEndingMagnifyGesture(phase: event.phase)
        guard abs(event.magnification) >= 0.001 else {
            if isEndingGesture {
                finishGesture()
            }

            return true
        }

        if event.magnification < 0,
           isCurrentlyFit,
           requestFitZoomOut() {
            return true
        }

        consumeCurrentGesture()
        let nextMagnification = ImageViewerNSView.pinchMagnification(
            currentMagnification: currentMagnification,
            delta: event.magnification,
            minimumMagnification: minimumMagnification,
            maximumMagnification: maximumMagnification
        )
        applyMagnification(nextMagnification, event.locationInWindow)

        if isEndingGesture {
            finishGesture()
        }

        return true
    }

    func handlingResult(
        verticalDelta: CGFloat,
        horizontalDelta: CGFloat,
        phase: NSEvent.Phase,
        momentumPhase: NSEvent.Phase,
        isVerticallyScrollable: Bool,
        isHorizontallyScrollable: Bool
    ) -> ImageViewerScrollHandlingResult {
        resetGestureIfNeeded(phase: phase, momentumPhase: momentumPhase)
        accumulatedHorizontalDelta += horizontalDelta
        accumulatedVerticalDelta += verticalDelta

        if hasNavigatedDuringCurrentGesture {
            return .consumeGesture
        }

        let horizontalGesture = abs(accumulatedHorizontalDelta)
        let verticalGesture = abs(accumulatedVerticalDelta)
        if horizontalGesture >= 24, horizontalGesture > verticalGesture * 1.35 {
            hasNavigatedDuringCurrentGesture = true
            return accumulatedHorizontalDelta > 0 ? .navigate(.previous) : .navigate(.next)
        }

        if abs(verticalDelta) >= 0.5, !isVerticallyScrollable {
            return .consumeGesture
        }

        if abs(horizontalDelta) >= 0.5, !isHorizontallyScrollable {
            return .consumeGesture
        }

        return .scrollContent
    }

    static func mouseHandlingResult(
        verticalDelta: CGFloat,
        horizontalDelta: CGFloat,
        isEntireImageVisible: Bool,
        isVerticallyScrollable: Bool
    ) -> ImageViewerScrollHandlingResult {
        if abs(verticalDelta) > abs(horizontalDelta),
           !isEntireImageVisible,
           !isVerticallyScrollable {
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

    private func resetGestureIfNeeded(phase: NSEvent.Phase, momentumPhase: NSEvent.Phase) {
        if phase.contains(.began) || phase.contains(.mayBegin) {
            resetGesture()
        }

        if phase.contains(.ended)
            || phase.contains(.cancelled)
            || momentumPhase.contains(.ended)
            || momentumPhase.contains(.cancelled) {
            resetGesture()
        }
    }

    private func resetGesture() {
        hasNavigatedDuringCurrentGesture = false
        accumulatedHorizontalDelta = 0
        accumulatedVerticalDelta = 0
    }
}
