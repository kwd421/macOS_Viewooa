import AppKit
import SwiftUI

struct SlideshowIntervalScrollStepper: NSViewRepresentable {
    let onStep: (Double) -> Void

    func makeNSView(context: Context) -> ScrollStepperView {
        let view = ScrollStepperView()
        view.onStep = onStep
        return view
    }

    func updateNSView(_ nsView: ScrollStepperView, context: Context) {
        nsView.onStep = onStep
    }
}

final class ScrollStepperView: NSView {
    var onStep: ((Double) -> Void)?
    private var eventMonitor: Any?
    private var preciseScrollRemainder: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window == nil {
            removeEventMonitor()
        } else {
            installEventMonitorIfNeeded()
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    private func installEventMonitorIfNeeded() {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, self.isEventInside(event) else { return event }
            self.handleScroll(event)
            return nil
        }
    }

    private func removeEventMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

    private func isEventInside(_ event: NSEvent) -> Bool {
        guard let window, event.window === window else { return false }

        let localPoint = convert(event.locationInWindow, from: nil)
        return bounds.contains(localPoint)
    }

    private func handleScroll(_ event: NSEvent) {
        let delta = event.hasPreciseScrollingDeltas ? -event.scrollingDeltaY : event.scrollingDeltaY
        guard abs(delta) > 0 else { return }

        if event.hasPreciseScrollingDeltas {
            preciseScrollRemainder += delta
            guard abs(preciseScrollRemainder) >= 8 else { return }
            onStep?(preciseScrollRemainder > 0 ? 0.5 : -0.5)
            preciseScrollRemainder = 0
            return
        }

        onStep?(delta > 0 ? 0.5 : -0.5)
    }
}
