import SwiftUI

@main
struct ViewooaApp: App {
    var body: some Scene {
        WindowGroup {
            ViewerWindowShell()
        }
        .defaultSize(width: 900, height: 620)
        .windowResizability(.contentMinSize)
    }
}
