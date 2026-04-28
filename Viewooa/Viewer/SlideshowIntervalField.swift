import AppKit
import SwiftUI

struct SlideshowIntervalField: NSViewRepresentable {
    @Binding var text: String
    let onCommit: () -> Void
    let onStep: (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WheelTextFieldContainer {
        let view = WheelTextFieldContainer()
        view.textField.delegate = context.coordinator
        view.onStep = onStep
        configure(view.textField)
        view.textField.stringValue = text
        return view
    }

    func updateNSView(_ nsView: WheelTextFieldContainer, context: Context) {
        context.coordinator.parent = self
        nsView.onStep = onStep
        configure(nsView.textField)

        let isEditing = nsView.window?.firstResponder === nsView.textField.currentEditor()
        if !isEditing, nsView.textField.stringValue != text {
            nsView.textField.stringValue = text
        }
    }

    private func configure(_ textField: NSTextField) {
        if !(textField.cell is CleanIntervalTextFieldCell) {
            textField.cell = CleanIntervalTextFieldCell(textCell: textField.stringValue)
        }

        textField.isBordered = false
        textField.drawsBackground = false
        textField.isBezeled = false
        textField.focusRingType = .none
        textField.alignment = .center
        textField.textColor = .white
        textField.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        textField.cell?.sendsActionOnEndEditing = true
        textField.maximumNumberOfLines = 1
        textField.lineBreakMode = .byClipping
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: SlideshowIntervalField

        init(_ parent: SlideshowIntervalField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            parent.onCommit()
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
            parent.text = textView.string
            parent.onCommit()
            control.window?.makeFirstResponder(nil)
            return true
        }
    }
}

private final class CleanIntervalTextFieldCell: NSTextFieldCell {
    override init(textCell string: String) {
        super.init(textCell: string)
        configure()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isScrollable = true
        usesSingleLineMode = true
        wraps = false
        lineBreakMode = .byClipping
    }

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        verticallyCenteredRect(forBounds: rect)
    }

    override func titleRect(forBounds rect: NSRect) -> NSRect {
        verticallyCenteredRect(forBounds: rect)
    }

    private func verticallyCenteredRect(forBounds rect: NSRect) -> NSRect {
        guard let font else { return rect }

        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        let yOffset = floor((rect.height - lineHeight) / 2)
        return NSRect(x: rect.minX, y: rect.minY + yOffset - 0.5, width: rect.width, height: lineHeight)
    }
}

final class WheelTextFieldContainer: NSView {
    let textField = NSTextField()
    var onStep: ((Double) -> Void)?
    private var preciseScrollRemainder: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(textField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        textField.frame = bounds
    }

    override func scrollWheel(with event: NSEvent) {
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
