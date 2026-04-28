import AppKit
import Foundation
import SwiftUI

@MainActor
final class ViewerState: ObservableObject {
    @Published var index: FolderImageIndex?
    @Published var currentImageURL: URL?
    @Published var currentResolvedImage: NSImage?
    @Published var zoomMode: ZoomMode = .fit(.all) {
        didSet {
            if case let .fit(fitMode) = zoomMode {
                preferredFitMode = fitMode
            }
        }
    }
    @Published var rotationQuarterTurns: Int = 0
    @Published var lastErrorMessage: String?
    @Published var isMetadataVisible = false
    @Published var pageLayout: ViewerPageLayout = .single
    @Published var spreadDirection: SpreadDirection = .leftToRight
    @Published var isCoverModeEnabled = true
    @Published var transientNotice: ViewerTransientNotice?
    @Published var isNavigationCountVisible = false
    @Published var isSlideshowPlaying = false
    @Published var slideshowIntervalSeconds = 3.0
    @Published var postProcessingOptions: Set<ImagePostProcessingOption> = []
    @Published var fitRequestID = 0
    @Published var isImageBrowserVisible = false
    @Published var isOpenBrowserVisible = false
    @Published var imageBrowserDisplayMode: ImageBrowserDisplayMode = .thumbnails
    @Published var imageBrowserThumbnailSize: CGFloat = 132

    static let minimumSlideshowIntervalSeconds = 0.5
    static let maximumSlideshowIntervalSeconds = 60.0
    static let defaultSlideshowIntervalSeconds = 3.0

    let documentLoader: ViewerDocumentLoader
    let preloadQueue: ImagePreloadQueue
    var displayedMagnification: CGFloat = 1.0
    var fitMagnification: CGFloat = 1.0
    var isEntireImageVisible = true
    var preferredFitMode: FitMode = .all
    var pdfDocument: ViewerPDFDocument?
    var navigationCountDismissTask: Task<Void, Never>?
    var slideshowTask: Task<Void, Never>?

    init(
        index: FolderImageIndex? = nil,
        fileManager: FileManager = .default,
        preloadQueue: ImagePreloadQueue = ImagePreloadQueue()
    ) {
        self.index = index
        self.currentImageURL = index.map { $0.imageURLs[$0.currentIndex] }
        self.documentLoader = ViewerDocumentLoader(fileManager: fileManager)
        self.preloadQueue = preloadQueue
        self.currentResolvedImage = currentImageURL.flatMap { preloadQueue.image(for: $0) }
    }

    deinit {
        navigationCountDismissTask?.cancel()
        slideshowTask?.cancel()
    }

    func openFile(at fileURL: URL) {
        do {
            switch try documentLoader.openFile(at: fileURL) {
            case let .imageIndex(index):
                apply(index: index)
            case let .pdf(document):
                apply(pdfDocument: document)
            }
        } catch {
            setError(message: error.localizedDescription)
        }
    }

    func openFolder(at folderURL: URL) {
        do {
            apply(index: try documentLoader.openFolder(at: folderURL))
        } catch {
            setError(message: error.localizedDescription)
        }
    }

    func presentOpenFilePanel() {
        showOpenBrowser()
    }

    func presentOpenSelectionPanel() {
        showOpenBrowser()
    }

    func presentOpenFolderPanel() {
        showOpenBrowser()
    }
}
