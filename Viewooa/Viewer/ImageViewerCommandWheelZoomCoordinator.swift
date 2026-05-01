import AppKit

final class ImageViewerCommandWheelZoomCoordinator {
    private var isGestureActive = false
    private var endWorkItem: DispatchWorkItem?
    private var endToken = UUID()

    func beginIfNeeded(phase: NSEvent.Phase) {
        if phase.contains(.began) || phase.contains(.mayBegin) || !isGestureActive {
            reset()
            isGestureActive = true
        }
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
        applyMagnification: (CGFloat, NSPoint?) -> Void,
        finishGesture: @escaping () -> Void
    ) -> Bool {
        beginIfNeeded(phase: phase)
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
        let hadGesture = isGestureActive
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
        isGestureActive = false
    }
}
