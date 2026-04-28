import SwiftUI
import AppKit

struct OpenBrowserKeyboardCatcher: NSViewRepresentable {
    let onEscape: () -> Void
    let onSelectAll: () -> Void
    let onOpen: () -> Void
    let onParent: () -> Void

    func makeNSView(context: Context) -> KeyboardCatcherView {
        let view = KeyboardCatcherView()
        view.onEscape = onEscape
        view.onSelectAll = onSelectAll
        view.onOpen = onOpen
        view.onParent = onParent
        return view
    }

    func updateNSView(_ nsView: KeyboardCatcherView, context: Context) {
        nsView.onEscape = onEscape
        nsView.onSelectAll = onSelectAll
        nsView.onOpen = onOpen
        nsView.onParent = onParent

        DispatchQueue.main.async {
            if nsView.window?.firstResponder is NSTextView == false {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    final class KeyboardCatcherView: NSView {
        var onEscape: (() -> Void)?
        var onSelectAll: (() -> Void)?
        var onOpen: (() -> Void)?
        var onParent: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            switch (event.keyCode, event.modifierFlags.intersection(.deviceIndependentFlagsMask)) {
            case (53, _):
                onEscape?()
            case (0, let modifiers) where modifiers.contains(.command):
                onSelectAll?()
            case (36, _), (76, _):
                onOpen?()
            case (126, let modifiers) where modifiers.contains(.command):
                onParent?()
            case (51, _):
                onParent?()
            default:
                super.keyDown(with: event)
            }
        }
    }
}
