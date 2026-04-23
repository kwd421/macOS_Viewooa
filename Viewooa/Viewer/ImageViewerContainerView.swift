import SwiftUI

struct ImageViewerContainerView: NSViewRepresentable {
    @ObservedObject var viewerState: ViewerState

    func makeNSView(context: Context) -> ImageViewerNSView {
        let nsView = ImageViewerNSView()
        nsView.onZoomModeChange = { zoomMode in
            guard viewerState.zoomMode != zoomMode else { return }
            viewerState.zoomMode = zoomMode
        }
        nsView.onViewportMetricsChange = { displayedMagnification, fitMagnification, isEntireImageVisible in
            viewerState.updateViewportMetrics(
                displayedMagnification: displayedMagnification,
                fitMagnification: fitMagnification,
                isEntireImageVisible: isEntireImageVisible
            )
        }
        nsView.onNavigateRequest = { direction in
            switch direction {
            case .previous:
                viewerState.showPreviousImage()
            case .next:
                viewerState.showNextImage()
            }
        }
        nsView.onToggleMetadataRequest = {
            viewerState.toggleMetadataVisibility()
        }
        nsView.onNavigationHoldChange = { isHolding in
            if isHolding {
                viewerState.beginNavigationHoldIndicator()
            } else {
                viewerState.endNavigationHoldIndicator()
            }
        }
        nsView.onPostProcessingToggle = { option in
            viewerState.togglePostProcessing(option)
        }
        nsView.onPostProcessingClear = {
            viewerState.clearPostProcessing()
        }
        nsView.onVerticalSlideshowReachedEnd = {
            viewerState.stopSlideshow()
        }
        return nsView
    }

    func updateNSView(_ nsView: ImageViewerNSView, context: Context) {
        nsView.onZoomModeChange = { zoomMode in
            guard viewerState.zoomMode != zoomMode else { return }
            viewerState.zoomMode = zoomMode
        }
        nsView.onViewportMetricsChange = { displayedMagnification, fitMagnification, isEntireImageVisible in
            viewerState.updateViewportMetrics(
                displayedMagnification: displayedMagnification,
                fitMagnification: fitMagnification,
                isEntireImageVisible: isEntireImageVisible
            )
        }
        nsView.onNavigateRequest = { direction in
            switch direction {
            case .previous:
                viewerState.showPreviousImage()
            case .next:
                viewerState.showNextImage()
            }
        }
        nsView.onToggleMetadataRequest = {
            viewerState.toggleMetadataVisibility()
        }
        nsView.onNavigationHoldChange = { isHolding in
            if isHolding {
                viewerState.beginNavigationHoldIndicator()
            } else {
                viewerState.endNavigationHoldIndicator()
            }
        }
        nsView.onPostProcessingToggle = { option in
            viewerState.togglePostProcessing(option)
        }
        nsView.onPostProcessingClear = {
            viewerState.clearPostProcessing()
        }
        nsView.onVerticalSlideshowReachedEnd = {
            viewerState.stopSlideshow()
        }

        nsView.apply(
            resolvedImage: viewerState.currentResolvedImage,
            resolvedImages: viewerState.displayResolvedImages,
            imageURL: viewerState.currentImageURL,
            imageURLs: viewerState.displayImageURLs,
            zoomMode: viewerState.zoomMode,
            rotationQuarterTurns: viewerState.rotationQuarterTurns,
            pageLayout: viewerState.pageLayout,
            fitRequestID: viewerState.fitRequestID,
            postProcessingOptions: viewerState.postProcessingOptions,
            verticalAutoScrollScreenSpeed: viewerState.activeVerticalSlideshowScrollSpeed
        )
    }
}
