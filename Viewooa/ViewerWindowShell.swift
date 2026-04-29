import SwiftUI

struct ViewerWindowShell: View {
    @ObservedObject var bridge: ViewooaBridge

    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()

            PhotoViewerFeatureView(
                store: bridge.photoViewerStore,
                areBrowserOverlaysVisible: bridge.areBrowserOverlaysVisible,
                onOpenBrowser: bridge.presentOpenBrowser,
                onZoomOut: bridge.zoomOut,
                onFitZoomOutRequest: bridge.showImageBrowser
            )
            .ignoresSafeArea()

            BrowserFeatureHostView(
                isImageBrowserVisible: bridge.isImageBrowserVisible,
                isOpenBrowserVisible: bridge.isOpenBrowserVisible,
                imageURLs: bridge.browserImageURLs,
                currentIndex: bridge.currentBrowserIndex,
                initialDirectory: bridge.initialOpenBrowserDirectory,
                displayMode: Binding(
                    get: { bridge.browserDisplayMode },
                    set: { bridge.setBrowserDisplayMode($0) }
                ),
                thumbnailSize: Binding(
                    get: { bridge.browserThumbnailSize },
                    set: { bridge.setBrowserThumbnailSize($0) }
                ),
                onSelectImage: bridge.selectImageFromBrowser,
                onOpen: bridge.openSelectionFromBrowser,
                onDismissImageBrowser: bridge.hideImageBrowser,
                onDismissOpenBrowser: bridge.hideOpenBrowser
            )
        }
        .background(WindowChromeConfigurator())
    }
}
