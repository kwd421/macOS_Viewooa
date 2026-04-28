import AppKit

final class ImageViewerCommandWheelZoomCoordinator {
    private struct Gesture {
        let startedAtFit: Bool
        var firstSignificantDelta: CGFloat?
    }

    private var gesture: Gesture?
    private var endWorkItem: DispatchWorkItem?
    private var endToken = UUID()

    func beginIfNeeded(phase: NSEvent.Phase, startedAtFit: Bool) {
        if phase.contains(.began) || phase.contains(.mayBegin) || gesture == nil {
            reset()
            gesture = Gesture(startedAtFit: startedAtFit, firstSignificantDelta: nil)
        }
    }

    func recordFirstSignificantDeltaIfNeeded(_ delta: CGFloat) {
        guard gesture?.firstSignificantDelta == nil else { return }
        gesture?.firstSignificantDelta = delta
    }

    func shouldRouteZoomOutToBrowser(zoomDelta: CGFloat, isCurrentlyFit: Bool) -> Bool {
        zoomDelta < 0
            && gesture?.startedAtFit == true
            && gesture?.firstSignificantDelta.map { $0 < 0 } == true
            && isCurrentlyFit
    }

    @MainActor
    @discardableResult
    func handleZoom(
        verticalDelta: CGFloat,
        horizontalDelta: CGFloat,
        locationInWindow: NSPoint?,
        phase: NSEvent.Phase,
        momentumPhase: NSEvent.Phase,
        currentMagnification: CGFloat,
        minimumMagnification: CGFloat,
        maximumMagnification: CGFloat,
        isCurrentlyFit: Bool,
        requestFitZoomOut: () -> Bool,
        applyMagnification: (CGFloat, NSPoint?) -> Void,
        finishGesture: @escaping () -> Void
    ) -> Bool {
        beginIfNeeded(phase: phase, startedAtFit: isCurrentlyFit)
        let isEndingGesture = ImageViewerNSView.isEndingScrollGesture(
            phase: phase,
            momentumPhase: momentumPhase
        )
        let zoomDelta = abs(verticalDelta) >= abs(horizontalDelta) ? verticalDelta : -horizontalDelta
        guard abs(zoomDelta) >= 0.1 else {
            if isEndingGesture {
                finishGesture()
            }
            return true
        }

        recordFirstSignificantDeltaIfNeeded(zoomDelta)

        if shouldRouteZoomOutToBrowser(zoomDelta: zoomDelta, isCurrentlyFit: isCurrentlyFit),
           requestFitZoomOut() {
            reset()
            return true
        }

        let nextMagnification = ImageViewerNSView.commandWheelMagnification(
            currentMagnification: currentMagnification,
            delta: zoomDelta,
            minimumMagnification: minimumMagnification,
            maximumMagnification: maximumMagnification
        )
        applyMagnification(nextMagnification, locationInWindow)

        if isEndingGesture {
            finishGesture()
        } else {
            scheduleEnd(finishGesture)
        }

        return true
    }

    @discardableResult
    func finish() -> Bool {
        let hadGesture = gesture != nil
        reset()
        return hadGesture
    }

    func scheduleEnd(_ action: @escaping () -> Void) {
        endWorkItem?.cancel()
        endToken = UUID()
        let token = endToken
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.endToken == token else { return }
            action()
        }
        endWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(180), execute: workItem)
    }

    func reset() {
        endWorkItem?.cancel()
        endWorkItem = nil
        endToken = UUID()
        gesture = nil
    }
}
