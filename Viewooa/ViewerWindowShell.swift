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
                onZoomOut: bridge.zoomOut
            )
            .ignoresSafeArea()

            BrowserFeatureHostView(
                isOpenBrowserVisible: bridge.isOpenBrowserVisible,
                initialDirectory: bridge.initialOpenBrowserDirectory,
                displayMode: Binding(
                    get: { bridge.browserDisplayMode },
                    set: { bridge.setBrowserDisplayMode($0) }
                ),
                thumbnailSize: Binding(
                    get: { bridge.browserThumbnailSize },
                    set: { bridge.setBrowserThumbnailSize($0) }
                ),
                onOpen: bridge.openSelectionFromBrowser,
                onDismissOpenBrowser: bridge.hideOpenBrowser
            )
        }
        .background(WindowChromeConfigurator())
    }
}
