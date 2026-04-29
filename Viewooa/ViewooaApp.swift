import SwiftUI

@main
struct ViewooaApp: App {
    @StateObject private var bridge = ViewooaBridge()

    var body: some Scene {
        Self.makeViewerScene(bridge: bridge)
    }

    static func makeViewerScene(bridge: ViewooaBridge) -> some Scene {
        Window("Viewooa", id: "viewer") {
            ViewerWindowShell(bridge: bridge)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 620)
        .windowResizability(.contentMinSize)
        .commands {
            ViewerCommands(
                openFile: bridge.presentOpenBrowser,
                openFolder: bridge.presentOpenBrowser,
                showPreviousImage: bridge.showPreviousImage,
                showNextImage: bridge.showNextImage,
                rotateClockwise: bridge.rotateClockwise,
                zoomIn: bridge.zoomIn,
                zoomOut: bridge.zoomOut,
                zoomToActualSize: bridge.zoomToActualSize,
                zoomToFitHeight: { bridge.zoomToFit(.height) },
                zoomToFitWidth: { bridge.zoomToFit(.width) },
                zoomToFitAll: { bridge.zoomToFit(.all) }
            )
        }
    }
}
