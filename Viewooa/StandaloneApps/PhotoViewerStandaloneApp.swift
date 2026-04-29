import AppKit
import SwiftUI

@main
struct PhotoViewerStandaloneApp: App {
    @StateObject private var store = PhotoViewerStore(viewerState: ViewerState())

    var body: some Scene {
        Window("Viewooa Photo Viewer", id: "photo-viewer") {
            ZStack {
                Color.black.opacity(0.96).ignoresSafeArea()

                PhotoViewerFeatureView(
                    store: store,
                    areBrowserOverlaysVisible: false,
                    onOpenBrowser: openFileOrFolder,
                    onZoomOut: store.zoomOut,
                    onFitZoomOutRequest: { false }
                )
                .ignoresSafeArea()
            }
            .background(WindowChromeConfigurator())
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 620)
        .windowResizability(.contentMinSize)
        .commands {
            ViewerCommands(
                openFile: openFile,
                openFolder: openFolder,
                showPreviousImage: store.showPreviousImageFromNavigationShortcut,
                showNextImage: store.showNextImageFromNavigationShortcut,
                rotateClockwise: store.rotateClockwise,
                zoomIn: store.zoomIn,
                zoomOut: store.zoomOut,
                zoomToActualSize: store.zoomToActualSize,
                zoomToFitHeight: { store.zoomToFit(.height) },
                zoomToFitWidth: { store.zoomToFit(.width) },
                zoomToFitAll: { store.zoomToFit(.all) }
            )
        }
    }

    private func openFileOrFolder() {
        openSelection(canChooseFiles: true, canChooseDirectories: true)
    }

    private func openFile() {
        openSelection(canChooseFiles: true, canChooseDirectories: false)
    }

    private func openFolder() {
        openSelection(canChooseFiles: false, canChooseDirectories: true)
    }

    private func openSelection(canChooseFiles: Bool, canChooseDirectories: Bool) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = canChooseFiles
        panel.canChooseDirectories = canChooseDirectories
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.openSelection(at: url)
    }
}
