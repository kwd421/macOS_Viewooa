import XCTest
import PDFKit
import ImageIO
@testable import Viewooa

final class ViewerStateTests: XCTestCase {
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
    func testImageViewerReloadsResolvedImageWhenRevisionChanges() {
        let viewer = ImageViewerNSView()
        let url = URL(fileURLWithPath: "/tmp/animated.gif")
        let firstFrame = NSImage(size: NSSize(width: 80, height: 30))
        let secondFrame = NSImage(size: NSSize(width: 90, height: 40))

        viewer.apply(
            resolvedImage: firstFrame,
            imageURL: url,
            imageRevision: 1,
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )
        viewer.apply(
            resolvedImage: secondFrame,
            imageURL: url,
            imageRevision: 2,
            zoomMode: .fit(.height),
            rotationQuarterTurns: 0
        )

        XCTAssertTrue(viewer.displayedImage === secondFrame)
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

        XCTAssertEqual(state.zoomMode, .custom(1.1))
    }

    @MainActor
    func testZoomInFromFitUsesDisplayedMagnificationAsBase() {
        let state = ViewerState()
        state.updateViewportMetrics(displayedMagnification: 0.4, fitMagnification: 0.4, isEntireImageVisible: true)

        state.zoomIn()

        XCTAssertEqual(state.zoomMode, .custom(0.44000000000000006))
    }

    @MainActor
    func testZoomOutFromFitUsesDefaultIncrement() {
        let state = ViewerState()

        state.zoomOut()

        XCTAssertEqual(state.zoomMode, .custom(0.9090909090909091))
    }

    @MainActor
    func testZoomOutFromFitUsesDisplayedMagnificationAsBase() {
        let state = ViewerState()
        state.updateViewportMetrics(displayedMagnification: 0.4, fitMagnification: 0.4, isEntireImageVisible: true)

        state.zoomOut()

        XCTAssertEqual(state.zoomMode, .custom(0.36363636363636365))
    }

    @MainActor
    func testBridgeZoomOutFromFitWithFolderImagesUsesViewerZoom() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]
        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        let bridge = ViewooaBridge(viewerState: state)

        bridge.zoomOut()

        XCTAssertFalse(bridge.areBrowserOverlaysVisible)
        XCTAssertEqual(state.zoomMode, .custom(0.9090909090909091))
    }

    @MainActor
    func testBrowserThumbnailSizeClampsToFinderLikeRange() {
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

        XCTAssertEqual(state.zoomMode, .custom(0.9090909090909091))
    }

    @MainActor
    func testZoomOutClampsToHalfOfFitForLargeImages() {
        let state = ViewerState()
        state.updateViewportMetrics(displayedMagnification: 0.21, fitMagnification: 0.4, isEntireImageVisible: true)

        state.zoomOut()

        XCTAssertEqual(state.zoomMode, .custom(0.2))
    }

    @MainActor
    func testZoomOutClampsToActualSizeWhenActualIsSmallerThanFit() {
        let state = ViewerState()
        state.updateViewportMetrics(displayedMagnification: 1.05, fitMagnification: 2.0, isEntireImageVisible: true)

        state.zoomOut()

        XCTAssertEqual(state.zoomMode, .custom(1.0))
    }

    @MainActor
    func testZoomActionShowsPercentageOverlay() {
        let state = ViewerState()

        state.zoomIn()

        XCTAssertTrue(state.isZoomPercentageVisible)
        XCTAssertEqual(state.zoomPercentageText, "110%")
    }

    @MainActor
    func testOpeningGIFEnablesFrameControlsAndFrameSteppingPausesPlayback() throws {
        let url = try Self.makeTemporaryGIF()
        let state = ViewerState()

        state.apply(index: FolderImageIndex(imageURLs: [url], currentIndex: 0))

        XCTAssertTrue(state.hasAnimatedImageFrames)
        XCTAssertEqual(state.animatedImageFrameText, "1 / 2")
        XCTAssertTrue(state.isAnimatedImagePlaying)
        XCTAssertEqual(state.imageRevision, 1)

        state.showNextAnimatedImageFrame()

        XCTAssertFalse(state.isAnimatedImagePlaying)
        XCTAssertEqual(state.animatedImageFrameText, "2 / 2")
        XCTAssertEqual(state.imageRevision, 2)
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

}

private extension ViewerStateTests {
    static func makeTemporaryGIF() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("gif")

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            "com.compuserve.gif" as CFString,
            2,
            nil
        ) else {
            throw NSError(domain: "ViewerStateTests", code: 1)
        }

        for color in [NSColor.red, NSColor.blue] {
            guard let image = makeCGImage(color: color) else {
                throw NSError(domain: "ViewerStateTests", code: 2)
            }
            let properties: [CFString: Any] = [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: 0.1
                ]
            ]
            CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "ViewerStateTests", code: 3)
        }

        return url
    }

    static func makeCGImage(color: NSColor) -> CGImage? {
        let width = 2
        let height = 2
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}
