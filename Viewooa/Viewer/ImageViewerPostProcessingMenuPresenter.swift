import AppKit

@MainActor
final class ImageViewerPostProcessingMenuPresenter: NSObject {
    private var onToggle: ((ImagePostProcessingOption) -> Void)?
    private var onClear: (() -> Void)?

    func present(
        in view: NSView,
        atWindowLocation locationInWindow: NSPoint,
        options: Set<ImagePostProcessingOption>,
        onToggle: @escaping (ImagePostProcessingOption) -> Void,
        onClear: @escaping () -> Void
    ) {
        self.onToggle = onToggle
        self.onClear = onClear

        let menu = NSMenu(title: "Post Processing")
        for option in ImagePostProcessingOption.allCases {
            let item = NSMenuItem(title: option.title, action: #selector(togglePostProcessingMenuItem(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = option.rawValue
            item.state = options.contains(option) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let clearItem = NSMenuItem(title: "Clear All", action: #selector(clearPostProcessingMenuItem(_:)), keyEquivalent: "")
        clearItem.target = self
        clearItem.isEnabled = !options.isEmpty
        menu.addItem(clearItem)

        let point = view.convert(locationInWindow, from: nil)
        menu.popUp(positioning: nil, at: point, in: view)
    }

    @objc
    private func togglePostProcessingMenuItem(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let option = ImagePostProcessingOption(rawValue: rawValue) else { return }

        onToggle?(option)
    }

    @objc
    private func clearPostProcessingMenuItem(_ sender: NSMenuItem) {
        onClear?()
    }
}
