import SwiftUI

struct ImageViewerContainerView: NSViewRepresentable {
    @ObservedObject var viewerState: ViewerState

    func makeNSView(context: Context) -> ImageViewerNSView {
        ImageViewerNSView()
    }

    func updateNSView(_ nsView: ImageViewerNSView, context: Context) {
        nsView.apply(
            imageURL: viewerState.currentImageURL,
            zoomMode: viewerState.zoomMode,
            rotationQuarterTurns: viewerState.rotationQuarterTurns
        )
    }
}
