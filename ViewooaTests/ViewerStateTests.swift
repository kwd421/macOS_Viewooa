import XCTest
import PDFKit
import SwiftUI
@testable import Viewooa

final class ViewerStateTests: XCTestCase {
    private static func mouseEvent(location: NSPoint) throws -> NSEvent {
        try XCTUnwrap(
            NSEvent.mouseEvent(
                with: .leftMouseDragged,
                location: location,
                modifierFlags: [],
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                eventNumber: 0,
                clickCount: 1,
                pressure: 1
            )
        )
    }

    @MainActor
    func testNavigationPublishesPreloadedImageForDisplay() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]
        let preloadedImage = NSImage(size: NSSize(width: 40, height: 20))
        let preloadQueue = ImagePreloadQueue()
        preloadQueue.store(preloadedImage, for: urls[1])

        let state = ViewerState(
            index: FolderImageIndex(imageURLs: urls, currentIndex: 0),
            preloadQueue: preloadQueue
        )

        state.showNextImage()

        XCTAssertTrue(state.currentResolvedImage === preloadedImage)
    }

    @MainActor
    func testImageViewerUsesResolvedImageBeforeLoadingFromURL() {
        let viewer = ImageViewerNSView()
        let resolvedImage = NSImage(size: NSSize(width: 80, height: 30))

        viewer.apply(
            resolvedImage: resolvedImage,
            imageURL: URL(fileURLWithPath: "/tmp/does-not-exist.jpg"),
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )

        XCTAssertTrue(viewer.displayedImage === resolvedImage)
    }

    @MainActor
    func testRotationKeepsSourceImageAndUpdatesDisplayedSize() {
        let viewer = ImageViewerNSView()
        let resolvedImage = NSImage(size: NSSize(width: 80, height: 30))

        viewer.apply(
            resolvedImage: resolvedImage,
            imageURL: URL(fileURLWithPath: "/tmp/rotated.jpg"),
            zoomMode: .fit(.all),
            rotationQuarterTurns: 1
        )

        XCTAssertTrue(viewer.displayedImage === resolvedImage)
        XCTAssertEqual(viewer.displayedImageSize.width, 30, accuracy: 0.001)
        XCTAssertEqual(viewer.displayedImageSize.height, 80, accuracy: 0.001)
    }

    @MainActor
    func testAppUsesSingleWindowScene() {
        let sceneType = String(
            reflecting: type(of: ViewooaApp.makeViewerScene(bridge: ViewooaBridge()))
        )

        XCTAssertTrue(sceneType.contains("Window<"))
    }

    @MainActor
    func testViewerWindowShellAcceptsInjectedBridge() {
        let bridge = ViewooaBridge()

        _ = ViewerWindowShell(bridge: bridge)
    }

    @MainActor
    func testBrowserFeatureHostDoesNotRequireBridge() {
        var displayMode = ImageBrowserDisplayMode.thumbnails
        var thumbnailSize: CGFloat = 132

        _ = BrowserFeatureHostView(
            isImageBrowserVisible: false,
            isOpenBrowserVisible: false,
            imageURLs: [],
            currentIndex: nil,
            initialDirectory: FileManager.default.homeDirectoryForCurrentUser,
            displayMode: Binding(
                get: { displayMode },
                set: { displayMode = $0 }
            ),
            thumbnailSize: Binding(
                get: { thumbnailSize },
                set: { thumbnailSize = $0 }
            ),
            onSelectImage: { _ in },
            onOpen: { _ in },
            onDismissImageBrowser: {},
            onDismissOpenBrowser: {}
        )
    }

    @MainActor
    func testImageViewerContainerDoesNotRequireViewerState() {
        _ = ImageViewerContainerView(
            configuration: ImageViewerContainerConfiguration(
                resolvedImage: nil,
                resolvedImages: nil,
                imageURL: nil,
                imageURLs: nil,
                zoomMode: .fit(.all),
                rotationQuarterTurns: 0,
                pageLayout: .single,
                fitRequestID: 0,
                postProcessingOptions: [],
                verticalAutoScrollScreenSpeed: 0
            ),
            actions: ImageViewerContainerActions(
                onZoomModeChange: { _ in },
                onViewportMetricsChange: { _, _, _ in },
                onNavigate: { _ in },
                onToggleMetadata: {},
                onNavigationHoldChange: { _ in },
                onPostProcessingToggle: { _ in },
                onPostProcessingClear: {},
                onVerticalSlideshowReachedEnd: {},
                onFitZoomOutRequest: { false }
            )
        )
    }

    @MainActor
    func testPhotoViewerFeatureUsesStoreBoundary() {
        let store = PhotoViewerStore(viewerState: ViewerState())

        _ = PhotoViewerFeatureView(
            store: store,
            areBrowserOverlaysVisible: false,
            onOpenBrowser: {},
            onZoomOut: {},
            onFitZoomOutRequest: { false }
        )
    }

    @MainActor
    func testBridgeCanBeComposedFromFeatureStores() {
        let photoViewerStore = PhotoViewerStore(viewerState: ViewerState())
        let browserOverlayStore = BrowserOverlayStore()

        let bridge = ViewooaBridge(
            photoViewerStore: photoViewerStore,
            browserOverlayStore: browserOverlayStore
        )

        bridge.presentOpenBrowser()

        XCTAssertTrue(browserOverlayStore.isOpenBrowserVisible)
        XCTAssertTrue(bridge.isOpenBrowserVisible)
    }

    @MainActor
    func testBrowserOverlayStoreOwnsOverlayStateAndThumbnailRange() {
        let store = BrowserOverlayStore()

        store.showOpenBrowser()
        XCTAssertTrue(store.isOpenBrowserVisible)
        XCTAssertFalse(store.isImageBrowserVisible)

        store.showImageBrowser()
        XCTAssertFalse(store.isOpenBrowserVisible)
        XCTAssertTrue(store.isImageBrowserVisible)

        store.setThumbnailSize(12)
        XCTAssertEqual(store.thumbnailSize, 72)

        store.setThumbnailSize(500)
        XCTAssertEqual(store.thumbnailSize, 220)
    }

    @MainActor
    func testDefaultZoomModeFitsAll() {
        let state = ViewerState()

        XCTAssertEqual(state.zoomMode, .fit(.all))
    }

    @MainActor
    func testNextAdvancesIndex() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.showNextImage()

        XCTAssertEqual(state.index?.currentIndex, 1)
    }

    @MainActor
    func testNextAtLastImagePublishesLastFileNotice() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 1))
        state.showNextImage()

        XCTAssertEqual(state.index?.currentIndex, 1)
        XCTAssertEqual(state.transientNotice?.message, "마지막 파일입니다")
    }

    @MainActor
    func testPreviousAtFirstImagePublishesFirstFileNotice() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.showPreviousImage()

        XCTAssertEqual(state.index?.currentIndex, 0)
        XCTAssertEqual(state.transientNotice?.message, "첫번째 파일입니다")
    }

    @MainActor
    func testBoundaryNoticeCanBeTriggeredRepeatedly() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 1))
        state.showNextImage()
        let firstNoticeID = state.transientNotice?.id

        state.showNextImage()

        XCTAssertNotEqual(state.transientNotice?.id, firstNoticeID)
        XCTAssertEqual(state.transientNotice?.message, "마지막 파일입니다")
    }

    @MainActor
    func testNavigationHoldIndicatorShowsCurrentPosition() async {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg"),
            URL(fileURLWithPath: "/tmp/c.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 1))
        state.beginNavigationHoldIndicator()

        XCTAssertTrue(state.isNavigationCountVisible)
        XCTAssertEqual(state.navigationCountText, "2 / 3")

        state.endNavigationHoldIndicator()

        XCTAssertTrue(state.isNavigationCountVisible)

        try? await Task.sleep(for: .milliseconds(1100))

        XCTAssertFalse(state.isNavigationCountVisible)
    }

    @MainActor
    func testNavigationHoldIndicatorStaysVisibleWhileAdvancing() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg"),
            URL(fileURLWithPath: "/tmp/c.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.beginNavigationHoldIndicator()
        state.showNextImage()

        XCTAssertTrue(state.isNavigationCountVisible)
        XCTAssertEqual(state.navigationCountText, "2 / 3")
    }

    @MainActor
    func testNavigationShortcutShowsCountAndHidesAfterIdleDelay() async {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg"),
            URL(fileURLWithPath: "/tmp/c.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.showNextImageFromNavigationShortcut()

        XCTAssertEqual(state.index?.currentIndex, 1)
        XCTAssertTrue(state.isNavigationCountVisible)
        XCTAssertEqual(state.navigationCountText, "2 / 3")

        try? await Task.sleep(for: .milliseconds(600))
        state.showNextImageFromNavigationShortcut()

        XCTAssertEqual(state.index?.currentIndex, 2)
        XCTAssertTrue(state.isNavigationCountVisible)
        XCTAssertEqual(state.navigationCountText, "3 / 3")

        try? await Task.sleep(for: .milliseconds(600))
        XCTAssertTrue(state.isNavigationCountVisible)

        try? await Task.sleep(for: .milliseconds(550))
        XCTAssertFalse(state.isNavigationCountVisible)
    }

    @MainActor
    func testPostProcessingOptionsToggleAndClear() {
        let state = ViewerState()

        state.togglePostProcessing(.sharpen)
        XCTAssertEqual(state.postProcessingOptions, [.sharpen])

        state.togglePostProcessing(.smooth)
        XCTAssertEqual(state.postProcessingOptions, [.sharpen, .smooth])

        state.togglePostProcessing(.sharpen)
        XCTAssertEqual(state.postProcessingOptions, [.smooth])

        state.clearPostProcessing()
        XCTAssertTrue(state.postProcessingOptions.isEmpty)
    }

    @MainActor
    func testSlideshowIntervalClampsAndDrivesVerticalSpeed() {
        let state = ViewerState()

        state.setSlideshowInterval(0.1)
        XCTAssertEqual(state.slideshowIntervalSeconds, ViewerState.minimumSlideshowIntervalSeconds)

        state.setSlideshowInterval(4.0)
        XCTAssertEqual(state.slideshowIntervalSeconds, 4.0)
        XCTAssertEqual(state.verticalSlideshowScrollSpeed, 160, accuracy: 0.001)

        state.setSlideshowInterval(100)
        XCTAssertEqual(state.slideshowIntervalSeconds, ViewerState.maximumSlideshowIntervalSeconds)
    }

    @MainActor
    func testVerticalSlideshowPublishesActiveScrollSpeedOnlyWhenPlayingInVerticalMode() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]
        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))

        state.startSlideshow()
        XCTAssertEqual(state.activeVerticalSlideshowScrollSpeed, 0)

        state.setPageLayout(.verticalStrip)
        XCTAssertGreaterThan(state.activeVerticalSlideshowScrollSpeed, 0)

        state.stopSlideshow()
        XCTAssertEqual(state.activeVerticalSlideshowScrollSpeed, 0)
    }

    @MainActor
    func testVerticalAutoScrollOriginMovesDownAndClampsAtBottom() {
        let origin = ImageViewerNSView.verticalAutoScrollOrigin(
            currentOrigin: NSPoint(x: 10, y: 500),
            documentSize: NSSize(width: 1000, height: 1200),
            viewportSize: NSSize(width: 500, height: 300),
            magnification: 1,
            screenPointDelta: 160
        )

        XCTAssertEqual(origin.x, 10, accuracy: 0.001)
        XCTAssertEqual(origin.y, 340, accuracy: 0.001)

        let clampedOrigin = ImageViewerNSView.verticalAutoScrollOrigin(
            currentOrigin: NSPoint(x: 10, y: 80),
            documentSize: NSSize(width: 1000, height: 1200),
            viewportSize: NSSize(width: 500, height: 300),
            magnification: 1,
            screenPointDelta: 160
        )

        XCTAssertEqual(clampedOrigin.y, 0, accuracy: 0.001)
    }

    @MainActor
    func testDirectionalInputAdvancesIndexWhenEntireImageIsVisible() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.updateViewportMetrics(displayedMagnification: 0.8, fitMagnification: 1.0, isEntireImageVisible: true)

        state.showNextImageFromDirectionalInput()

        XCTAssertEqual(state.index?.currentIndex, 1)
    }

    @MainActor
    func testDirectionalInputDoesNotAdvanceIndexWhenImageExceedsViewport() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.updateViewportMetrics(displayedMagnification: 1.8, fitMagnification: 1.0, isEntireImageVisible: false)

        state.showNextImageFromDirectionalInput()

        XCTAssertEqual(state.index?.currentIndex, 0)
    }

    @MainActor
    func testNavigationResetsZoomModeToFit() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.zoomMode = .actualSize
        state.showNextImage()

        XCTAssertEqual(state.zoomMode, .fit(.all))
    }

    @MainActor
    func testNavigationPreservesSelectedFitMode() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.fitToWindow(.all)
        state.zoomMode = .actualSize
        state.showNextImage()

        XCTAssertEqual(state.zoomMode, .fit(.all))
    }

    @MainActor
    func testSpreadModeUsesCoverPageBeforePairingImages() {
        XCTAssertEqual(
            ViewerState.spreadIndexes(currentIndex: 0, imageCount: 5, coverModeEnabled: true),
            [0]
        )
        XCTAssertEqual(
            ViewerState.spreadIndexes(currentIndex: 1, imageCount: 5, coverModeEnabled: true),
            [1, 2]
        )
        XCTAssertEqual(
            ViewerState.spreadIndexes(currentIndex: 3, imageCount: 5, coverModeEnabled: true),
            [3, 4]
        )
    }

    @MainActor
    func testSpreadModeNavigationAdvancesByVisiblePair() {
        let urls = (0..<5).map { URL(fileURLWithPath: "/tmp/\($0).jpg") }
        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.setPageLayout(.spread)

        state.showNextImage()
        XCTAssertEqual(state.index?.currentIndex, 1)

        state.showNextImage()
        XCTAssertEqual(state.index?.currentIndex, 3)

        state.showPreviousImage()
        XCTAssertEqual(state.index?.currentIndex, 1)

        state.showPreviousImage()
        XCTAssertEqual(state.index?.currentIndex, 0)
    }

    @MainActor
    func testActualSizeButtonTogglesBackToFit() {
        let state = ViewerState()

        state.toggleActualSize()
        XCTAssertEqual(state.zoomMode, .actualSize)

        state.toggleActualSize()
        XCTAssertEqual(state.zoomMode, .fit(.all))
    }

    @MainActor
    func testZoomInFromFitUsesDefaultIncrement() {
        let state = ViewerState()

        state.zoomIn()

        XCTAssertEqual(state.zoomMode, .custom(1.25))
    }

    @MainActor
    func testZoomInFromFitUsesDisplayedMagnificationAsBase() {
        let state = ViewerState()
        state.updateViewportMetrics(displayedMagnification: 0.4, fitMagnification: 0.4, isEntireImageVisible: true)

        state.zoomIn()

        XCTAssertEqual(state.zoomMode, .custom(0.5))
    }

    @MainActor
    func testZoomOutFromFitWithoutImageBrowserUsesDefaultIncrement() {
        let state = ViewerState()

        state.zoomOut()

        XCTAssertEqual(state.zoomMode, .custom(0.8))
    }

    @MainActor
    func testZoomOutFromFitWithoutImageBrowserUsesDisplayedMagnificationAsBase() {
        let state = ViewerState()
        state.updateViewportMetrics(displayedMagnification: 0.4, fitMagnification: 0.4, isEntireImageVisible: true)

        state.zoomOut()

        XCTAssertEqual(state.zoomMode, .custom(0.32))
    }

    @MainActor
    func testZoomOutFromFitWithFolderImagesShowsImageBrowser() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]
        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        let bridge = ViewooaBridge(viewerState: state)

        bridge.zoomOut()

        XCTAssertTrue(bridge.isImageBrowserVisible)
        XCTAssertEqual(state.zoomMode, .fit(.all))
    }

    @MainActor
    func testSelectingImageFromBrowserUpdatesCurrentImageAndHidesBrowser() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg"),
            URL(fileURLWithPath: "/tmp/c.jpg")
        ]
        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        let bridge = ViewooaBridge(viewerState: state)
        bridge.showImageBrowser()

        bridge.selectImageFromBrowser(at: 2)

        XCTAssertFalse(bridge.isImageBrowserVisible)
        XCTAssertEqual(state.index?.currentIndex, 2)
        XCTAssertEqual(state.currentImageURL, urls[2])
    }

    @MainActor
    func testImageBrowserThumbnailSizeClampsToFinderLikeRange() {
        let bridge = ViewooaBridge()

        bridge.setBrowserThumbnailSize(12)
        XCTAssertEqual(bridge.browserThumbnailSize, 72)

        bridge.setBrowserThumbnailSize(500)
        XCTAssertEqual(bridge.browserThumbnailSize, 220)
    }

    @MainActor
    func testZoomOutFromActualSizeUsesSmallerStep() {
        let state = ViewerState()
        state.zoomMode = .actualSize

        state.zoomOut()

        XCTAssertEqual(state.zoomMode, .custom(0.8))
    }

    @MainActor
    func testRotateClockwiseWrapsAfterFullTurn() {
        let state = ViewerState()

        for _ in 0..<5 {
            state.rotateClockwise()
        }

        XCTAssertEqual(state.rotationQuarterTurns, 1)
    }

    @MainActor
    func testErrorDoesNotClearCurrentImageSelection() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]
        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 1))

        state.openFile(at: URL(fileURLWithPath: "/tmp/not-an-image.txt"))

        XCTAssertEqual(state.currentImageURL, urls[1])
        XCTAssertEqual(state.index?.currentIndex, 1)
        XCTAssertEqual(state.lastErrorMessage, "The selected file is not a supported image.")
    }

    @MainActor
    func testOpeningPDFDirectlyDisplaysItsPagesWithoutFolderImages() throws {
        let pdfURL = try makeTemporaryPDF(pageCount: 2)
        let state = ViewerState()

        state.openFile(at: pdfURL)

        XCTAssertEqual(state.currentImageURL, pdfURL)
        XCTAssertEqual(state.index?.imageURLs.count, 2)
        XCTAssertNotNil(state.currentResolvedImage)
        XCTAssertEqual(state.displayResolvedImages?.count, 1)

        state.showNextImage()

        XCTAssertEqual(state.index?.currentIndex, 1)
        XCTAssertEqual(state.currentImageURL, pdfURL)
        XCTAssertNotNil(state.currentResolvedImage)
    }

    @MainActor
    func testInteractiveMagnificationReportsCustomZoomMode() {
        let viewer = ImageViewerNSView()
        var reportedZoomMode: ZoomMode?

        viewer.onZoomModeChange = { zoomMode in
            reportedZoomMode = zoomMode
        }

        viewer.handleMagnificationChange(2.5, isUserInitiated: true)

        XCTAssertEqual(reportedZoomMode, .custom(2.5))
    }

    @MainActor
    func testProgrammaticMagnificationDoesNotReportCustomZoomMode() {
        let viewer = ImageViewerNSView()
        var didReportZoomMode = false

        viewer.onZoomModeChange = { _ in
            didReportZoomMode = true
        }

        viewer.handleMagnificationChange(1.0, isUserInitiated: false)

        XCTAssertFalse(didReportZoomMode)
    }

    @MainActor
    func testOpeningNewImageAppliesFitImmediatelyWithoutZoomAnimation() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 620),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        let viewer = ImageViewerNSView(frame: window.contentView?.bounds ?? .zero)
        window.contentView = viewer
        viewer.layoutSubtreeIfNeeded()

        viewer.apply(
            resolvedImage: NSImage(size: NSSize(width: 300, height: 200)),
            imageURL: URL(fileURLWithPath: "/tmp/first.png"),
            zoomMode: .custom(2.0),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        viewer.apply(
            resolvedImage: NSImage(size: NSSize(width: 1086, height: 1448)),
            imageURL: URL(fileURLWithPath: "/tmp/second.png"),
            zoomMode: .fit(.all),
            rotationQuarterTurns: 0
        )

        let expectedFit = ImageViewerNSView.fitMagnification(
            imageSize: NSSize(width: 1086, height: 1448),
            viewportSize: NSSize(width: 900, height: 620),
            fitMode: .all,
            minimumMagnification: viewer.scrollView.minMagnification,
            maximumMagnification: viewer.scrollView.maxMagnification
        )

        XCTAssertEqual(viewer.scrollView.magnification, expectedFit, accuracy: 0.001)
        XCTAssertTrue(viewer.isEntireImageVisible)
    }

    private func makeTemporaryPDF(pageCount: Int) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        let document = PDFDocument()

        for pageIndex in 0..<pageCount {
            let image = NSImage(size: NSSize(width: 120, height: 160))
            image.lockFocus()
            NSColor.white.setFill()
            NSRect(x: 0, y: 0, width: 120, height: 160).fill()
            NSString(string: "\(pageIndex + 1)").draw(at: NSPoint(x: 52, y: 72))
            image.unlockFocus()

            guard let page = PDFPage(image: image) else {
                throw NSError(domain: "ViewooaTests", code: 1)
            }
            document.insert(page, at: pageIndex)
        }

        XCTAssertTrue(document.write(to: url))
        return url
    }

    @MainActor
    func testDoubleClickFromFitSwitchesToActualSize() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var reportedZoomMode: ZoomMode?

        viewer.onZoomModeChange = { zoomMode in
            reportedZoomMode = zoomMode
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        XCTAssertTrue(viewer.handleDoubleClick())
        XCTAssertEqual(reportedZoomMode, .actualSize)
    }

    @MainActor
    func testDoubleClickFromFitKeepsClickedImagePointAnchoredAfterActualSizeRelayout() throws {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 900, height: 620)
        let imageSize = NSSize(width: 1600, height: 1200)
        let image = NSImage(size: imageSize)

        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .fit(.all),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        let scrollView = try XCTUnwrap(viewer.subviews.compactMap { $0 as? NSScrollView }.first)
        let clickedImagePoint = NSPoint(x: 1200, y: 600)
        let currentImageFrame = ImageViewerNSView.centeredImageFrame(
            imageSize: imageSize,
            containerSize: scrollView.documentView?.bounds.size ?? .zero
        )
        let clickedDocumentPoint = ImageViewerNSView.documentPoint(
            forImagePoint: clickedImagePoint,
            imageFrame: currentImageFrame
        )
        let anchorUnitPoint = ImageViewerNSView.anchorUnitPoint(
            anchorDocumentPoint: clickedDocumentPoint,
            visibleRect: scrollView.contentView.bounds
        )

        XCTAssertTrue(viewer.handleDoubleClick(anchoredAtDocumentPoint: clickedDocumentPoint))

        let actualContainerSize = ImageViewerNSView.documentContainerSize(
            imageSize: imageSize,
            viewportSize: scrollView.bounds.size,
            magnification: 1.0
        )
        let actualImageFrame = ImageViewerNSView.centeredImageFrame(
            imageSize: imageSize,
            containerSize: actualContainerSize
        )
        let expectedDocumentPoint = ImageViewerNSView.documentPoint(
            forImagePoint: clickedImagePoint,
            imageFrame: actualImageFrame
        )
        let expectedOrigin = ImageViewerNSView.visibleRectOrigin(
            anchoring: expectedDocumentPoint,
            at: anchorUnitPoint,
            containerSize: actualContainerSize,
            viewportSize: scrollView.bounds.size,
            magnification: 1.0
        )

        XCTAssertEqual(scrollView.magnification, 1.0, accuracy: 0.001)
        XCTAssertEqual(scrollView.contentView.bounds.origin.x, expectedOrigin.x, accuracy: 0.001)
        XCTAssertEqual(scrollView.contentView.bounds.origin.y, expectedOrigin.y, accuracy: 0.001)
        XCTAssertNotEqual(scrollView.contentView.bounds.origin.x, 750, accuracy: 0.001)
    }

    @MainActor
    func testFastRepeatedDoubleClickActivatesOnFourthClickCount() {
        XCTAssertFalse(ImageViewerClickActivation.isDoubleClickActivation(clickCount: 1))
        XCTAssertTrue(ImageViewerClickActivation.isDoubleClickActivation(clickCount: 2))
        XCTAssertFalse(ImageViewerClickActivation.isDoubleClickActivation(clickCount: 3))
        XCTAssertTrue(ImageViewerClickActivation.isDoubleClickActivation(clickCount: 4))
    }

    func testFastRepeatedDoubleClickConsumesThirdClickWithoutToggling() {
        XCTAssertFalse(ImageViewerClickActivation.isMultiClickContinuation(clickCount: 1))
        XCTAssertFalse(ImageViewerClickActivation.isMultiClickContinuation(clickCount: 2))
        XCTAssertTrue(ImageViewerClickActivation.isMultiClickContinuation(clickCount: 3))
        XCTAssertFalse(ImageViewerClickActivation.isMultiClickContinuation(clickCount: 4))
    }

    @MainActor
    func testDoubleClickFromCustomZoomSwitchesToFit() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var reportedZoomMode: ZoomMode?

        viewer.onZoomModeChange = { zoomMode in
            reportedZoomMode = zoomMode
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .custom(1.6),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        XCTAssertTrue(viewer.handleDoubleClick())
        XCTAssertEqual(reportedZoomMode, .fit(.all))
    }

    @MainActor
    func testCommandWheelZoomReportsCustomZoomMode() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var reportedZoomMode: ZoomMode?

        viewer.onZoomModeChange = { zoomMode in
            reportedZoomMode = zoomMode
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        XCTAssertTrue(viewer.handleCommandWheelZoom(verticalDelta: 12, horizontalDelta: 0))

        guard case let .custom(scale) = reportedZoomMode else {
            XCTFail("Expected command-wheel zoom to report a custom zoom mode.")
            return
        }
        XCTAssertGreaterThan(scale, 1.0)
    }

    @MainActor
    func testCommandWheelZoomOutFromFitCanOpenImageBrowserInsteadOfZooming() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var didRequestBrowser = false
        var reportedZoomMode: ZoomMode?

        viewer.onFitZoomOutRequest = {
            didRequestBrowser = true
            return true
        }
        viewer.onZoomModeChange = { zoomMode in
            reportedZoomMode = zoomMode
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        XCTAssertTrue(viewer.handleCommandWheelZoom(verticalDelta: -12, horizontalDelta: 0))
        XCTAssertTrue(didRequestBrowser)
        XCTAssertNil(reportedZoomMode)
    }

    @MainActor
    func testCommandWheelZoomOutStartedAboveFitSnapsBackWithoutOpeningBrowser() async {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var didRequestBrowser = false
        var reportedZoomModes: [ZoomMode] = []

        viewer.onFitZoomOutRequest = {
            didRequestBrowser = true
            return true
        }
        viewer.onZoomModeChange = { zoomMode in
            reportedZoomModes.append(zoomMode)
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .custom(3.0),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        XCTAssertTrue(viewer.handleCommandWheelZoom(verticalDelta: -52, horizontalDelta: 0, phase: .began))
        XCTAssertTrue(viewer.handleCommandWheelZoom(verticalDelta: 0, horizontalDelta: 0, phase: .ended))
        try? await Task.sleep(for: .milliseconds(360))

        XCTAssertFalse(didRequestBrowser)
        XCTAssertEqual(reportedZoomModes.last, .fit(.all))
    }

    @MainActor
    func testCommandWheelZoomGestureStartedByZoomInDoesNotOpenBrowserWhenReversedAtFit() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var didRequestBrowser = false

        viewer.onFitZoomOutRequest = {
            didRequestBrowser = true
            return true
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .fit(.all),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        XCTAssertTrue(viewer.handleCommandWheelZoom(verticalDelta: 12, horizontalDelta: 0, phase: .began))
        XCTAssertTrue(viewer.handleCommandWheelZoom(verticalDelta: -32, horizontalDelta: 0, phase: .changed))
        XCTAssertTrue(viewer.handleCommandWheelZoom(verticalDelta: 0, horizontalDelta: 0, phase: .ended))

        XCTAssertFalse(didRequestBrowser)
    }

    @MainActor
    func testPinchZoomOutBelowFitSnapsBackToFitWhenGestureEnds() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var reportedZoomMode: ZoomMode?

        viewer.onZoomModeChange = { zoomMode in
            reportedZoomMode = zoomMode
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .custom(0.5),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        XCTAssertTrue(viewer.snapBackToFitIfNeeded(animated: false))
        XCTAssertEqual(reportedZoomMode, .fit(.all))
    }

    @MainActor
    func testPinchZoomAboveFitDoesNotSnapBackWhenGestureEnds() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var reportedZoomMode: ZoomMode?

        viewer.onZoomModeChange = { zoomMode in
            reportedZoomMode = zoomMode
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .custom(3.0),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        XCTAssertFalse(viewer.snapBackToFitIfNeeded(animated: false))
        XCTAssertNil(reportedZoomMode)
    }

    @MainActor
    func testScrollUpNavigatesToPreviousImageWhenFit() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var requestedDirection: ImageViewerNSView.NavigationDirection?

        viewer.onNavigateRequest = { direction in
            requestedDirection = direction
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        let didConsumeScroll = viewer.handleScrollGesture(verticalDelta: 12, horizontalDelta: 0)

        XCTAssertTrue(didConsumeScroll)
        XCTAssertEqual(requestedDirection, .previous)
    }

    @MainActor
    func testMouseScrollDownNavigatesToNextImageWhenEntireImageIsVisible() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var requestedDirection: ImageViewerNSView.NavigationDirection?

        viewer.onNavigateRequest = { direction in
            requestedDirection = direction
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        let didConsumeScroll = viewer.handleScrollGesture(verticalDelta: -12, horizontalDelta: 0)

        XCTAssertTrue(didConsumeScroll)
        XCTAssertEqual(requestedDirection, .next)
    }

    @MainActor
    func testMouseScrollNavigatesWhenAnyFitAllImageIsEntirelyVisible() {
        let cases: [(name: String, size: NSSize, viewport: NSSize)] = [
            ("portrait", NSSize(width: 1086, height: 1448), NSSize(width: 900, height: 620)),
            ("landscape", NSSize(width: 2400, height: 1350), NSSize(width: 900, height: 620)),
            ("square", NSSize(width: 3000, height: 3000), NSSize(width: 900, height: 620)),
            ("panorama", NSSize(width: 6000, height: 1200), NSSize(width: 900, height: 620)),
            ("veryTall", NSSize(width: 800, height: 6000), NSSize(width: 900, height: 620))
        ]

        for testCase in cases {
            assertMouseScrollNavigatesWhenFitAll(
                imageSize: testCase.size,
                viewportSize: testCase.viewport,
                file: #filePath,
                line: #line
            )
        }
    }

    @MainActor
    private func assertMouseScrollNavigatesWhenFitAll(
        imageSize: NSSize,
        viewportSize: NSSize,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(origin: .zero, size: viewportSize)
        let image = NSImage(size: imageSize)
        var requestedDirection: ImageViewerNSView.NavigationDirection?

        viewer.onNavigateRequest = { direction in
            requestedDirection = direction
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.png"),
            zoomMode: .fit(.all),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        let didConsumeScroll = viewer.handleScrollGesture(verticalDelta: -12, horizontalDelta: 0)

        XCTAssertTrue(viewer.isEntireImageVisible, file: file, line: line)
        XCTAssertFalse(viewer.isImageScrollableHorizontally, file: file, line: line)
        XCTAssertFalse(viewer.isImageScrollableVertically, file: file, line: line)
        XCTAssertTrue(didConsumeScroll, file: file, line: line)
        XCTAssertEqual(requestedDirection, .next, file: file, line: line)
    }

    @MainActor
    func testFitVisibilityAllowsSubPointOverflowFromRoundingForAnyAspectRatio() {
        let cases: [(imageSize: NSSize, viewportSize: NSSize, magnification: CGFloat)] = [
            (NSSize(width: 1086, height: 1448), NSSize(width: 900, height: 620), 620.6 / 1448),
            (NSSize(width: 2400, height: 1350), NSSize(width: 900, height: 620), 900.5 / 2400),
            (NSSize(width: 3000, height: 3000), NSSize(width: 900, height: 620), 620.4 / 3000)
        ]

        for testCase in cases {
            let scrollability = ImageViewerNSView.imageScrollability(
                imageSize: testCase.imageSize,
                viewportSize: testCase.viewportSize,
                magnification: testCase.magnification
            )

            XCTAssertFalse(scrollability.horizontal)
            XCTAssertFalse(scrollability.vertical)
        }
    }

    @MainActor
    func testDocumentPanToleranceUsesScreenPointToleranceAtCurrentMagnification() {
        XCTAssertFalse(
            ImageViewerNSView.canPanVisibleRect(
                documentSize: NSSize(width: 2001.5, height: 1000),
                viewportSize: NSSize(width: 1000, height: 500),
                magnification: 0.5
            )
        )
        XCTAssertTrue(
            ImageViewerNSView.canPanVisibleRect(
                documentSize: NSSize(width: 2003, height: 1000),
                viewportSize: NSSize(width: 1000, height: 500),
                magnification: 0.5
            )
        )
    }

    @MainActor
    func testMouseScrollDoesNotNavigateWhenImageExceedsViewport() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 300, height: 300))
        var requestedDirection: ImageViewerNSView.NavigationDirection?

        viewer.onNavigateRequest = { direction in
            requestedDirection = direction
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .custom(1.8),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        let didConsumeScroll = viewer.handleScrollGesture(verticalDelta: -12, horizontalDelta: 0)

        XCTAssertFalse(didConsumeScroll)
        XCTAssertNil(requestedDirection)
    }

    @MainActor
    func testTrackpadHorizontalSwipeNavigatesOnlyOncePerGesture() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var requestedDirections: [ImageViewerNSView.NavigationDirection] = []

        viewer.onNavigateRequest = { direction in
            requestedDirections.append(direction)
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: -14, isTrackpad: true, phase: .began))
        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: -14, isTrackpad: true, phase: .changed))
        _ = viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: 0, isTrackpad: true, phase: .ended)
        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: -14, isTrackpad: true, phase: .began))
        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: -14, isTrackpad: true, phase: .changed))

        XCTAssertEqual(requestedDirections, [.next, .next])
    }

    @MainActor
    func testTrackpadHorizontalSwipeNavigatesEvenWhenImageExceedsViewport() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 300, height: 300))
        var requestedDirection: ImageViewerNSView.NavigationDirection?

        viewer.onNavigateRequest = { direction in
            requestedDirection = direction
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .custom(1.8),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        let didConsumeScroll = viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: -28, isTrackpad: true, phase: .began)

        XCTAssertTrue(didConsumeScroll)
        XCTAssertEqual(requestedDirection, .next)
    }

    @MainActor
    func testCommandModifiedScrollZoomsInsteadOfNavigating() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var reportedZoomMode: ZoomMode?
        var requestedDirection: ImageViewerNSView.NavigationDirection?

        viewer.onZoomModeChange = { zoomMode in
            reportedZoomMode = zoomMode
        }
        viewer.onNavigateRequest = { direction in
            requestedDirection = direction
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        let didConsumeScroll = viewer.handleScrollGesture(
            verticalDelta: -12,
            horizontalDelta: 0,
            modifierFlags: [.command]
        )

        XCTAssertTrue(didConsumeScroll)
        XCTAssertNotNil(reportedZoomMode)
        XCTAssertNil(requestedDirection)
    }

    @MainActor
    func testTrackpadVerticalScrollIsConsumedWhenImageDoesNotOverflowVertically() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var requestedDirection: ImageViewerNSView.NavigationDirection?

        viewer.onNavigateRequest = { direction in
            requestedDirection = direction
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        let didConsumeScroll = viewer.handleScrollGesture(verticalDelta: -14, horizontalDelta: 0, isTrackpad: true, phase: .began)

        XCTAssertTrue(didConsumeScroll)
        XCTAssertNil(requestedDirection)
    }

    @MainActor
    func testCenteredFramePlacesSmallImageInViewportCenter() {
        let frame = ImageViewerNSView.centeredImageFrame(
            imageSize: NSSize(width: 200, height: 100),
            containerSize: NSSize(width: 400, height: 400)
        )

        XCTAssertEqual(frame.origin.x, 100, accuracy: 0.001)
        XCTAssertEqual(frame.origin.y, 150, accuracy: 0.001)
        XCTAssertEqual(frame.size.width, 200, accuracy: 0.001)
        XCTAssertEqual(frame.size.height, 100, accuracy: 0.001)
    }

    @MainActor
    func testDocumentContainerExpandsToViewportForCentering() {
        let size = ImageViewerNSView.documentContainerSize(
            imageSize: NSSize(width: 200, height: 100),
            viewportSize: NSSize(width: 400, height: 400),
            magnification: 1.0
        )

        XCTAssertEqual(size.width, 400, accuracy: 0.001)
        XCTAssertEqual(size.height, 400, accuracy: 0.001)
    }

    @MainActor
    func testSpreadContentSizePlacesImagesSideBySideWithoutGap() {
        let size = ImageViewerNSView.displayedContentSize(
            imageSizes: [
                NSSize(width: 200, height: 300),
                NSSize(width: 150, height: 250)
            ],
            pageLayout: .spread
        )
        let frames = ImageViewerNSView.imageFrames(
            imageSizes: [
                NSSize(width: 200, height: 300),
                NSSize(width: 150, height: 250)
            ],
            containerSize: NSSize(width: 500, height: 400),
            pageLayout: .spread
        )

        XCTAssertEqual(size.width, 350, accuracy: 0.001)
        XCTAssertEqual(size.height, 300, accuracy: 0.001)
        XCTAssertEqual(frames[0].maxX, frames[1].minX, accuracy: 0.001)
    }

    @MainActor
    func testVerticalStripStacksImagesWithoutGap() {
        let size = ImageViewerNSView.displayedContentSize(
            imageSizes: [
                NSSize(width: 200, height: 300),
                NSSize(width: 150, height: 250)
            ],
            pageLayout: .verticalStrip
        )
        let frames = ImageViewerNSView.imageFrames(
            imageSizes: [
                NSSize(width: 200, height: 300),
                NSSize(width: 150, height: 250)
            ],
            containerSize: NSSize(width: 400, height: 700),
            pageLayout: .verticalStrip
        )

        XCTAssertEqual(size.width, 200, accuracy: 0.001)
        XCTAssertEqual(size.height, 550, accuracy: 0.001)
        XCTAssertEqual(frames[1].maxY, frames[0].minY, accuracy: 0.001)
    }

    @MainActor
    func testFitMagnificationUsesViewportHeight() {
        let magnification = ImageViewerNSView.fitMagnification(
            imageSize: NSSize(width: 1200, height: 1000),
            viewportSize: NSSize(width: 400, height: 500),
            fitMode: .height,
            minimumMagnification: 0.05,
            maximumMagnification: 8.0
        )

        XCTAssertEqual(magnification, 0.5, accuracy: 0.001)
    }

    @MainActor
    func testFitMagnificationUsesViewportWidth() {
        let magnification = ImageViewerNSView.fitMagnification(
            imageSize: NSSize(width: 1200, height: 1000),
            viewportSize: NSSize(width: 600, height: 300),
            fitMode: .width,
            minimumMagnification: 0.05,
            maximumMagnification: 8.0
        )

        XCTAssertEqual(magnification, 0.5, accuracy: 0.001)
    }

    @MainActor
    func testFitAllMagnificationUsesSmallerAxis() {
        let magnification = ImageViewerNSView.fitMagnification(
            imageSize: NSSize(width: 2000, height: 1000),
            viewportSize: NSSize(width: 400, height: 500),
            fitMode: .all,
            minimumMagnification: 0.05,
            maximumMagnification: 8.0
        )

        XCTAssertEqual(magnification, 0.2, accuracy: 0.001)
    }

    @MainActor
    func testHeightFitCanExposeHorizontalScrollingForWideImages() {
        let viewportSize = NSSize(width: 400, height: 500)
        let imageSize = NSSize(width: 2000, height: 1000)
        let magnification = ImageViewerNSView.fitMagnification(
            imageSize: imageSize,
            viewportSize: viewportSize,
            fitMode: .height,
            minimumMagnification: 0.05,
            maximumMagnification: 8.0
        )
        let scrollability = ImageViewerNSView.imageScrollability(
            imageSize: imageSize,
            viewportSize: viewportSize,
            magnification: magnification
        )

        XCTAssertTrue(scrollability.horizontal)
        XCTAssertFalse(scrollability.vertical)
    }

    @MainActor
    func testPortraitFitDoesNotExposeScrollableAxes() {
        let viewportSize = NSSize(width: 900, height: 620)
        let imageSize = NSSize(width: 1200, height: 1600)
        let magnification = ImageViewerNSView.fitMagnification(
            imageSize: imageSize,
            viewportSize: viewportSize,
            fitMode: .height,
            minimumMagnification: 0.05,
            maximumMagnification: 8.0
        )
        let scrollability = ImageViewerNSView.imageScrollability(
            imageSize: imageSize,
            viewportSize: viewportSize,
            magnification: magnification
        )

        XCTAssertFalse(scrollability.horizontal)
        XCTAssertFalse(scrollability.vertical)
    }

    @MainActor
    func testTrackpadVerticalScrollIsConsumedWhenFitImageDoesNotOverflowVertically() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 900, height: 620)
        let image = NSImage(size: NSSize(width: 1200, height: 1600))
        var requestedDirection: ImageViewerNSView.NavigationDirection?

        viewer.onNavigateRequest = { direction in
            requestedDirection = direction
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/portrait.png"),
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        let didConsumeScroll = viewer.handleScrollGesture(verticalDelta: -14, horizontalDelta: 0, isTrackpad: true, phase: .began)

        XCTAssertTrue(didConsumeScroll)
        XCTAssertNil(requestedDirection)
    }

    @MainActor
    func testCommandWheelMagnificationClampsToBounds() {
        let zoomedIn = ImageViewerNSView.commandWheelMagnification(
            currentMagnification: 7.9,
            delta: 50,
            minimumMagnification: 0.05,
            maximumMagnification: 8.0
        )
        let zoomedOut = ImageViewerNSView.commandWheelMagnification(
            currentMagnification: 0.06,
            delta: -50,
            minimumMagnification: 0.05,
            maximumMagnification: 8.0
        )

        XCTAssertEqual(zoomedIn, 8.0, accuracy: 0.001)
        XCTAssertEqual(zoomedOut, 0.05, accuracy: 0.001)
    }

    @MainActor
    func testPinchMagnificationClampsToBounds() {
        let zoomedIn = ImageViewerNSView.pinchMagnification(
            currentMagnification: 7.9,
            delta: 1.0,
            minimumMagnification: 0.05,
            maximumMagnification: 8.0
        )
        let zoomedOut = ImageViewerNSView.pinchMagnification(
            currentMagnification: 0.06,
            delta: -1.0,
            minimumMagnification: 0.05,
            maximumMagnification: 8.0
        )

        XCTAssertEqual(zoomedIn, 8.0, accuracy: 0.001)
        XCTAssertEqual(zoomedOut, 0.05, accuracy: 0.001)
    }

    @MainActor
    func testEndedMagnifyPhaseIsRecognizedForSnapBack() {
        XCTAssertTrue(ImageViewerNSView.isEndingMagnifyGesture(phase: .ended))
        XCTAssertTrue(ImageViewerNSView.isEndingMagnifyGesture(phase: .cancelled))
        XCTAssertFalse(ImageViewerNSView.isEndingMagnifyGesture(phase: .changed))
    }

    @MainActor
    func testCanPanVisibleRectOnlyWhenContentExceedsViewport() {
        XCTAssertFalse(
            ImageViewerNSView.canPanVisibleRect(
                documentSize: NSSize(width: 400, height: 300),
                viewportSize: NSSize(width: 400, height: 300),
                magnification: 1.0
            )
        )
        XCTAssertTrue(
            ImageViewerNSView.canPanVisibleRect(
                documentSize: NSSize(width: 800, height: 300),
                viewportSize: NSSize(width: 400, height: 300),
                magnification: 1.0
            )
        )
    }

    @MainActor
    func testPannedVisibleRectOriginMovesOppositeDragAndClamps() {
        let origin = ImageViewerNSView.pannedVisibleRectOrigin(
            currentOrigin: NSPoint(x: 100, y: 100),
            documentSize: NSSize(width: 1000, height: 800),
            viewportSize: NSSize(width: 400, height: 300),
            magnification: 1.0,
            dragDelta: NSPoint(x: 50, y: -60)
        )
        let clampedOrigin = ImageViewerNSView.pannedVisibleRectOrigin(
            currentOrigin: NSPoint(x: 10, y: 10),
            documentSize: NSSize(width: 1000, height: 800),
            viewportSize: NSSize(width: 400, height: 300),
            magnification: 1.0,
            dragDelta: NSPoint(x: 50, y: 50)
        )

        XCTAssertEqual(origin.x, 50, accuracy: 0.001)
        XCTAssertEqual(origin.y, 160, accuracy: 0.001)
        XCTAssertEqual(clampedOrigin.x, 0, accuracy: 0.001)
        XCTAssertEqual(clampedOrigin.y, 0, accuracy: 0.001)
    }

    @MainActor
    func testClickDragToleranceIgnoresSmallDoubleClickJitter() {
        XCTAssertFalse(
            ImageViewerNSView.isBeyondClickDragTolerance(
                from: NSPoint(x: 100, y: 100),
                to: NSPoint(x: 102, y: 101)
            )
        )
        XCTAssertTrue(
            ImageViewerNSView.isBeyondClickDragTolerance(
                from: NSPoint(x: 100, y: 100),
                to: NSPoint(x: 104, y: 100)
            )
        )
    }

    @MainActor
    func testPointerDragLocksPointerOnlyAfterDragTolerance() throws {
        let coordinator = ImageViewerPointerDragCoordinator()
        var lockBeginCount = 0
        var lockEndCount = 0
        var panCount = 0

        XCTAssertTrue(
            coordinator.handle(
                .began,
                event: try Self.mouseEvent(location: NSPoint(x: 100, y: 100)),
                canPan: true,
                onPan: { _, _ in panCount += 1 },
                onPointerLockBegin: { _ in lockBeginCount += 1 },
                onPointerLockEnd: { lockEndCount += 1 }
            )
        )
        XCTAssertFalse(
            coordinator.handle(
                .changed,
                event: try Self.mouseEvent(location: NSPoint(x: 102, y: 101)),
                canPan: true,
                onPan: { _, _ in panCount += 1 },
                onPointerLockBegin: { _ in lockBeginCount += 1 },
                onPointerLockEnd: { lockEndCount += 1 }
            )
        )
        XCTAssertFalse(
            coordinator.handle(
                .ended,
                event: try Self.mouseEvent(location: NSPoint(x: 102, y: 101)),
                canPan: true,
                onPan: { _, _ in panCount += 1 },
                onPointerLockBegin: { _ in lockBeginCount += 1 },
                onPointerLockEnd: { lockEndCount += 1 }
            )
        )

        XCTAssertEqual(lockBeginCount, 0)
        XCTAssertEqual(lockEndCount, 0)
        XCTAssertEqual(panCount, 0)
    }

    @MainActor
    func testPointerDragUnlocksPointerWhenPanDragEnds() throws {
        let coordinator = ImageViewerPointerDragCoordinator()
        var lockBeginCount = 0
        var lockEndCount = 0
        var panLocations: [(previous: NSPoint, current: NSPoint)] = []

        _ = coordinator.handle(
            .began,
            event: try Self.mouseEvent(location: NSPoint(x: 100, y: 100)),
            canPan: true,
            onPan: { previous, current in panLocations.append((previous, current)) },
            onPointerLockBegin: { _ in lockBeginCount += 1 },
            onPointerLockEnd: { lockEndCount += 1 }
        )
        XCTAssertTrue(
            coordinator.handle(
                .changed,
                event: try Self.mouseEvent(location: NSPoint(x: 105, y: 100)),
                canPan: true,
                onPan: { previous, current in panLocations.append((previous, current)) },
                onPointerLockBegin: { _ in lockBeginCount += 1 },
                onPointerLockEnd: { lockEndCount += 1 }
            )
        )
        XCTAssertTrue(
            coordinator.handle(
                .changed,
                event: try Self.mouseEvent(location: NSPoint(x: 110, y: 95)),
                canPan: true,
                onPan: { previous, current in panLocations.append((previous, current)) },
                onPointerLockBegin: { _ in lockBeginCount += 1 },
                onPointerLockEnd: { lockEndCount += 1 }
            )
        )
        XCTAssertTrue(
            coordinator.handle(
                .ended,
                event: try Self.mouseEvent(location: NSPoint(x: 110, y: 95)),
                canPan: true,
                onPan: { previous, current in panLocations.append((previous, current)) },
                onPointerLockBegin: { _ in lockBeginCount += 1 },
                onPointerLockEnd: { lockEndCount += 1 }
            )
        )

        XCTAssertEqual(lockBeginCount, 1)
        XCTAssertEqual(lockEndCount, 1)
        XCTAssertEqual(panLocations.count, 2)
        XCTAssertEqual(panLocations[0].previous, NSPoint(x: 100, y: 100))
        XCTAssertEqual(panLocations[0].current, NSPoint(x: 105, y: 100))
        XCTAssertEqual(panLocations[1].previous, NSPoint(x: 105, y: 100))
        XCTAssertEqual(panLocations[1].current, NSPoint(x: 110, y: 95))
    }

    @MainActor
    func testDoubleClickCenterPointMapsImagePointIntoDocumentFrame() {
        let point = ImageViewerNSView.documentPoint(
            forImagePoint: NSPoint(x: 80, y: 120),
            imageFrame: NSRect(x: 30, y: 45, width: 400, height: 300)
        )

        XCTAssertEqual(point.x, 110, accuracy: 0.001)
        XCTAssertEqual(point.y, 165, accuracy: 0.001)
    }

    @MainActor
    func testDoubleClickCenterPointClampsToImageBounds() {
        let point = ImageViewerNSView.clampedPoint(
            NSPoint(x: -20, y: 340),
            to: NSRect(x: 0, y: 0, width: 400, height: 300)
        )

        XCTAssertEqual(point.x, 0, accuracy: 0.001)
        XCTAssertEqual(point.y, 300, accuracy: 0.001)
    }

    @MainActor
    func testArrowKeyCodesMapToNavigationDirections() {
        XCTAssertEqual(ImageViewerNSView.navigationDirection(forKeyCode: 123), .previous)
        XCTAssertEqual(ImageViewerNSView.navigationDirection(forKeyCode: 124), .next)
        XCTAssertNil(ImageViewerNSView.navigationDirection(forKeyCode: 36))
    }

    @MainActor
    func testLandscapeFitKeepsImageCenteredInViewportWidth() {
        let viewportSize = NSSize(width: 900, height: 620)
        let imageSize = NSSize(width: 1600, height: 1200)
        let magnification = ImageViewerNSView.fitMagnification(
            imageSize: imageSize,
            viewportSize: viewportSize,
            fitMode: .height,
            minimumMagnification: 0.05,
            maximumMagnification: 8.0
        )
        let containerSize = ImageViewerNSView.documentContainerSize(
            imageSize: imageSize,
            viewportSize: viewportSize,
            magnification: magnification
        )
        let frame = ImageViewerNSView.centeredImageFrame(
            imageSize: imageSize,
            containerSize: containerSize
        )

        XCTAssertEqual(frame.origin.x, 70.9677, accuracy: 0.001)
        XCTAssertEqual(frame.origin.y, 0, accuracy: 0.001)
    }

    @MainActor
    func testCenteredVisibleRectOriginResetsOffsetToViewportCenter() {
        let origin = ImageViewerNSView.centeredVisibleRectOrigin(
            containerSize: NSSize(width: 2000, height: 1200),
            viewportSize: NSSize(width: 900, height: 620),
            magnification: 1.0
        )

        XCTAssertEqual(origin.x, 550, accuracy: 0.001)
        XCTAssertEqual(origin.y, 290, accuracy: 0.001)
    }

    @MainActor
    func testVisibleRectOriginCentersOnDoubleClickDocumentPoint() {
        let origin = ImageViewerNSView.visibleRectOrigin(
            centeredOn: NSPoint(x: 800, y: 600),
            containerSize: NSSize(width: 1600, height: 1200),
            viewportSize: NSSize(width: 400, height: 300),
            magnification: 1.0
        )

        XCTAssertEqual(origin.x, 600, accuracy: 0.001)
        XCTAssertEqual(origin.y, 450, accuracy: 0.001)
    }

    @MainActor
    func testVisibleRectOriginClampsWhenDoubleClickPointIsNearImageEdge() {
        let origin = ImageViewerNSView.visibleRectOrigin(
            centeredOn: NSPoint(x: 50, y: 40),
            containerSize: NSSize(width: 1600, height: 1200),
            viewportSize: NSSize(width: 400, height: 300),
            magnification: 1.0
        )

        XCTAssertEqual(origin.x, 0, accuracy: 0.001)
        XCTAssertEqual(origin.y, 0, accuracy: 0.001)
    }

    @MainActor
    func testVisibleRectOriginAnchorsCommandWheelZoomAtPointerPosition() {
        let unitPoint = ImageViewerNSView.anchorUnitPoint(
            anchorDocumentPoint: NSPoint(x: 300, y: 200),
            visibleRect: NSRect(x: 200, y: 100, width: 400, height: 300)
        )
        let origin = ImageViewerNSView.visibleRectOrigin(
            anchoring: NSPoint(x: 500, y: 300),
            at: unitPoint,
            containerSize: NSSize(width: 1600, height: 1200),
            viewportSize: NSSize(width: 400, height: 300),
            magnification: 2.0
        )

        XCTAssertEqual(unitPoint.x, 0.25, accuracy: 0.001)
        XCTAssertEqual(unitPoint.y, 1.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(origin.x, 450, accuracy: 0.001)
        XCTAssertEqual(origin.y, 250, accuracy: 0.001)
    }

    @MainActor
    func testAnchoredContentOffsetSurvivesContentFrameChanges() {
        let offset = ImageViewerNSView.anchoredContentOffset(
            documentPoint: NSPoint(x: 300, y: 220),
            contentFrame: NSRect(x: 100, y: 120, width: 500, height: 600)
        )
        let remappedPoint = ImageViewerNSView.documentPoint(
            contentOffset: offset,
            contentFrame: NSRect(x: 80, y: 90, width: 700, height: 800)
        )

        XCTAssertEqual(offset.x, 200, accuracy: 0.001)
        XCTAssertEqual(offset.y, 100, accuracy: 0.001)
        XCTAssertEqual(remappedPoint.x, 280, accuracy: 0.001)
        XCTAssertEqual(remappedPoint.y, 190, accuracy: 0.001)
    }
}
