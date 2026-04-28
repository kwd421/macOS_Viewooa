import Foundation

final class ImageViewerNavigationHoldCoordinator {
    private var holdWorkItem: DispatchWorkItem?
    private var holdToken = UUID()
    private var isIndicatorVisible = false
    private(set) var activeKeyCode: UInt16?

    func begin(for keyCode: UInt16, onHoldChange: @escaping (Bool) -> Void) {
        activeKeyCode = keyCode
        holdWorkItem?.cancel()
        holdToken = UUID()
        isIndicatorVisible = false

        let token = holdToken
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.holdToken == token else { return }
            self.isIndicatorVisible = true
            onHoldChange(true)
        }
        holdWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: workItem)
    }

    func end(onHoldChange: (Bool) -> Void) {
        holdWorkItem?.cancel()
        holdWorkItem = nil
        holdToken = UUID()
        activeKeyCode = nil

        if isIndicatorVisible {
            isIndicatorVisible = false
            onHoldChange(false)
        }
    }

    func cancel() {
        holdWorkItem?.cancel()
        holdWorkItem = nil
        holdToken = UUID()
        activeKeyCode = nil
        isIndicatorVisible = false
    }
}
