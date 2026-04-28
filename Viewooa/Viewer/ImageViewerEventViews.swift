import AppKit

enum PointerDragPhase {
    case began
    case changed
    case ended
}

enum ImageViewerClickActivation {
    static func isDoubleClickActivation(clickCount: Int) -> Bool {
        clickCount >= 2 && clickCount.isMultiple(of: 2)
    }
}

final class NavigationAwareScrollView: NSScrollView {
    var scrollHandler: ((NSEvent) -> Bool)?
    var magnifyHandler: ((NSEvent) -> Bool)?
    var doubleClickHandler: ((NSEvent) -> Bool)?
    var keyDownHandler: ((NSEvent) -> Bool)?
    var keyUpHandler: ((NSEvent) -> Bool)?
    var dragHandler: ((PointerDragPhase, NSEvent) -> Bool)?
    var contextMenuHandler: ((NSEvent) -> Bool)?

    override var acceptsFirstResponder: Bool { true }

    override func scrollWheel(with event: NSEvent) {
        if scrollHandler?(event) == true {
            return
        }

        super.scrollWheel(with: event)
    }

    override func magnify(with event: NSEvent) {
        if magnifyHandler?(event) == true {
            return
        }

        super.magnify(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)

        if ImageViewerClickActivation.isDoubleClickActivation(clickCount: event.clickCount),
           doubleClickHandler?(event) == true {
            return
        }

        _ = dragHandler?(.began, event)

        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        if dragHandler?(.changed, event) == true {
            return
        }

        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if dragHandler?(.ended, event) == true {
            return
        }

        super.mouseUp(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)

        if contextMenuHandler?(event) == true {
            return
        }

        super.rightMouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if keyDownHandler?(event) == true {
            return
        }

        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        if keyUpHandler?(event) == true {
            return
        }

        super.keyUp(with: event)
    }
}

final class DoubleClickAwareView: NSView {
    var doubleClickHandler: ((NSEvent) -> Bool)?
    var dragHandler: ((PointerDragPhase, NSEvent) -> Bool)?
    var contextMenuHandler: ((NSEvent) -> Bool)?

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(enclosingScrollView)

        if ImageViewerClickActivation.isDoubleClickActivation(clickCount: event.clickCount),
           doubleClickHandler?(event) == true {
            return
        }

        _ = dragHandler?(.began, event)

        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        if dragHandler?(.changed, event) == true {
            return
        }

        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if dragHandler?(.ended, event) == true {
            return
        }

        super.mouseUp(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        window?.makeFirstResponder(enclosingScrollView)

        if contextMenuHandler?(event) == true {
            return
        }

        super.rightMouseDown(with: event)
    }
}
