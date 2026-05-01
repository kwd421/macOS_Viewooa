import Foundation

@MainActor
final class BrowserOverlayStore: ObservableObject {
    @Published private(set) var isOpenBrowserVisible = false
    @Published private(set) var displayMode: BrowserDisplayMode = .thumbnails
    @Published private(set) var thumbnailSize: CGFloat = BrowserThumbnailSizing.defaultSize

    var areOverlaysVisible: Bool {
        isOpenBrowserVisible
    }

    func showOpenBrowser() {
        isOpenBrowserVisible = true
    }

    func hideOpenBrowser() {
        isOpenBrowserVisible = false
    }

    func setDisplayMode(_ mode: BrowserDisplayMode) {
        displayMode = mode
    }

    func setThumbnailSize(_ size: CGFloat) {
        thumbnailSize = BrowserThumbnailSizing.clamped(size)
    }
}
