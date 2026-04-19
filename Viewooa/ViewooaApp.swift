import SwiftUI

@main
struct ViewooaApp: App {
    @StateObject private var viewerState = ViewerState()

    var body: some Scene {
        Self.makeViewerScene(viewerState: viewerState)
    }

    static func makeViewerScene(viewerState: ViewerState) -> some Scene {
        Window("Viewooa", id: "viewer") {
            ViewerWindowShell(viewerState: viewerState)
        }
        .defaultSize(width: 900, height: 620)
        .windowResizability(.contentMinSize)
        .commands {
            ViewerCommands(
                openFile: viewerState.presentOpenFilePanel,
                openFolder: viewerState.presentOpenFolderPanel,
                showPreviousImage: viewerState.showPreviousImage,
                showNextImage: viewerState.showNextImage
            )
        }
    }
}
