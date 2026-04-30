import XCTest
import AppKit
@testable import Viewooa

final class ImageViewerNSViewGeometryTests: XCTestCase {
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
