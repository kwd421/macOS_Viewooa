import SwiftUI

struct ViewerCommands: Commands {
    let openFile: () -> Void
    let openFolder: () -> Void
    let showPreviousImage: () -> Void
    let showNextImage: () -> Void
    let rotateClockwise: () -> Void
    let zoomIn: () -> Void
    let zoomOut: () -> Void
    let zoomToActualSize: () -> Void
    let zoomToFit: () -> Void

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open File...", action: openFile)
                .keyboardShortcut("o", modifiers: [.command])

            Button("Open Folder...", action: openFolder)
                .keyboardShortcut("o", modifiers: [.command, .shift])
        }

        CommandMenu("Navigate") {
            Button("Previous Image", action: showPreviousImage)
                .keyboardShortcut(.leftArrow, modifiers: [])

            Button("Next Image", action: showNextImage)
                .keyboardShortcut(.rightArrow, modifiers: [])
        }

        CommandMenu("View") {
            Button("Zoom In", action: zoomIn)
                .keyboardShortcut("=", modifiers: [.command])

            Button("Zoom Out", action: zoomOut)
                .keyboardShortcut("-", modifiers: [.command])

            Divider()

            Button("Actual Size", action: zoomToActualSize)
                .keyboardShortcut("0", modifiers: [.command])

            Button("Fit to Window", action: zoomToFit)

            Divider()

            Button("Rotate Right", action: rotateClockwise)
                .keyboardShortcut("r", modifiers: [.command])
        }
    }
}
