import AppKit

@MainActor
final class ImageViewerPointerDragCoordinator {
    private var dragStartLocationInWindow: NSPoint?
    private var lastDragLocationInWindow: NSPoint?
    private var hasDraggedVisibleRect = false

    func reset() {
        dragStartLocationInWindow = nil
        lastDragLocationInWindow = nil
        hasDraggedVisibleRect = false
    }

    func handle(
        _ phase: PointerDragPhase,
        event: NSEvent,
        canPan: Bool,
        onPan: (_ previousLocation: NSPoint, _ currentLocation: NSPoint) -> Void
    ) -> Bool {
        switch phase {
        case .began:
            guard canPan else {
                reset()
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
               !ImageViewerNSView.isBeyondClickDragTolerance(from: dragStartLocationInWindow, to: currentLocation) {
                return false
            }

            onPan(lastDragLocationInWindow, currentLocation)
            self.lastDragLocationInWindow = currentLocation
            hasDraggedVisibleRect = true
            return true
        case .ended:
            guard lastDragLocationInWindow != nil else { return false }

            let didDrag = hasDraggedVisibleRect
            reset()
            return didDrag
        }
    }

}
