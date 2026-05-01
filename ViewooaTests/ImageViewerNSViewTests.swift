import XCTest
import AppKit
@testable import Viewooa

final class ImageViewerNSViewTests: XCTestCase {
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
    func testCommandWheelZoomOutFromFitZoomsWithoutOpeningBrowser() {
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

        XCTAssertTrue(viewer.handleCommandWheelZoom(verticalDelta: -12, horizontalDelta: 0))
        XCTAssertNotNil(reportedZoomMode)
    }

    @MainActor
    func testCommandWheelZoomOutStartedAboveFitSnapsBackToFit() async {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))
        var reportedZoomModes: [ZoomMode] = []

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

        XCTAssertEqual(reportedZoomModes.last, .fit(.all))
    }

    @MainActor
    func testCommandWheelZoomGestureCanReverseAtFitWithoutOverlayRouting() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 200, height: 200))

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

}
