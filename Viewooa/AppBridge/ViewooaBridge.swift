import Combine
import Foundation

@MainActor
final class ViewooaBridge: ObservableObject {
    let photoViewerStore: PhotoViewerStore
    let browserOverlayStore: BrowserOverlayStore

    private var browserOverlayObserver: AnyCancellable?

    convenience init(viewerState: ViewerState = ViewerState()) {
        self.init(photoViewerStore: PhotoViewerStore(viewerState: viewerState))
    }

    init(
        photoViewerStore: PhotoViewerStore,
        browserOverlayStore: BrowserOverlayStore = BrowserOverlayStore()
    ) {
        self.photoViewerStore = photoViewerStore
        self.browserOverlayStore = browserOverlayStore
        browserOverlayObserver = browserOverlayStore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    func presentOpenBrowser() {
        photoViewerStore.stopSlideshow()
        photoViewerStore.hideMetadata()
        browserOverlayStore.showOpenBrowser()
    }

    func hideOpenBrowser() {
        browserOverlayStore.hideOpenBrowser()
    }

    func openSelectionFromBrowser(_ url: URL) {
        photoViewerStore.openSelection(at: url)
        browserOverlayStore.hideOpenBrowser()
    }

    func zoomOut() {
        if photoViewerStore.zoomMode.isFit, canShowImageBrowser {
            showImageBrowser()
            return
        }

        photoViewerStore.zoomOut()
    }

    func showPreviousImage() {
        photoViewerStore.showPreviousImageFromNavigationShortcut()
    }

    func showNextImage() {
        photoViewerStore.showNextImageFromNavigationShortcut()
    }

    func rotateClockwise() {
        photoViewerStore.rotateClockwise()
    }

    func zoomIn() {
        photoViewerStore.zoomIn()
    }

    func zoomToActualSize() {
        photoViewerStore.zoomToActualSize()
    }

    func zoomToFit(_ mode: FitMode) {
        photoViewerStore.zoomToFit(mode)
    }

    @discardableResult
    func showImageBrowser() -> Bool {
        guard canShowImageBrowser else { return false }
        photoViewerStore.stopSlideshow()
        photoViewerStore.hideMetadata()
        browserOverlayStore.showImageBrowser()
        return true
    }

    func hideImageBrowser() {
        browserOverlayStore.hideImageBrowser()
    }

    func selectImageFromBrowser(at selectedIndex: Int) {
        guard browserImageURLs.indices.contains(selectedIndex) else { return }
        browserOverlayStore.hideImageBrowser()
        photoViewerStore.selectImageFromBrowser(at: selectedIndex)
    }

    func setBrowserDisplayMode(_ mode: ImageBrowserDisplayMode) {
        browserOverlayStore.setDisplayMode(mode)
    }

    func setBrowserThumbnailSize(_ size: CGFloat) {
        browserOverlayStore.setThumbnailSize(size)
    }

    var isOpenBrowserVisible: Bool {
        browserOverlayStore.isOpenBrowserVisible
    }

    var isImageBrowserVisible: Bool {
        browserOverlayStore.isImageBrowserVisible
    }

    var areBrowserOverlaysVisible: Bool {
        browserOverlayStore.areOverlaysVisible
    }

    var browserDisplayMode: ImageBrowserDisplayMode {
        browserOverlayStore.displayMode
    }

    var browserThumbnailSize: CGFloat {
        browserOverlayStore.thumbnailSize
    }

    var initialOpenBrowserDirectory: URL {
        photoViewerStore.initialOpenBrowserDirectory
    }

    var browserImageURLs: [URL] {
        photoViewerStore.browserImageURLs
    }

    var currentBrowserIndex: Int? {
        photoViewerStore.currentBrowserIndex
    }

    var canShowImageBrowser: Bool {
        photoViewerStore.canShowImageBrowser
    }
}
