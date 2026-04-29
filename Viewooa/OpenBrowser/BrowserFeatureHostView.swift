import SwiftUI

struct BrowserFeatureHostView: View {
    let isImageBrowserVisible: Bool
    let isOpenBrowserVisible: Bool
    let imageURLs: [URL]
    let currentIndex: Int?
    let initialDirectory: URL
    @Binding var displayMode: ImageBrowserDisplayMode
    @Binding var thumbnailSize: CGFloat
    let onSelectImage: (Int) -> Void
    let onOpen: (URL) -> Void
    let onDismissImageBrowser: () -> Void
    let onDismissOpenBrowser: () -> Void

    var body: some View {
        ZStack {
            imageBrowserOverlay
            openBrowserOverlay
        }
        .animation(.smooth(duration: 0.24, extraBounce: 0), value: isImageBrowserVisible)
        .animation(.smooth(duration: 0.24, extraBounce: 0), value: isOpenBrowserVisible)
    }

    @ViewBuilder
    private var imageBrowserOverlay: some View {
        if isImageBrowserVisible {
            ImageBrowserOverlay(
                imageURLs: imageURLs,
                currentIndex: currentIndex,
                displayMode: $displayMode,
                thumbnailSize: $thumbnailSize,
                onSelect: onSelectImage,
                onDismiss: onDismissImageBrowser
            )
            .transition(.opacity.combined(with: .scale(scale: 0.985)))
            .zIndex(10)
        }
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
