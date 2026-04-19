import SwiftUI

struct ViewerCommands: Commands {
    let openFile: () -> Void
    let openFolder: () -> Void
    let showPreviousImage: () -> Void
    let showNextImage: () -> Void

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
    }
}
