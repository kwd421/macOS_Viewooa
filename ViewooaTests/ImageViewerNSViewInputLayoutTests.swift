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
    func testTrackpadHorizontalSwipeNavigatesOnGestureEnd() async {
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
        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: -50, isTrackpad: true, phase: .changed))
        XCTAssertEqual(requestedDirections, [])

        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: 0, isTrackpad: true, phase: .ended))
        try? await Task.sleep(for: .milliseconds(260))

        XCTAssertEqual(requestedDirections, [.next])
    }

    @MainActor
    func testTrackpadHorizontalSwipeNavigatesOnlyOncePerGesture() async {
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

        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: -90, isTrackpad: true, phase: .began))
        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: 0, isTrackpad: true, phase: .ended))
        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: -120, isTrackpad: true, momentumPhase: .changed))
        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: 0, isTrackpad: true, momentumPhase: .ended))
        try? await Task.sleep(for: .milliseconds(260))

        XCTAssertEqual(requestedDirections, [.next])
    }

    @MainActor
    func testTrackpadHorizontalSwipePreviewsEvenWhenImageExceedsViewport() async {
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

        let didConsumeScroll = viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: -80, isTrackpad: true, phase: .began)

        XCTAssertTrue(didConsumeScroll)
        XCTAssertLessThan(viewer.interactiveNavigationStripView.layer?.transform.m41 ?? 0, 0)
        XCTAssertEqual(viewer.documentContainerView.layer?.transform.m41 ?? 0, 0, accuracy: 0.001)
        XCTAssertNil(requestedDirection)

        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: 0, isTrackpad: true, phase: .ended))
        try? await Task.sleep(for: .milliseconds(260))

        XCTAssertEqual(requestedDirection, .next)
    }

    @MainActor
    func testTrackpadHorizontalSwipeShowsAdjacentPreviewImage() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        let image = NSImage(size: NSSize(width: 300, height: 300))
        viewer.nextPreviewImageView.image = image
        viewer.nextPreviewImageView.frame = NSRect(origin: .zero, size: image.size)

        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/sample.jpg"),
            zoomMode: .custom(1.8),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        viewer.applyInteractiveNavigationOffset(-120)

        XCTAssertFalse(viewer.nextPreviewImageView.isHidden)
        XCTAssertTrue(viewer.previousPreviewImageView.isHidden)
        XCTAssertGreaterThan(viewer.nextPreviewImageView.frame.minX, viewer.imageStack.primaryImageFrame.minX)
    }

    @MainActor
    func testTrackpadHorizontalSwipeKeepsGapForWideImagePreview() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        let image = NSImage(size: NSSize(width: 800, height: 300))
        viewer.nextPreviewImageView.image = image
        viewer.nextPreviewImageView.frame = NSRect(origin: .zero, size: image.size)

        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/wide.jpg"),
            zoomMode: .custom(1.0),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        viewer.applyInteractiveNavigationOffset(-80)

        let pageFrame = viewer.scrollView.frame
        let gap = viewer.nextPreviewImageView.frame.minX - pageFrame.maxX
        XCTAssertEqual(gap, 28, accuracy: 0.001)
    }

    @MainActor
    func testTrackpadHorizontalSwipeMovesCurrentAndPreviewBySameDistance() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        let image = NSImage(size: NSSize(width: 800, height: 300))
        viewer.nextPreviewImageView.image = image
        viewer.nextPreviewImageView.frame = NSRect(origin: .zero, size: image.size)

        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/wide.jpg"),
            zoomMode: .custom(1.0),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        viewer.applyInteractiveNavigationOffset(-80)
        let offsetAt80 = viewer.interactiveNavigationStripView.layer?.transform.m41 ?? 0
        let currentVisualMinXAt80 = viewer.imageStack.primaryImageFrame.minX + offsetAt80
        let previewVisualMinXAt80 = viewer.nextPreviewImageView.frame.minX + offsetAt80
        viewer.applyInteractiveNavigationOffset(-120)
        let offsetAt120 = viewer.interactiveNavigationStripView.layer?.transform.m41 ?? 0
        let currentVisualMinXAt120 = viewer.imageStack.primaryImageFrame.minX + offsetAt120
        let previewVisualMinXAt120 = viewer.nextPreviewImageView.frame.minX + offsetAt120

        XCTAssertEqual(currentVisualMinXAt120 - currentVisualMinXAt80, -40, accuracy: 0.001)
        XCTAssertEqual(previewVisualMinXAt120 - previewVisualMinXAt80, -40, accuracy: 0.001)
    }

    @MainActor
    func testTrackpadHorizontalSwipeFitsPreviewImageBeforeNavigationCompletes() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        let currentImage = NSImage(size: NSSize(width: 800, height: 300))
        let nextImage = NSImage(size: NSSize(width: 1000, height: 1000))
        viewer.nextPreviewImageView.image = nextImage
        viewer.nextPreviewImageView.frame = NSRect(origin: .zero, size: nextImage.size)

        viewer.apply(
            resolvedImage: currentImage,
            imageURL: URL(fileURLWithPath: "/tmp/wide.jpg"),
            zoomMode: .fit(.all),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        viewer.applyInteractiveNavigationOffset(-80)

        XCTAssertEqual(viewer.nextPreviewImageView.frame.width, 300, accuracy: 0.001)
        XCTAssertEqual(viewer.nextPreviewImageView.frame.height, 300, accuracy: 0.001)
    }

    @MainActor
    func testTrackpadHorizontalSwipeKeepsPreviewVisibleUntilFinishAnimationCompletes() async {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        let image = NSImage(size: NSSize(width: 800, height: 300))
        viewer.nextPreviewImageView.image = image
        viewer.nextPreviewImageView.frame = NSRect(origin: .zero, size: image.size)
        var requestedDirection: ImageViewerNSView.NavigationDirection?

        viewer.onNavigateRequest = { direction in
            requestedDirection = direction
        }
        viewer.apply(
            resolvedImage: image,
            imageURL: URL(fileURLWithPath: "/tmp/wide.jpg"),
            zoomMode: .custom(1.0),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        viewer.applyInteractiveNavigationOffset(-80)
        viewer.finishInteractiveNavigation(.next)
        try? await Task.sleep(for: .milliseconds(80))

        XCTAssertFalse(viewer.nextPreviewImageView.isHidden)
        XCTAssertNil(requestedDirection)

        try? await Task.sleep(for: .milliseconds(220))

        XCTAssertTrue(viewer.nextPreviewImageView.isHidden)
        XCTAssertEqual(requestedDirection, .next)
    }

    @MainActor
    func testCommittedTrackpadSwipeKeepsPreviewUntilDestinationImageIsApplied() async {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        let currentImage = NSImage(size: NSSize(width: 800, height: 300))
        let nextImage = NSImage(size: NSSize(width: 800, height: 300))
        let currentURL = URL(fileURLWithPath: "/tmp/current.jpg")
        let nextURL = URL(fileURLWithPath: "/tmp/next.jpg")
        var requestedDirection: ImageViewerNSView.NavigationDirection?

        viewer.onNavigateRequest = { direction in
            requestedDirection = direction
        }
        viewer.apply(
            resolvedImage: currentImage,
            imageURL: currentURL,
            previousPreviewURL: nil,
            nextPreviewURL: nil,
            zoomMode: .fit(.all),
            rotationQuarterTurns: 0
        )
        viewer.nextPreviewURL = nextURL
        viewer.nextPreviewImageView.image = nextImage
        viewer.nextPreviewImageView.frame = NSRect(origin: .zero, size: nextImage.size)
        viewer.layoutSubtreeIfNeeded()

        viewer.applyInteractiveNavigationOffset(-80)
        viewer.finishInteractiveNavigation(.next)
        try? await Task.sleep(for: .milliseconds(300))

        XCTAssertEqual(requestedDirection, .next)
        XCTAssertFalse(viewer.nextPreviewImageView.isHidden)
        XCTAssertEqual(viewer.pendingInteractiveNavigationDestinationURL, nextURL)

        viewer.apply(
            resolvedImage: nextImage,
            imageURL: nextURL,
            previousPreviewURL: currentURL,
            nextPreviewURL: nil,
            zoomMode: .fit(.all),
            rotationQuarterTurns: 0
        )

        XCTAssertTrue(viewer.nextPreviewImageView.isHidden)
        XCTAssertNil(viewer.pendingInteractiveNavigationDestinationURL)
        XCTAssertEqual(viewer.interactiveNavigationStripView.layer?.transform.m41 ?? 0, 0, accuracy: 0.001)
    }

    @MainActor
    func testTrackpadHorizontalSwipePreservesTallPreviewAspectRatio() {
        let viewer = ImageViewerNSView()
        viewer.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        let currentImage = NSImage(size: NSSize(width: 500, height: 200))
        let tallPreviewImage = NSImage(size: NSSize(width: 120, height: 360))
        viewer.nextPreviewImageView.image = tallPreviewImage
        viewer.nextPreviewImageView.frame = NSRect(origin: .zero, size: tallPreviewImage.size)

        viewer.apply(
            resolvedImage: currentImage,
            imageURL: URL(fileURLWithPath: "/tmp/wide-current.jpg"),
            zoomMode: .custom(1.0),
            rotationQuarterTurns: 0
        )
        viewer.layoutSubtreeIfNeeded()

        viewer.applyInteractiveNavigationOffset(-80)

        let previewFrame = viewer.nextPreviewImageView.frame
        XCTAssertEqual(previewFrame.width / previewFrame.height, 120.0 / 360.0, accuracy: 0.001)
        XCTAssertLessThan(previewFrame.width, previewFrame.height)
    }

    @MainActor
    func testShortTrackpadHorizontalSwipeSnapsBackWithoutNavigating() async {
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

        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: -24, isTrackpad: true, phase: .began))
        XCTAssertTrue(viewer.handleScrollGesture(verticalDelta: 0, horizontalDelta: 0, isTrackpad: true, phase: .ended))
        try? await Task.sleep(for: .milliseconds(300))

        XCTAssertNil(requestedDirection)
        XCTAssertEqual(viewer.documentContainerView.layer?.transform.m41 ?? 0, 0, accuracy: 0.001)
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
    func testTinyPinchNoiseDoesNotCountAsSignificantMagnifyDelta() {
        XCTAssertFalse(ImageViewerTrackpadScrollCoordinator.isSignificantMagnifyDelta(-0.001))
        XCTAssertTrue(ImageViewerTrackpadScrollCoordinator.isSignificantMagnifyDelta(-0.02))
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
    func testPointerDragStartsPanningOnlyAfterDragTolerance() throws {
        let coordinator = ImageViewerPointerDragCoordinator()
        var panCount = 0

        XCTAssertTrue(
            coordinator.handle(
                .began,
                event: try Self.mouseEvent(location: NSPoint(x: 100, y: 100)),
                canPan: true,
                onPan: { _, _ in panCount += 1 }
            )
        )
        XCTAssertFalse(
            coordinator.handle(
                .changed,
                event: try Self.mouseEvent(location: NSPoint(x: 102, y: 101)),
                canPan: true,
                onPan: { _, _ in panCount += 1 }
            )
        )
        XCTAssertFalse(
            coordinator.handle(
                .ended,
                event: try Self.mouseEvent(location: NSPoint(x: 102, y: 101)),
                canPan: true,
                onPan: { _, _ in panCount += 1 }
            )
        )

        XCTAssertEqual(panCount, 0)
    }

    @MainActor
    func testPointerDragTracksContinuousWindowLocationsUntilDragEnds() throws {
        let coordinator = ImageViewerPointerDragCoordinator()
        var panLocations: [(previous: NSPoint, current: NSPoint)] = []

        _ = coordinator.handle(
            .began,
            event: try Self.mouseEvent(location: NSPoint(x: 100, y: 100)),
            canPan: true,
            onPan: { previous, current in panLocations.append((previous, current)) }
        )
        XCTAssertTrue(
            coordinator.handle(
                .changed,
                event: try Self.mouseEvent(location: NSPoint(x: 105, y: 100)),
                canPan: true,
                onPan: { previous, current in panLocations.append((previous, current)) }
            )
        )
        XCTAssertTrue(
            coordinator.handle(
                .changed,
                event: try Self.mouseEvent(location: NSPoint(x: 110, y: 95)),
                canPan: true,
                onPan: { previous, current in panLocations.append((previous, current)) }
            )
        )
        XCTAssertTrue(
            coordinator.handle(
                .ended,
                event: try Self.mouseEvent(location: NSPoint(x: 110, y: 95)),
                canPan: true,
                onPan: { previous, current in panLocations.append((previous, current)) }
            )
        )

        XCTAssertEqual(panLocations.count, 2)
        XCTAssertEqual(panLocations[0].previous, NSPoint(x: 100, y: 100))
        XCTAssertEqual(panLocations[0].current, NSPoint(x: 105, y: 100))
        XCTAssertEqual(panLocations[1].previous, NSPoint(x: 105, y: 100))
        XCTAssertEqual(panLocations[1].current, NSPoint(x: 110, y: 95))
    }

}
