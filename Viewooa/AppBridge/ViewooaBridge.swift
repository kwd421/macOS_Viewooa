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

    func setBrowserDisplayMode(_ mode: BrowserDisplayMode) {
        browserOverlayStore.setDisplayMode(mode)
    }

    func setBrowserThumbnailSize(_ size: CGFloat) {
        browserOverlayStore.setThumbnailSize(size)
    }

    var isOpenBrowserVisible: Bool {
        browserOverlayStore.isOpenBrowserVisible
    }

    var areBrowserOverlaysVisible: Bool {
        browserOverlayStore.areOverlaysVisible
    }

    var browserDisplayMode: BrowserDisplayMode {
        browserOverlayStore.displayMode
    }

    var browserThumbnailSize: CGFloat {
        browserOverlayStore.thumbnailSize
    }

    var initialOpenBrowserDirectory: URL {
        photoViewerStore.initialOpenBrowserDirectory
    }
}
