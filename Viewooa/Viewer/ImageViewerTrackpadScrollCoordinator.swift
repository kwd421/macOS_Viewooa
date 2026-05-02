import AppKit

enum ImageViewerScrollHandlingResult: Equatable {
    case navigate(ImageViewerNSView.NavigationDirection)
    case interactiveNavigation(offset: CGFloat)
    case finishInteractiveNavigation(ImageViewerNSView.NavigationDirection?)
    case consumeGesture
    case scrollContent
}

final class ImageViewerTrackpadScrollCoordinator {
    private var accumulatedHorizontalDelta: CGFloat = 0
    private var accumulatedVerticalDelta: CGFloat = 0
    private var isMagnifyGestureActive = false
    private var didFinishHorizontalNavigation = false

    private static let significantMagnifyDelta: CGFloat = 0.01
    private static let horizontalNavigationThreshold: CGFloat = 72
    private static let horizontalNavigationIntentRatio: CGFloat = 1.35

    private var interactiveNavigationOffset: CGFloat {
        accumulatedHorizontalDelta
    }

    private var interactiveNavigationDirection: ImageViewerNSView.NavigationDirection? {
        guard abs(interactiveNavigationOffset) >= Self.horizontalNavigationThreshold else {
            return nil
        }

        return interactiveNavigationOffset < 0 ? .next : .previous
    }

    func consumeCurrentGesture() {
        accumulatedHorizontalDelta = 0
        accumulatedVerticalDelta = 0
        didFinishHorizontalNavigation = false
    }

    @MainActor
    @discardableResult
    func handleMagnify(
        event: NSEvent,
        currentMagnification: CGFloat,
        minimumMagnification: CGFloat,
        maximumMagnification: CGFloat,
        applyMagnification: (CGFloat, NSPoint) -> Void,
        finishGesture: () -> Void
    ) -> Bool {
        beginMagnifyGestureIfNeeded(phase: event.phase)
        let isEndingGesture = ImageViewerNSView.isEndingMagnifyGesture(phase: event.phase)
        guard Self.isSignificantMagnifyDelta(event.magnification) else {
            if isEndingGesture {
                finishGesture()
                resetMagnifyGesture()
            }

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

    private func beginMagnifyGestureIfNeeded(phase: NSEvent.Phase) {
        if phase.contains(.began) || phase.contains(.mayBegin) || !isMagnifyGestureActive {
            isMagnifyGestureActive = true
        }
    }

    static func isSignificantMagnifyDelta(_ delta: CGFloat) -> Bool {
        abs(delta) >= significantMagnifyDelta
    }

    private func resetMagnifyGesture() {
        isMagnifyGestureActive = false
    }

    func handlingResult(
        verticalDelta: CGFloat,
        horizontalDelta: CGFloat,
        phase: NSEvent.Phase,
        momentumPhase: NSEvent.Phase,
        isVerticallyScrollable: Bool,
        isHorizontallyScrollable: Bool
    ) -> ImageViewerScrollHandlingResult {
        if phase.contains(.began) || phase.contains(.mayBegin) {
            resetGesture()
        }

        if didFinishHorizontalNavigation {
            return .consumeGesture
        }

        accumulatedHorizontalDelta += horizontalDelta
        accumulatedVerticalDelta += verticalDelta

        if isEndingGesture(phase: phase, momentumPhase: momentumPhase) {
            guard isHorizontalNavigationGesture else {
                resetGesture()
                return .finishInteractiveNavigation(nil)
            }

            let direction = interactiveNavigationDirection
            if direction != nil {
                didFinishHorizontalNavigation = true
                accumulatedHorizontalDelta = 0
                accumulatedVerticalDelta = 0
            } else {
                resetGesture()
            }
            return .finishInteractiveNavigation(direction)
        }

        if isHorizontalNavigationGesture {
            return .interactiveNavigation(offset: interactiveNavigationOffset)
        }

        if abs(verticalDelta) >= 0.5, !isVerticallyScrollable {
            return .consumeGesture
        }

        if abs(horizontalDelta) >= 0.5, !isHorizontallyScrollable {
            return .consumeGesture
        }

        return .scrollContent
    }

    private var isHorizontalNavigationGesture: Bool {
        let horizontalGesture = abs(accumulatedHorizontalDelta)
        let verticalGesture = abs(accumulatedVerticalDelta)
        return horizontalGesture >= 4
            && horizontalGesture > verticalGesture * Self.horizontalNavigationIntentRatio
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

    private func isEndingGesture(phase: NSEvent.Phase, momentumPhase: NSEvent.Phase) -> Bool {
        phase.contains(.ended)
            || phase.contains(.cancelled)
            || momentumPhase.contains(.ended)
            || momentumPhase.contains(.cancelled)
    }

    private func resetGesture() {
        accumulatedHorizontalDelta = 0
        accumulatedVerticalDelta = 0
        didFinishHorizontalNavigation = false
    }
}
