import Foundation

extension ViewerState {
    func apply(index: FolderImageIndex, hidesNavigationCount: Bool = true) {
        pdfDocument = nil
        self.index = index
        currentImageURL = index.imageURLs[index.currentIndex]
        currentResolvedImage = currentImageURL.flatMap { preloadQueue.image(for: $0) }
        zoomMode = .fit(preferredFitMode)
        displayedMagnification = 1.0
        fitMagnification = 1.0
        isEntireImageVisible = true
        rotationQuarterTurns = 0
        lastErrorMessage = nil
        isMetadataVisible = false
        transientNotice = nil
        isImageBrowserVisible = false
        isOpenBrowserVisible = false
        if hidesNavigationCount {
            hideNavigationCountImmediately()
        }
        refreshPreloadTargets()
    }

    func apply(pdfDocument document: ViewerPDFDocument) {
        pdfDocument = document
        index = FolderImageIndex(imageURLs: document.pageURLs, currentIndex: 0)
        currentImageURL = document.fileURL
        currentResolvedImage = document.image(at: 0)
        resetViewportForNewContent()
    }

    func applyPDFPage(at pageIndex: Int, hidesNavigationCount: Bool = true) {
        guard isViewingPDF,
              let pdfDocument,
              let pageImage = pdfDocument.image(at: pageIndex) else { return }

        index = FolderImageIndex(imageURLs: pdfDocument.pageURLs, currentIndex: pageIndex)
        currentImageURL = pdfDocument.fileURL
        currentResolvedImage = pageImage
        resetViewportForNewContent(hidesNavigationCount: hidesNavigationCount)
    }

    func resetViewportForNewContent(hidesNavigationCount: Bool = true) {
        zoomMode = .fit(preferredFitMode)
        displayedMagnification = 1.0
        fitMagnification = 1.0
        isEntireImageVisible = true
        rotationQuarterTurns = 0
        lastErrorMessage = nil
        isMetadataVisible = false
        transientNotice = nil
        isImageBrowserVisible = false
        isOpenBrowserVisible = false
        if hidesNavigationCount {
            hideNavigationCountImmediately()
        }
    }

    func refreshPreloadTargets() {
        guard let index else { return }

        let targets = preloadQueue.targetURLs(for: index.imageURLs, currentIndex: index.currentIndex)
        preloadQueue.preload(urls: targets)
    }
}
