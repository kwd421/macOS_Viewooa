import SwiftUI

struct ImageViewerContainerView: NSViewRepresentable {
    @ObservedObject var viewerState: ViewerState

    func makeNSView(context: Context) -> ImageViewerNSView {
        let nsView = ImageViewerNSView()
        nsView.onZoomModeChange = { zoomMode in
            guard viewerState.zoomMode != zoomMode else { return }
            viewerState.zoomMode = zoomMode
        }
        return nsView
    }

    func updateNSView(_ nsView: ImageViewerNSView, context: Context) {
        nsView.onZoomModeChange = { zoomMode in
            guard viewerState.zoomMode != zoomMode else { return }
            viewerState.zoomMode = zoomMode
        }

        nsView.apply(
            resolvedImage: viewerState.currentResolvedImage,
            imageURL: viewerState.currentImageURL,
            zoomMode: viewerState.zoomMode,
            rotationQuarterTurns: viewerState.rotationQuarterTurns
        )
    }
}
