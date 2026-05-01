import AppKit

enum ImageViewerScrollHandlingResult: Equatable {
    case navigate(ImageViewerNSView.NavigationDirection)
    case consumeGesture
    case scrollContent
}

final class ImageViewerTrackpadScrollCoordinator {
    private struct MagnifyGesture {
        let startedAtFit: Bool
        var firstSignificantDelta: CGFloat?
    }

    private var hasNavigatedDuringCurrentGesture = false
    private var accumulatedHorizontalDelta: CGFloat = 0
    private var accumulatedVerticalDelta: CGFloat = 0
    private var magnifyGesture: MagnifyGesture?

    private static let significantMagnifyDelta: CGFloat = 0.01

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
        beginMagnifyGestureIfNeeded(phase: event.phase, startedAtFit: isCurrentlyFit)
        let isEndingGesture = ImageViewerNSView.isEndingMagnifyGesture(phase: event.phase)
        guard abs(event.magnification) >= Self.significantMagnifyDelta else {
            if isEndingGesture {
                finishGesture()
                resetMagnifyGesture()
            }

            return true
        }

        recordFirstSignificantMagnifyDeltaIfNeeded(event.magnification)

        if shouldRouteFitZoomOutToBrowser(magnificationDelta: event.magnification, isCurrentlyFit: isCurrentlyFit),
           requestFitZoomOut() {
            resetMagnifyGesture()
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
            resetMagnifyGesture()
        }

        return true
    }

    private func beginMagnifyGestureIfNeeded(phase: NSEvent.Phase, startedAtFit: Bool) {
        if phase.contains(.began) || phase.contains(.mayBegin) || magnifyGesture == nil {
            magnifyGesture = MagnifyGesture(startedAtFit: startedAtFit, firstSignificantDelta: nil)
        }
    }

    private func recordFirstSignificantMagnifyDeltaIfNeeded(_ delta: CGFloat) {
        guard magnifyGesture?.firstSignificantDelta == nil else { return }
        magnifyGesture?.firstSignificantDelta = delta
    }

    private func shouldRouteFitZoomOutToBrowser(magnificationDelta: CGFloat, isCurrentlyFit: Bool) -> Bool {
        Self.shouldRouteFitZoomOutToBrowser(
            magnificationDelta: magnificationDelta,
            startedAtFit: magnifyGesture?.startedAtFit == true,
            firstSignificantDelta: magnifyGesture?.firstSignificantDelta,
            isCurrentlyFit: isCurrentlyFit
        )
    }

    static func shouldRouteFitZoomOutToBrowser(
        magnificationDelta: CGFloat,
        startedAtFit: Bool,
        firstSignificantDelta: CGFloat?,
        isCurrentlyFit: Bool
    ) -> Bool {
        magnificationDelta < 0
            && startedAtFit
            && firstSignificantDelta.map { $0 < 0 } == true
            && isCurrentlyFit
    }

    static func isSignificantMagnifyDelta(_ delta: CGFloat) -> Bool {
        abs(delta) >= significantMagnifyDelta
    }

    private func resetMagnifyGesture() {
        magnifyGesture = nil
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
