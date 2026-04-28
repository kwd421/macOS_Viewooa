import AppKit
import SwiftUI

struct ImageBrowserEscapeCatcher: NSViewRepresentable {
    let onEscape: () -> Void

    func makeNSView(context: Context) -> EscapeCatcherView {
        let view = EscapeCatcherView()
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: EscapeCatcherView, context: Context) {
        nsView.onEscape = onEscape
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    final class EscapeCatcherView: NSView {
        var onEscape: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            guard event.keyCode == 53 else {
                super.keyDown(with: event)
                return
            }

            onEscape?()
        }
    }
}
