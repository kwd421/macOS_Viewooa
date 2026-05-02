import AppKit
import Combine
import Foundation

@MainActor
protocol PhotoViewerControlling: ObservableObject {
    var currentImageURL: URL? { get }
    var isMetadataVisible: Bool { get }
    var imageMetadataRows: [ImageMetadataRow] { get }
    var isNavigationCountVisible: Bool { get }
    var navigationCountText: String? { get }
    var imageCount: Int { get }
    var lastErrorMessage: String? { get }
    var transientNotice: ViewerTransientNotice? { get }
    var slideshowIntervalSeconds: Double { get }
    var pageLayout: ViewerPageLayout { get }
    var spreadDirection: SpreadDirection { get }
    var isCoverModeEnabled: Bool { get }
    var zoomMode: ZoomMode { get }
    var selectedFitMode: FitMode { get }
    var zoomPercentageText: String? { get }
    var isZoomPercentageVisible: Bool { get }
    var isSlideshowPlaying: Bool { get }
    var hasAnimatedImageFrames: Bool { get }
    var animatedImageFrameText: String? { get }
    var isAnimatedImagePlaying: Bool { get }
    var imageViewerConfiguration: ImageViewerContainerConfiguration { get }

    func imageViewerActions() -> ImageViewerContainerActions
    func clearError()
    func clearTransientNotice(id noticeID: ViewerTransientNotice.ID)
    func toggleMetadataVisibility()
    func setPageLayout(_ layout: ViewerPageLayout)
    func setSpreadDirection(_ direction: SpreadDirection)
    func toggleCoverMode()
    func fitToWindow(_ fitMode: FitMode)
    func toggleSlideshow()
    func setSlideshowInterval(_ seconds: Double)
    func zoomIn()
    func rotateClockwise()
    func showPreviousImageFromNavigationShortcut()
    func showNextImageFromNavigationShortcut()
    func beginNavigationHoldIndicator()
    func endNavigationHoldIndicator()
    func toggleActualSize()
    func showPreviousAnimatedImageFrame()
    func toggleAnimatedImagePlayback()
    func showNextAnimatedImageFrame()
}

@MainActor
final class PhotoViewerStore: PhotoViewerControlling {
    private let viewerState: ViewerState
    private var viewerStateObserver: AnyCancellable?

    init(viewerState: ViewerState) {
        self.viewerState = viewerState
        viewerStateObserver = viewerState.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var currentImageURL: URL? { viewerState.currentImageURL }
    var isMetadataVisible: Bool { viewerState.isMetadataVisible }
    var imageMetadataRows: [ImageMetadataRow] { viewerState.imageMetadataRows }
    var isNavigationCountVisible: Bool { viewerState.isNavigationCountVisible }
    var navigationCountText: String? { viewerState.navigationCountText }
    var imageCount: Int { viewerState.index?.imageURLs.count ?? 0 }
    var lastErrorMessage: String? { viewerState.lastErrorMessage }
    var transientNotice: ViewerTransientNotice? { viewerState.transientNotice }
    var slideshowIntervalSeconds: Double { viewerState.slideshowIntervalSeconds }
    var pageLayout: ViewerPageLayout { viewerState.pageLayout }
    var spreadDirection: SpreadDirection { viewerState.spreadDirection }
    var isCoverModeEnabled: Bool { viewerState.isCoverModeEnabled }
    var zoomMode: ZoomMode { viewerState.zoomMode }
    var selectedFitMode: FitMode { viewerState.preferredFitMode }
    var zoomPercentageText: String? { viewerState.zoomPercentageText }
    var isZoomPercentageVisible: Bool { viewerState.isZoomPercentageVisible }
    var isSlideshowPlaying: Bool { viewerState.isSlideshowPlaying }
    var hasAnimatedImageFrames: Bool { viewerState.hasAnimatedImageFrames }
    var animatedImageFrameText: String? { viewerState.animatedImageFrameText }
    var isAnimatedImagePlaying: Bool { viewerState.isAnimatedImagePlaying }
    var initialOpenBrowserDirectory: URL {
        guard let directory = viewerState.currentImageURL?.deletingLastPathComponent() else {
            return FileManager.default.homeDirectoryForCurrentUser
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return FileManager.default.homeDirectoryForCurrentUser
        }

        return directory
    }

    var imageViewerConfiguration: ImageViewerContainerConfiguration {
        ImageViewerContainerConfiguration(
            resolvedImage: viewerState.currentResolvedImage,
            resolvedImages: viewerState.displayResolvedImages,
            imageURL: viewerState.currentImageURL,
            imageURLs: viewerState.displayImageURLs,
            imageRevision: viewerState.imageRevision,
            zoomMode: viewerState.zoomMode,
            rotationQuarterTurns: viewerState.rotationQuarterTurns,
            pageLayout: viewerState.pageLayout,
            fitRequestID: viewerState.fitRequestID,
            postProcessingOptions: viewerState.postProcessingOptions,
            verticalAutoScrollScreenSpeed: viewerState.activeVerticalSlideshowScrollSpeed
        )
    }

    func imageViewerActions() -> ImageViewerContainerActions {
        ImageViewerContainerActions(
            onZoomModeChange: setZoomMode,
            onViewportMetricsChange: updateViewportMetrics,
            onNavigate: navigate,
            onToggleMetadata: toggleMetadataVisibility,
            onNavigationHoldChange: setNavigationHoldIndicatorVisible,
            onPostProcessingToggle: togglePostProcessing,
            onPostProcessingClear: clearPostProcessing,
            onVerticalSlideshowReachedEnd: stopSlideshow
        )
    }

    func clearError() {
        viewerState.clearError()
    }

    func clearTransientNotice(id noticeID: ViewerTransientNotice.ID) {
        viewerState.clearTransientNotice(id: noticeID)
    }

    func toggleMetadataVisibility() {
        viewerState.toggleMetadataVisibility()
    }

    func hideMetadata() {
        viewerState.isMetadataVisible = false
    }

    func openSelection(at url: URL) {
        if viewerState.documentLoader.isDirectory(url) {
            viewerState.openFolder(at: url)
        } else {
            viewerState.openFile(at: url)
        }
    }

    func setPageLayout(_ layout: ViewerPageLayout) {
        viewerState.setPageLayout(layout)
    }

    func setSpreadDirection(_ direction: SpreadDirection) {
        viewerState.setSpreadDirection(direction)
    }

    func toggleCoverMode() {
        viewerState.toggleCoverMode()
    }

    func fitToWindow(_ fitMode: FitMode) {
        viewerState.fitToWindow(fitMode)
    }

    func toggleSlideshow() {
        viewerState.toggleSlideshow()
    }

    func setSlideshowInterval(_ seconds: Double) {
        viewerState.setSlideshowInterval(seconds)
    }

    func zoomIn() {
        viewerState.zoomIn()
    }

    func zoomOut() {
        viewerState.zoomOut()
    }

    func zoomToActualSize() {
        viewerState.zoomMode = .actualSize
        viewerState.showZoomPercentage(for: 1.0)
    }

    func zoomToFit(_ mode: FitMode) {
        viewerState.fitToWindow(mode)
    }

    func rotateClockwise() {
        viewerState.rotateClockwise()
    }

    func showPreviousImageFromNavigationShortcut() {
        viewerState.showPreviousImageFromNavigationShortcut()
    }

    func showNextImageFromNavigationShortcut() {
        viewerState.showNextImageFromNavigationShortcut()
    }

    func beginNavigationHoldIndicator() {
        viewerState.beginNavigationHoldIndicator()
    }

    func endNavigationHoldIndicator() {
        viewerState.endNavigationHoldIndicator()
    }

    func toggleActualSize() {
        viewerState.toggleActualSize()
    }

    func showPreviousAnimatedImageFrame() {
        viewerState.showPreviousAnimatedImageFrame()
    }

    func toggleAnimatedImagePlayback() {
        viewerState.toggleAnimatedImagePlayback()
    }

    func showNextAnimatedImageFrame() {
        viewerState.showNextAnimatedImageFrame()
    }

    private func setZoomMode(_ zoomMode: ZoomMode) {
        guard viewerState.zoomMode != zoomMode else { return }
        viewerState.setZoomModeFromViewer(zoomMode)
    }

    private func updateViewportMetrics(
        displayedMagnification: CGFloat,
        fitMagnification: CGFloat,
        isEntireImageVisible: Bool
    ) {
        viewerState.updateViewportMetrics(
            displayedMagnification: displayedMagnification,
            fitMagnification: fitMagnification,
            isEntireImageVisible: isEntireImageVisible
        )
    }

    private func navigate(_ direction: ImageViewerNSView.NavigationDirection) {
        switch direction {
        case .previous:
            viewerState.showPreviousImageFromNavigationShortcut()
        case .next:
            viewerState.showNextImageFromNavigationShortcut()
        }
    }

    private func setNavigationHoldIndicatorVisible(_ isVisible: Bool) {
        if isVisible {
            viewerState.beginNavigationHoldIndicator()
        } else {
            viewerState.endNavigationHoldIndicator()
        }
    }

    private func togglePostProcessing(_ option: ImagePostProcessingOption) {
        viewerState.togglePostProcessing(option)
    }

    private func clearPostProcessing() {
        viewerState.clearPostProcessing()
    }

    func stopSlideshow() {
        viewerState.stopSlideshow()
    }
}
