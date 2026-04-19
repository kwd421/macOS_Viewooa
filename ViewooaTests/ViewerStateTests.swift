import XCTest
@testable import Viewooa

final class ViewerStateTests: XCTestCase {
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
