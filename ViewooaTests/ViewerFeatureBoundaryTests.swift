import XCTest
import SwiftUI
import AppKit
@testable import Viewooa

final class ViewerFeatureBoundaryTests: XCTestCase {
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
        var displayMode = BrowserDisplayMode.thumbnails
        var thumbnailSize: CGFloat = 132

        _ = BrowserFeatureHostView(
            isOpenBrowserVisible: false,
            initialDirectory: FileManager.default.homeDirectoryForCurrentUser,
            displayMode: Binding(
                get: { displayMode },
                set: { displayMode = $0 }
            ),
            thumbnailSize: Binding(
                get: { thumbnailSize },
                set: { thumbnailSize = $0 }
            ),
            onOpen: { _ in },
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
                imageRevision: 0,
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
                onVerticalSlideshowReachedEnd: {}
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
            onZoomOut: {}
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

        store.setThumbnailSize(12)
        XCTAssertEqual(store.thumbnailSize, 72)

        store.setThumbnailSize(500)
        XCTAssertEqual(store.thumbnailSize, 220)
    }

    @MainActor
    func testBottomToolbarSeparatorsOnlyFrameOpenAndPinSections() {
        XCTAssertTrue(ViewerBottomToolbarSection.open.showsTrailingSeparator)
        XCTAssertFalse(ViewerBottomToolbarSection.open.showsLeadingSeparator)

        XCTAssertFalse(ViewerBottomToolbarSection.zoom.showsLeadingSeparator)
        XCTAssertFalse(ViewerBottomToolbarSection.zoom.showsTrailingSeparator)

        XCTAssertFalse(ViewerBottomToolbarSection.navigation.showsLeadingSeparator)
        XCTAssertFalse(ViewerBottomToolbarSection.navigation.showsTrailingSeparator)

        XCTAssertTrue(ViewerBottomToolbarSection.pin.showsLeadingSeparator)
        XCTAssertFalse(ViewerBottomToolbarSection.pin.showsTrailingSeparator)
    }

    @MainActor
    func testProminentViewerToolbarIconStyleAddsContrastAndPersistentBorder() {
        let standardStyle = ViewerControlVisualStyle.iconActionStyle(isActive: false)
        let prominentStyle = ViewerControlVisualStyle.iconActionStyle(isActive: false, emphasis: .prominent)

        XCTAssertNil(standardStyle.overlay)
        XCTAssertNotNil(prominentStyle.overlay)

        XCTAssertGreaterThan(
            alphaComponent(of: prominentStyle.backgroundColor(false)),
            alphaComponent(of: standardStyle.backgroundColor(false))
        )
    }

    private func alphaComponent(of color: Color) -> CGFloat {
        NSColor(color).alphaComponent
    }
}
