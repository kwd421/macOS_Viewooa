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
        onPan: (_ previousLocation: NSPoint, _ currentLocation: NSPoint) -> Void,
        onPointerLockBegin: (_ startLocation: NSPoint) -> Void = { _ in },
        onPointerLockEnd: () -> Void = {}
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

            if !hasDraggedVisibleRect {
                onPointerLockBegin(dragStartLocationInWindow)
            }
            onPan(lastDragLocationInWindow, currentLocation)
            self.lastDragLocationInWindow = currentLocation
            hasDraggedVisibleRect = true
            return true
        case .ended:
            guard lastDragLocationInWindow != nil else { return false }

            let didDrag = hasDraggedVisibleRect
            reset()
            if didDrag {
                onPointerLockEnd()
            }
            return didDrag
        }
    }
}

final class ImageViewerPointerLockController {
    private var lockedScreenPoint: CGPoint?
    private var isCursorHidden = false

    deinit {
        end()
    }

    @MainActor
    func begin(atWindowLocation locationInWindow: NSPoint, in window: NSWindow?) {
        guard lockedScreenPoint == nil,
              let screenPoint = Self.cursorWarpPoint(forWindowLocation: locationInWindow, in: window) else {
            return
        }

        lockedScreenPoint = screenPoint
        NSCursor.hide()
        isCursorHidden = true
    }

    func end() {
        guard lockedScreenPoint != nil || isCursorHidden else {
            return
        }

        if let lockedScreenPoint {
            CGWarpMouseCursorPosition(lockedScreenPoint)
        }
        if isCursorHidden {
            NSCursor.unhide()
            isCursorHidden = false
        }
        lockedScreenPoint = nil
    }

    @MainActor
    private static func cursorWarpPoint(forWindowLocation locationInWindow: NSPoint, in window: NSWindow?) -> CGPoint? {
        guard let window else { return nil }

        let screenPoint = window.convertPoint(toScreen: locationInWindow)
        let displayBounds = CGDisplayBounds(CGMainDisplayID())
        return CGPoint(
            x: screenPoint.x - displayBounds.minX,
            y: displayBounds.maxY - screenPoint.y
        )
    }
}
