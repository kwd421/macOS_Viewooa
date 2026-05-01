import Foundation

@MainActor
final class BrowserOverlayStore: ObservableObject {
    @Published private(set) var isOpenBrowserVisible = false
    @Published private(set) var isImageBrowserVisible = false
    @Published private(set) var displayMode: ImageBrowserDisplayMode = .thumbnails
    @Published private(set) var thumbnailSize: CGFloat = ImageBrowserThumbnailSizing.defaultSize

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
        thumbnailSize = ImageBrowserThumbnailSizing.clamped(size)
    }
}
