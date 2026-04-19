import XCTest
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
            zoomMode: .fit,
            rotationQuarterTurns: 0
        )

        XCTAssertTrue(viewer.displayedImage === resolvedImage)
    }

    @MainActor
    func testAppUsesSingleWindowScene() {
        let sceneType = String(
            reflecting: type(of: ViewooaApp.makeViewerScene(viewerState: ViewerState()))
        )

        XCTAssertTrue(sceneType.contains("Window<"))
    }

    @MainActor
    func testViewerWindowShellAcceptsInjectedViewerState() {
        let state = ViewerState()

        _ = ViewerWindowShell(viewerState: state)
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
    func testNavigationResetsZoomModeToFit() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]

        let state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.zoomMode = .actualSize
        state.showNextImage()

        XCTAssertEqual(state.zoomMode, .fit)
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
}
