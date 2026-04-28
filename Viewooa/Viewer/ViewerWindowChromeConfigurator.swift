import AppKit
import SwiftUI

struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(window: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        alignTrafficLights(in: window)
    }

    private func alignTrafficLights(in window: NSWindow) {
        guard let closeButton = window.standardWindowButton(.closeButton),
              let minimizeButton = window.standardWindowButton(.miniaturizeButton),
              let zoomButton = window.standardWindowButton(.zoomButton),
              let buttonContainer = closeButton.superview else {
            return
        }

        let topPadding: CGFloat = 16
        let leftPadding: CGFloat = 16
        let spacing = minimizeButton.frame.minX - closeButton.frame.minX
        let y = buttonContainer.bounds.height - topPadding - closeButton.frame.height

        closeButton.setFrameOrigin(NSPoint(x: leftPadding, y: y))
        minimizeButton.setFrameOrigin(NSPoint(x: leftPadding + spacing, y: y))
        zoomButton.setFrameOrigin(NSPoint(x: leftPadding + spacing * 2, y: y))
    }
}
