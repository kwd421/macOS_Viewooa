import AppKit
import SwiftUI

struct ImageViewerContainerConfiguration {
    let resolvedImage: NSImage?
    let resolvedImages: [NSImage]?
    let imageURL: URL?
    let imageURLs: [URL]?
    let zoomMode: ZoomMode
    let rotationQuarterTurns: Int
    let pageLayout: ViewerPageLayout
    let fitRequestID: Int
    let postProcessingOptions: Set<ImagePostProcessingOption>
    let verticalAutoScrollScreenSpeed: CGFloat
}

struct ImageViewerContainerActions {
    let onZoomModeChange: (ZoomMode) -> Void
    let onViewportMetricsChange: (CGFloat, CGFloat, Bool) -> Void
    let onNavigate: (ImageViewerNSView.NavigationDirection) -> Void
    let onToggleMetadata: () -> Void
    let onNavigationHoldChange: (Bool) -> Void
    let onPostProcessingToggle: (ImagePostProcessingOption) -> Void
    let onPostProcessingClear: () -> Void
    let onVerticalSlideshowReachedEnd: () -> Void
}

struct ImageViewerContainerView: NSViewRepresentable {
    let configuration: ImageViewerContainerConfiguration
    let actions: ImageViewerContainerActions

    func makeNSView(context: Context) -> ImageViewerNSView {
        let nsView = ImageViewerNSView()
        applyActions(to: nsView)
        return nsView
    }

    func updateNSView(_ nsView: ImageViewerNSView, context: Context) {
        applyActions(to: nsView)

        nsView.apply(
            resolvedImage: configuration.resolvedImage,
            resolvedImages: configuration.resolvedImages,
            imageURL: configuration.imageURL,
            imageURLs: configuration.imageURLs,
            zoomMode: configuration.zoomMode,
            rotationQuarterTurns: configuration.rotationQuarterTurns,
            pageLayout: configuration.pageLayout,
            fitRequestID: configuration.fitRequestID,
            postProcessingOptions: configuration.postProcessingOptions,
            verticalAutoScrollScreenSpeed: configuration.verticalAutoScrollScreenSpeed
        )
    }

    private func applyActions(to nsView: ImageViewerNSView) {
        nsView.onZoomModeChange = actions.onZoomModeChange
        nsView.onViewportMetricsChange = actions.onViewportMetricsChange
        nsView.onNavigateRequest = actions.onNavigate
        nsView.onToggleMetadataRequest = actions.onToggleMetadata
        nsView.onNavigationHoldChange = actions.onNavigationHoldChange
        nsView.onPostProcessingToggle = actions.onPostProcessingToggle
        nsView.onPostProcessingClear = actions.onPostProcessingClear
        nsView.onVerticalSlideshowReachedEnd = actions.onVerticalSlideshowReachedEnd
    }
}
