import AppKit

extension ViewerState {
    func showImageBrowser() {
        guard canShowImageBrowser else { return }
        stopSlideshow()
        isMetadataVisible = false
        isOpenBrowserVisible = false
        isImageBrowserVisible = true
    }

    func hideImageBrowser() {
        isImageBrowserVisible = false
    }

    func showOpenBrowser() {
        stopSlideshow()
        isMetadataVisible = false
        isImageBrowserVisible = false
        isOpenBrowserVisible = true
    }

    func hideOpenBrowser() {
        isOpenBrowserVisible = false
    }

    func openSelectionFromBrowser(_ url: URL) {
        if documentLoader.isDirectory(url) {
            openFolder(at: url)
        } else {
            openFile(at: url)
        }
        isOpenBrowserVisible = false
    }

    func selectImageFromBrowser(at selectedIndex: Int) {
        guard let index,
              !isViewingPDF,
              index.imageURLs.indices.contains(selectedIndex) else { return }

        isImageBrowserVisible = false
        apply(index: FolderImageIndex(imageURLs: index.imageURLs, currentIndex: selectedIndex))
    }

    func setImageBrowserDisplayMode(_ mode: ImageBrowserDisplayMode) {
        imageBrowserDisplayMode = mode
    }

    func setImageBrowserThumbnailSize(_ size: CGFloat) {
        imageBrowserThumbnailSize = min(max(size, 72), 220)
    }

    var browserImageURLs: [URL] {
        guard !isViewingPDF, let index else { return [] }
        return index.imageURLs
    }

    var currentBrowserIndex: Int? {
        guard !isViewingPDF else { return nil }
        return index?.currentIndex
    }

    var canShowImageBrowser: Bool {
        !isViewingPDF && (index?.imageURLs.isEmpty == false)
    }
}
