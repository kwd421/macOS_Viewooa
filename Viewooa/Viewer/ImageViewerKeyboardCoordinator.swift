import AppKit

@MainActor
final class ImageViewerKeyboardCoordinator {
    private let navigationHoldCoordinator = ImageViewerNavigationHoldCoordinator()

    func endHold(onHoldChange: (Bool) -> Void) {
        navigationHoldCoordinator.end(onHoldChange: onHoldChange)
    }

    func handleKeyDown(
        _ event: NSEvent,
        onToggleMetadata: () -> Void,
        onNavigate: (ImageViewerNSView.NavigationDirection) -> Void,
        onHoldChange: @escaping (Bool) -> Void
    ) -> Bool {
        if event.keyCode == 48 {
            onToggleMetadata()
            return true
        }

        guard let direction = ImageViewerNSView.navigationDirection(forKeyCode: event.keyCode) else {
            return false
        }

        if !event.isARepeat {
            navigationHoldCoordinator.begin(for: event.keyCode, onHoldChange: onHoldChange)
        }
        onNavigate(direction)
        return true
    }

    func handleKeyUp(_ event: NSEvent, onHoldChange: (Bool) -> Void) -> Bool {
        guard ImageViewerNSView.navigationDirection(forKeyCode: event.keyCode) != nil else {
            return false
        }

        if navigationHoldCoordinator.activeKeyCode == event.keyCode {
            navigationHoldCoordinator.end(onHoldChange: onHoldChange)
        }
        return true
    }
}
