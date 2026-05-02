import AppKit
import SwiftUI

@main
struct FinderBrowserStandaloneApp: App {
    @State private var displayMode: BrowserDisplayMode = .thumbnails
    @State private var thumbnailSize: CGFloat = 132
    @State private var initialDirectory = FileManager.default.homeDirectoryForCurrentUser

    var body: some Scene {
        Window("Viewooa Finder Browser", id: "finder-browser") {
            OpenBrowserOverlay(
                initialDirectory: initialDirectory,
                displayMode: $displayMode,
                thumbnailSize: $thumbnailSize,
                onOpen: handleOpen,
                onDismiss: handleDismiss,
                prefersRecentDirectory: true
            )
            .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 960, height: 680)
        .windowResizability(.contentMinSize)
    }

    private func handleOpen(_ url: URL) {
        if FileManager.default.directoryExists(at: url) {
            initialDirectory = url
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    private func handleDismiss() {
        if let window = NSApp.keyWindow {
            window.performClose(nil)
        } else {
            NSApp.terminate(nil)
        }
    }
}

private extension FileManager {
    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
