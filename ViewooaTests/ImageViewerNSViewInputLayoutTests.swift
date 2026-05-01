import XCTest
import AppKit
@testable import Viewooa

final class ImageViewerNSViewInputLayoutTests: XCTestCase {
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
    func testTinyPinchNoiseDoesNotCountAsSignificantFitZoomOut() {
        XCTAssertFalse(ImageViewerTrackpadScrollCoordinator.isSignificantMagnifyDelta(-0.001))
        XCTAssertTrue(ImageViewerTrackpadScrollCoordinator.isSignificantMagnifyDelta(-0.02))
        XCTAssertFalse(
            ImageViewerTrackpadScrollCoordinator.shouldRouteFitZoomOutToBrowser(
                magnificationDelta: -0.001,
                startedAtFit: true,
                firstSignificantDelta: nil,
                isCurrentlyFit: true
            )
        )
    }

    @MainActor
    func testPinchZoomOutRoutesToBrowserOnlyWhenGestureStartsAtFit() {
        XCTAssertTrue(
            ImageViewerTrackpadScrollCoordinator.shouldRouteFitZoomOutToBrowser(
                magnificationDelta: -0.02,
                startedAtFit: true,
                firstSignificantDelta: -0.02,
                isCurrentlyFit: true
            )
        )
        XCTAssertFalse(
            ImageViewerTrackpadScrollCoordinator.shouldRouteFitZoomOutToBrowser(
                magnificationDelta: -0.02,
                startedAtFit: false,
                firstSignificantDelta: -0.02,
                isCurrentlyFit: true
            )
        )
        XCTAssertFalse(
            ImageViewerTrackpadScrollCoordinator.shouldRouteFitZoomOutToBrowser(
                magnificationDelta: -0.02,
                startedAtFit: true,
                firstSignificantDelta: 0.02,
                isCurrentlyFit: true
            )
        )
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
}
