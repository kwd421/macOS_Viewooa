import Foundation

extension ViewerState {
    func clearError() {
        lastErrorMessage = nil
    }

    func clearTransientNotice(id: ViewerTransientNotice.ID? = nil) {
        guard id == nil || transientNotice?.id == id else { return }
        transientNotice = nil
    }

    func setError(message: String) {
        lastErrorMessage = message
    }

    func showTransientNotice(_ message: String) {
        transientNotice = ViewerTransientNotice(message: message)
    }

    var navigationCountText: String? {
        guard let index else { return nil }
        return "\(index.currentIndex + 1) / \(index.imageURLs.count)"
    }

    var canShowPreviousImage: Bool {
        guard let index else { return false }
        let previousIndex = ViewerNavigationResolver.previousIndex(
            currentIndex: index.currentIndex,
            itemCount: index.imageURLs.count,
            layout: pageLayout,
            coverModeEnabled: isCoverModeEnabled
        )
        return previousIndex >= 0 && previousIndex != index.currentIndex
    }

    var canShowNextImage: Bool {
        guard let index else { return false }
        let nextIndex = ViewerNavigationResolver.nextIndex(
            currentIndex: index.currentIndex,
            itemCount: index.imageURLs.count,
            layout: pageLayout,
            coverModeEnabled: isCoverModeEnabled
        )
        return nextIndex < index.imageURLs.count && nextIndex != index.currentIndex
    }
}
