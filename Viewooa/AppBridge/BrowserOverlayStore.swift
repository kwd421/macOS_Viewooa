import Foundation

@MainActor
final class BrowserOverlayStore: ObservableObject {
    private enum Constants {
        static let defaultThumbnailSize: CGFloat = 132
        static let minimumThumbnailSize: CGFloat = 72
        static let maximumThumbnailSize: CGFloat = 220
    }

    @Published private(set) var isOpenBrowserVisible = false
    @Published private(set) var isImageBrowserVisible = false
    @Published private(set) var displayMode: ImageBrowserDisplayMode = .thumbnails
    @Published private(set) var thumbnailSize: CGFloat = Constants.defaultThumbnailSize

    var areOverlaysVisible: Bool {
        isOpenBrowserVisible || isImageBrowserVisible
    }

    func showOpenBrowser() {
        isImageBrowserVisible = false
        isOpenBrowserVisible = true
    }

    func hideOpenBrowser() {
        isOpenBrowserVisible = false
    }

    func showImageBrowser() {
        isOpenBrowserVisible = false
        isImageBrowserVisible = true
    }

    func hideImageBrowser() {
        isImageBrowserVisible = false
    }

    func setDisplayMode(_ mode: ImageBrowserDisplayMode) {
        displayMode = mode
    }

    func setThumbnailSize(_ size: CGFloat) {
        thumbnailSize = min(max(size, Constants.minimumThumbnailSize), Constants.maximumThumbnailSize)
    }
}
