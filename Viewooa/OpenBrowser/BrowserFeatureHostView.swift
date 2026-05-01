import SwiftUI

struct BrowserFeatureHostView: View {
    let isOpenBrowserVisible: Bool
    let initialDirectory: URL
    @Binding var displayMode: BrowserDisplayMode
    @Binding var thumbnailSize: CGFloat
    let onOpen: (URL) -> Void
    let onDismissOpenBrowser: () -> Void

    var body: some View {
        ZStack {
            openBrowserOverlay
        }
        .animation(.smooth(duration: 0.24, extraBounce: 0), value: isOpenBrowserVisible)
    }

    @ViewBuilder
    private var openBrowserOverlay: some View {
        if isOpenBrowserVisible {
            OpenBrowserOverlay(
                initialDirectory: initialDirectory,
                displayMode: $displayMode,
                thumbnailSize: $thumbnailSize,
                onOpen: onOpen,
                onDismiss: onDismissOpenBrowser
            )
            .ignoresSafeArea()
            .transition(.opacity.combined(with: .scale(scale: 0.985)))
            .zIndex(11)
        }
    }
}
