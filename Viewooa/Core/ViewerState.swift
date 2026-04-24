import AppKit
import Foundation
import ImageIO
import PDFKit
import SwiftUI

enum FitMode: CaseIterable, Equatable, Identifiable {
    case height
    case width
    case all

    var id: Self { self }

    var title: String {
        switch self {
        case .height:
            "Fit Height"
        case .width:
            "Fit Width"
        case .all:
            "Fit All"
        }
    }

    var shortTitle: String {
        switch self {
        case .height:
            "Height"
        case .width:
            "Width"
        case .all:
            "All"
        }
    }
}

enum ZoomMode: Equatable {
    case fit(FitMode)
    case actualSize
    case custom(CGFloat)

    var isFit: Bool {
        if case .fit = self {
            return true
        }

        return false
    }
}

enum ViewerPageLayout: CaseIterable, Equatable, Identifiable {
    case single
    case spread
    case verticalStrip

    var id: Self { self }

    var title: String {
        switch self {
        case .single:
            "Single Page"
        case .spread:
            "Two Pages"
        case .verticalStrip:
            "Vertical Strip"
        }
    }

    var shortTitle: String {
        switch self {
        case .single:
            "Single"
        case .spread:
            "2-Up"
        case .verticalStrip:
            "Webtoon"
        }
    }
}

enum SpreadDirection: CaseIterable, Equatable, Identifiable {
    case leftToRight
    case rightToLeft

    var id: Self { self }

    var title: String {
        switch self {
        case .leftToRight:
            "Left to Right"
        case .rightToLeft:
            "Right to Left"
        }
    }

    var shortTitle: String {
        switch self {
        case .leftToRight:
            "L-R"
        case .rightToLeft:
            "R-L"
        }
    }
}

enum ImagePostProcessingOption: String, CaseIterable, Equatable, Identifiable {
    case sharpen
    case smooth
    case denoise
    case contrast
    case actualSizeRepair

    var id: Self { self }

    var title: String {
        switch self {
        case .sharpen:
            "Sharpen"
        case .smooth:
            "Smooth"
        case .denoise:
            "Denoise"
        case .contrast:
            "Contrast"
        case .actualSizeRepair:
            "1x Zoom Repair"
        }
    }
}

enum ImageBrowserDisplayMode: String, CaseIterable, Equatable, Identifiable {
    case thumbnails
    case list

    var id: Self { self }

    var title: String {
        switch self {
        case .thumbnails:
            "Thumbnails"
        case .list:
            "List"
        }
    }

    var systemImage: String {
        switch self {
        case .thumbnails:
            "square.grid.3x3"
        case .list:
            "list.bullet"
        }
    }
}

struct ImageMetadataRow: Identifiable, Equatable {
    let label: String
    let value: String

    var id: String { label }
}

struct ViewerTransientNotice: Identifiable, Equatable {
    let id = UUID()
    let message: String
}

private enum ViewerZoom {
    static let step: CGFloat = 1.25
    static let minimumScale: CGFloat = 0.05
    static let maximumScale: CGFloat = 8.0
}

@MainActor
final class ViewerState: ObservableObject {
    @Published var index: FolderImageIndex?
    @Published var currentImageURL: URL?
    @Published private(set) var currentResolvedImage: NSImage?
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
    @Published private(set) var isSlideshowPlaying = false
    @Published private(set) var slideshowIntervalSeconds = 3.0
    @Published var postProcessingOptions: Set<ImagePostProcessingOption> = []
    @Published private(set) var fitRequestID = 0
    @Published var isImageBrowserVisible = false
    @Published var isOpenBrowserVisible = false
    @Published var imageBrowserDisplayMode: ImageBrowserDisplayMode = .thumbnails
    @Published var imageBrowserThumbnailSize: CGFloat = 132

    static let minimumSlideshowIntervalSeconds = 0.5
    static let maximumSlideshowIntervalSeconds = 60.0
    static let defaultSlideshowIntervalSeconds = 3.0

    private let fileManager: FileManager
    private let preloadQueue: ImagePreloadQueue
    private var displayedMagnification: CGFloat = 1.0
    private var fitMagnification: CGFloat = 1.0
    private var isEntireImageVisible = true
    private var preferredFitMode: FitMode = .all
    private var pdfFileURL: URL?
    private var pdfPageImages: [NSImage] = []
    private var pdfPageURLs: [URL] = []
    private var navigationCountDismissTask: Task<Void, Never>?
    private var slideshowTask: Task<Void, Never>?

    init(
        index: FolderImageIndex? = nil,
        fileManager: FileManager = .default,
        preloadQueue: ImagePreloadQueue = ImagePreloadQueue()
    ) {
        self.index = index
        self.currentImageURL = index.map { $0.imageURLs[$0.currentIndex] }
        self.fileManager = fileManager
        self.preloadQueue = preloadQueue
        self.currentResolvedImage = currentImageURL.flatMap { preloadQueue.image(for: $0) }
    }

    deinit {
        navigationCountDismissTask?.cancel()
        slideshowTask?.cancel()
    }

    func openFile(at fileURL: URL) {
        if SupportedImageTypes.isPDF(fileURL) {
            openPDF(at: fileURL)
            return
        }

        guard SupportedImageTypes.isBrowsableImage(fileURL) else {
            setError(message: "The selected file is not a supported image.")
            return
        }

        let folderURL = fileURL.deletingLastPathComponent()

        do {
            let imageURLs = try imageURLs(in: folderURL)

            guard let currentIndex = FolderImageIndex.currentIndex(for: fileURL, in: imageURLs) else {
                setError(message: "The selected image could not be found in its folder.")
                return
            }

            apply(index: FolderImageIndex(imageURLs: imageURLs, currentIndex: currentIndex))
        } catch {
            setError(message: error.localizedDescription)
        }
    }

    func openFolder(at folderURL: URL) {
        do {
            let imageURLs = try imageURLs(in: folderURL)

            guard !imageURLs.isEmpty else {
                setError(message: "The selected folder does not contain supported images.")
                return
            }

            apply(index: FolderImageIndex(imageURLs: imageURLs, currentIndex: 0))
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

    func showNextImage() {
        guard let index else { return }
        let nextIndex = nextImageIndex(from: index.currentIndex, imageCount: index.imageURLs.count)
        guard nextIndex < index.imageURLs.count, nextIndex != index.currentIndex else {
            showTransientNotice("마지막 파일입니다")
            return
        }
        if isViewingPDF {
            applyPDFPage(at: nextIndex, hidesNavigationCount: false)
        } else {
            apply(index: FolderImageIndex(imageURLs: index.imageURLs, currentIndex: nextIndex), hidesNavigationCount: false)
        }
    }

    func showPreviousImage() {
        guard let index else { return }
        let previousIndex = previousImageIndex(from: index.currentIndex)
        guard previousIndex >= 0, previousIndex != index.currentIndex else {
            showTransientNotice("첫번째 파일입니다")
            return
        }
        if isViewingPDF {
            applyPDFPage(at: previousIndex, hidesNavigationCount: false)
        } else {
            apply(index: FolderImageIndex(imageURLs: index.imageURLs, currentIndex: previousIndex), hidesNavigationCount: false)
        }
    }

    func showNextImageFromDirectionalInput() {
        guard isEntireImageVisible else { return }
        showNextImage()
    }

    func showPreviousImageFromDirectionalInput() {
        guard isEntireImageVisible else { return }
        showPreviousImage()
    }

    func showNextImageFromNavigationShortcut() {
        beginNavigationHoldIndicator()
        showNextImage()
        endNavigationHoldIndicator()
    }

    func showPreviousImageFromNavigationShortcut() {
        beginNavigationHoldIndicator()
        showPreviousImage()
        endNavigationHoldIndicator()
    }

    func rotateClockwise() {
        rotationQuarterTurns = (rotationQuarterTurns + 1) % 4
    }

    func toggleMetadataVisibility() {
        isMetadataVisible.toggle()
    }

    func setPageLayout(_ layout: ViewerPageLayout) {
        pageLayout = layout
        fitToWindow(layout == .verticalStrip ? .width : nil)
        restartSlideshowIfNeeded()
    }

    func setSpreadDirection(_ direction: SpreadDirection) {
        spreadDirection = direction
    }

    func toggleCoverMode() {
        isCoverModeEnabled.toggle()
        fitToWindow()
    }

    func toggleActualSize() {
        if case .actualSize = zoomMode {
            fitToWindow()
        } else {
            zoomMode = .actualSize
        }
    }

    func zoomIn() {
        zoomMode = .custom(clampedZoomScale(currentZoomScale * ViewerZoom.step))
    }

    func zoomOut() {
        if zoomMode.isFit, canShowImageBrowser {
            showImageBrowser()
            return
        }

        zoomMode = .custom(clampedZoomScale(currentZoomScale / ViewerZoom.step))
    }

    func fitToWindow(_ fitMode: FitMode? = nil) {
        zoomMode = .fit(fitMode ?? preferredFitMode)
        fitRequestID += 1
    }

    func updateViewportMetrics(displayedMagnification: CGFloat, fitMagnification: CGFloat, isEntireImageVisible: Bool) {
        self.displayedMagnification = displayedMagnification
        self.fitMagnification = fitMagnification
        self.isEntireImageVisible = isEntireImageVisible
    }

    func clearError() {
        lastErrorMessage = nil
    }

    func clearTransientNotice(id: ViewerTransientNotice.ID? = nil) {
        guard id == nil || transientNotice?.id == id else { return }
        transientNotice = nil
    }

    func beginNavigationHoldIndicator() {
        guard index != nil else { return }
        navigationCountDismissTask?.cancel()
        isNavigationCountVisible = true
    }

    func endNavigationHoldIndicator() {
        scheduleNavigationCountDismissal()
    }

    func togglePostProcessing(_ option: ImagePostProcessingOption) {
        if postProcessingOptions.contains(option) {
            postProcessingOptions.remove(option)
        } else {
            postProcessingOptions.insert(option)
        }
    }

    func clearPostProcessing() {
        postProcessingOptions.removeAll()
    }

    func toggleSlideshow() {
        if isSlideshowPlaying {
            stopSlideshow()
        } else {
            startSlideshow()
        }
    }

    func startSlideshow() {
        guard index != nil else { return }
        isSlideshowPlaying = true
        configureSlideshowTask()
    }

    func stopSlideshow() {
        isSlideshowPlaying = false
        slideshowTask?.cancel()
        slideshowTask = nil
    }

    func setSlideshowInterval(_ interval: Double) {
        let clampedInterval = min(max(interval, Self.minimumSlideshowIntervalSeconds), Self.maximumSlideshowIntervalSeconds)
        slideshowIntervalSeconds = (clampedInterval * 2).rounded() / 2
        restartSlideshowIfNeeded()
    }

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
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
           isDirectory.boolValue {
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

    var imageMetadataRows: [ImageMetadataRow] {
        guard let currentImageURL else { return [] }

        var rows: [ImageMetadataRow] = [
            ImageMetadataRow(label: "Name", value: currentImageURL.lastPathComponent)
        ]

        if isViewingPDF, let index {
            rows.append(ImageMetadataRow(label: "Position", value: "Page \(index.currentIndex + 1) / \(index.imageURLs.count)"))
        } else if let index {
            rows.append(
                ImageMetadataRow(
                    label: "Position",
                    value: "\(index.currentIndex + 1) / \(index.imageURLs.count)"
                )
            )
        }

        if let dimensions = imageDimensions(at: currentImageURL) {
            rows.append(ImageMetadataRow(label: "Dimensions", value: "\(dimensions.width) x \(dimensions.height) px"))
        }

        let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .contentTypeKey, .contentModificationDateKey]
        if let values = try? currentImageURL.resourceValues(forKeys: resourceKeys) {
            if let fileSize = values.fileSize {
                rows.append(ImageMetadataRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)))
            }

            if let contentType = values.contentType {
                rows.append(ImageMetadataRow(label: "Type", value: contentType.localizedDescription ?? contentType.identifier))
            }

            if let modificationDate = values.contentModificationDate {
                rows.append(ImageMetadataRow(label: "Modified", value: Self.metadataDateFormatter.string(from: modificationDate)))
            }
        }

        rows.append(ImageMetadataRow(label: "Folder", value: currentImageURL.deletingLastPathComponent().path))
        return rows
    }

    var displayImageURLs: [URL] {
        guard let index else { return [] }

        if isViewingPDF {
            return displayPageIndexes(currentIndex: index.currentIndex, pageCount: index.imageURLs.count)
                .map { pdfPageURLs[$0] }
        }

        switch pageLayout {
        case .single:
            return [index.imageURLs[index.currentIndex]]
        case .spread:
            let indexes = Self.spreadIndexes(
                currentIndex: index.currentIndex,
                imageCount: index.imageURLs.count,
                coverModeEnabled: isCoverModeEnabled
            )
            let orderedIndexes = spreadDirection == .leftToRight ? indexes : indexes.reversed()
            return orderedIndexes.map { index.imageURLs[$0] }
        case .verticalStrip:
            return index.imageURLs
        }
    }

    var displayResolvedImages: [NSImage]? {
        guard isViewingPDF, let index else { return nil }

        return displayPageIndexes(currentIndex: index.currentIndex, pageCount: index.imageURLs.count)
            .map { pdfPageImages[$0] }
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

    var navigationCountText: String? {
        guard let index else { return nil }
        return "\(index.currentIndex + 1) / \(index.imageURLs.count)"
    }

    var canShowPreviousImage: Bool {
        guard let index else { return false }
        let previousIndex = previousImageIndex(from: index.currentIndex)
        return previousIndex >= 0 && previousIndex != index.currentIndex
    }

    var canShowNextImage: Bool {
        guard let index else { return false }
        let nextIndex = nextImageIndex(from: index.currentIndex, imageCount: index.imageURLs.count)
        return nextIndex < index.imageURLs.count && nextIndex != index.currentIndex
    }

    var verticalSlideshowScrollSpeed: CGFloat {
        CGFloat(640.0 / slideshowIntervalSeconds)
    }

    var activeVerticalSlideshowScrollSpeed: CGFloat {
        guard isSlideshowPlaying, pageLayout == .verticalStrip else { return 0 }
        return verticalSlideshowScrollSpeed
    }

    static func spreadIndexes(currentIndex: Int, imageCount: Int, coverModeEnabled: Bool) -> [Int] {
        guard imageCount > 0 else { return [] }

        if coverModeEnabled, currentIndex == 0 {
            return [0]
        }

        let minimumPairIndex = coverModeEnabled ? 1 : 0
        let relativeIndex = max(0, currentIndex - minimumPairIndex)
        let pairStartIndex = minimumPairIndex + (relativeIndex / 2) * 2
        let pairEndIndex = min(pairStartIndex + 1, imageCount - 1)
        return Array(pairStartIndex...pairEndIndex)
    }

    private func imageURLs(in folderURL: URL) throws -> [URL] {
        let contents = try fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return FolderImageIndex.sortedImageURLs(from: contents)
    }

    private func apply(index: FolderImageIndex, hidesNavigationCount: Bool = true) {
        pdfFileURL = nil
        pdfPageImages = []
        pdfPageURLs = []
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

    private func openPDF(at fileURL: URL) {
        guard let document = PDFDocument(url: fileURL), document.pageCount > 0 else {
            setError(message: "The selected PDF could not be opened.")
            return
        }

        let pageImages = (0..<document.pageCount).compactMap { pageIndex -> NSImage? in
            guard let page = document.page(at: pageIndex) else { return nil }
            return Self.renderPDFPage(page)
        }

        guard pageImages.count == document.pageCount else {
            setError(message: "The selected PDF could not be rendered.")
            return
        }

        pdfFileURL = fileURL
        pdfPageImages = pageImages
        pdfPageURLs = (0..<document.pageCount).map { Self.pdfPageURL(for: fileURL, pageIndex: $0) }
        index = FolderImageIndex(imageURLs: pdfPageURLs, currentIndex: 0)
        currentImageURL = fileURL
        currentResolvedImage = pageImages.first
        resetViewportForNewContent()
    }

    private func applyPDFPage(at pageIndex: Int, hidesNavigationCount: Bool = true) {
        guard isViewingPDF,
              let pdfFileURL,
              pdfPageImages.indices.contains(pageIndex) else { return }

        index = FolderImageIndex(imageURLs: pdfPageURLs, currentIndex: pageIndex)
        currentImageURL = pdfFileURL
        currentResolvedImage = pdfPageImages[pageIndex]
        resetViewportForNewContent(hidesNavigationCount: hidesNavigationCount)
    }

    private func resetViewportForNewContent(hidesNavigationCount: Bool = true) {
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

    private func setError(message: String) {
        lastErrorMessage = message
    }

    private func showTransientNotice(_ message: String) {
        transientNotice = ViewerTransientNotice(message: message)
    }

    private func scheduleNavigationCountDismissal() {
        navigationCountDismissTask?.cancel()
        navigationCountDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            isNavigationCountVisible = false
        }
    }

    private func hideNavigationCountImmediately() {
        navigationCountDismissTask?.cancel()
        navigationCountDismissTask = nil
        isNavigationCountVisible = false
    }

    private func restartSlideshowIfNeeded() {
        guard isSlideshowPlaying else { return }
        configureSlideshowTask()
    }

    private func configureSlideshowTask() {
        slideshowTask?.cancel()
        slideshowTask = nil

        guard isSlideshowPlaying, pageLayout != .verticalStrip else { return }

        slideshowTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                try? await Task.sleep(for: .milliseconds(Int(self.slideshowIntervalSeconds * 1000)))
                guard !Task.isCancelled, self.isSlideshowPlaying else { return }

                guard self.canShowNextImage else {
                    self.showTransientNotice("마지막 파일입니다")
                    self.stopSlideshow()
                    return
                }

                self.showNextImage()
            }
        }
    }

    private func nextImageIndex(from currentIndex: Int, imageCount: Int) -> Int {
        guard pageLayout == .spread else { return currentIndex + 1 }

        let currentSpreadStart = Self.spreadIndexes(
            currentIndex: currentIndex,
            imageCount: imageCount,
            coverModeEnabled: isCoverModeEnabled
        ).first ?? currentIndex
        return currentSpreadStart + (isCoverModeEnabled && currentSpreadStart == 0 ? 1 : 2)
    }

    private var isViewingPDF: Bool {
        pdfFileURL != nil
    }

    private func displayPageIndexes(currentIndex: Int, pageCount: Int) -> [Int] {
        switch pageLayout {
        case .single:
            return [currentIndex]
        case .spread:
            let indexes = Self.spreadIndexes(
                currentIndex: currentIndex,
                imageCount: pageCount,
                coverModeEnabled: isCoverModeEnabled
            )
            return spreadDirection == .leftToRight ? indexes : indexes.reversed()
        case .verticalStrip:
            return Array(0..<pageCount)
        }
    }

    private func previousImageIndex(from currentIndex: Int) -> Int {
        guard pageLayout == .spread, let index else { return currentIndex - 1 }

        let currentSpreadStart = Self.spreadIndexes(
            currentIndex: currentIndex,
            imageCount: index.imageURLs.count,
            coverModeEnabled: isCoverModeEnabled
        ).first ?? currentIndex

        if isCoverModeEnabled, currentSpreadStart <= 1 {
            return 0
        }

        let minimumPairIndex = isCoverModeEnabled ? 1 : 0
        return max(minimumPairIndex, currentSpreadStart - 2)
    }

    private var currentZoomScale: CGFloat {
        switch zoomMode {
        case .fit(_):
            displayedMagnification
        case .actualSize:
            1.0
        case let .custom(scale):
            scale
        }
    }

    private func clampedZoomScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, ViewerZoom.minimumScale), ViewerZoom.maximumScale)
    }

    private func refreshPreloadTargets() {
        guard let index else { return }

        let targets = preloadQueue.targetURLs(for: index.imageURLs, currentIndex: index.currentIndex)
        preloadQueue.preload(urls: targets)
    }

    private func imageDimensions(at url: URL) -> (width: Int, height: Int)? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return currentResolvedImage.map { (Int($0.size.width), Int($0.size.height)) }
        }

        return (width, height)
    }

    private static let metadataDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static func renderPDFPage(_ page: PDFPage) -> NSImage {
        let bounds = page.bounds(for: .mediaBox)
        let targetSize = NSSize(width: bounds.width * 2, height: bounds.height * 2)
        return page.thumbnail(of: targetSize, for: .mediaBox)
    }

    private static func pdfPageURL(for fileURL: URL, pageIndex: Int) -> URL {
        var components = URLComponents(url: fileURL, resolvingAgainstBaseURL: false)
        components?.fragment = "page-\(pageIndex + 1)"
        return components?.url ?? fileURL
    }
}
