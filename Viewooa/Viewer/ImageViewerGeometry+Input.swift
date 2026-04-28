import AppKit

extension ImageViewerNSView {
    static func isEndingMagnifyGesture(phase: NSEvent.Phase) -> Bool {
        phase.contains(.ended) || phase.contains(.cancelled)
    }

    static func isEndingScrollGesture(phase: NSEvent.Phase, momentumPhase: NSEvent.Phase) -> Bool {
        phase.contains(.ended)
            || phase.contains(.cancelled)
            || momentumPhase.contains(.ended)
            || momentumPhase.contains(.cancelled)
    }

    static func isBeyondClickDragTolerance(from startLocation: NSPoint, to currentLocation: NSPoint) -> Bool {
        let deltaX = currentLocation.x - startLocation.x
        let deltaY = currentLocation.y - startLocation.y
        return (deltaX * deltaX) + (deltaY * deltaY) >= 16
    }

    static func navigationDirection(forKeyCode keyCode: UInt16) -> NavigationDirection? {
        switch keyCode {
        case 123:
            return .previous
        case 124:
            return .next
        default:
            return nil
        }
    }
}
