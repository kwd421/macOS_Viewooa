import AppKit
import SwiftUI

private enum PhotoViewerOverlayLayout {
    static let controlBarEdgePadding: CGFloat = 20
    static let controlBarHeight = ViewerControlVisualStyle.iconSize + 20
    static let metadataPanelTopPadding: CGFloat = 76
    static let metadataPanelTopPaddingWithNavigationCount: CGFloat = 98
}

struct PhotoViewerFeatureView<Store: PhotoViewerControlling>: View {
    @ObservedObject var store: Store
    let areBrowserOverlaysVisible: Bool
    let onOpenBrowser: () -> Void
    let onZoomOut: () -> Void

    @AppStorage("viewer.bottomControlBarPinned") private var isControlBarPinned = true
    @State private var isHoveringControlRevealArea = false
    @AppStorage("viewer.topControlBarPinned") private var isTopControlBarPinned = true
    @State private var isHoveringTopControlRevealArea = false
    @State private var transientNoticeDismissTask: Task<Void, Never>?
    @State private var slideshowIntervalDraft = "3"

    var body: some View {
        ZStack {
            ImageViewerContainerView(
                configuration: store.imageViewerConfiguration,
                actions: store.imageViewerActions()
            )

            if hasImage, !areBrowserOverlaysVisible {
                topControlRevealArea
                navigationCountOverlay
                zoomPercentageOverlay
                metadataOverlay
                bottomControlRevealArea
                animatedImageControlsOverlay
            }

            if let overlayKind {
                ViewerOverlayCard(
                    kind: overlayKind,
                    onOpen: onOpenBrowser,
                    onDismissError: store.clearError
                )
            }

            transientNoticeOverlay
        }
        .animation(.easeOut(duration: 0.16), value: topControlsVisible)
        .animation(.easeOut(duration: 0.16), value: bottomControlsVisible)
        .animation(.easeOut(duration: 0.16), value: store.isMetadataVisible)
        .animation(.smooth(duration: 0.58, extraBounce: 0), value: store.isNavigationCountVisible)
        .animation(.easeOut(duration: 0.16), value: store.isZoomPercentageVisible)
        .animation(.easeOut(duration: 0.16), value: store.transientNotice)
        .onChange(of: store.transientNotice?.id) { _, noticeID in
            scheduleTransientNoticeDismissal(for: noticeID)
        }
        .onChange(of: store.slideshowIntervalSeconds) { _, seconds in
            slideshowIntervalDraft = ViewerSlideshowIntervalFormatter.string(for: seconds)
        }
        .onDisappear {
            transientNoticeDismissTask?.cancel()
        }
    }

    @ViewBuilder
    private var metadataOverlay: some View {
        if store.isMetadataVisible {
            VStack {
                HStack(alignment: .top) {
                    ImageMetadataPanel(rows: store.imageMetadataRows)
                    Spacer()
                }
                .padding(.leading, 18)
                .padding(
                    .top,
                    store.isNavigationCountVisible
                        ? PhotoViewerOverlayLayout.metadataPanelTopPaddingWithNavigationCount
                        : PhotoViewerOverlayLayout.metadataPanelTopPadding
                )

                Spacer()
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var bottomControlRevealArea: some View {
        VStack {
            Spacer()

            ZStack {
                Color.clear
                    .frame(height: 112)
                    .visualHoverTracking(isHovering: $isHoveringControlRevealArea, shape: Rectangle())

                bottomControlBar
                    .padding(.bottom, PhotoViewerOverlayLayout.controlBarEdgePadding)
                    .opacity(bottomControlsVisible ? 1 : 0)
                    .offset(y: bottomControlsVisible ? 0 : 4)
                    .blur(radius: bottomControlsVisible ? 0 : 0.7)
                    .allowsHitTesting(bottomControlsVisible)
                    .visualHoverTracking(isHovering: $isHoveringControlRevealArea, shape: Capsule())
            }
        }
    }

    private var topControlRevealArea: some View {
        VStack {
            ZStack(alignment: .top) {
                Color.clear
                    .frame(height: 78)
                    .visualHoverTracking(isHovering: $isHoveringTopControlRevealArea, shape: Rectangle())

                topControlBar
                    .padding(.top, PhotoViewerOverlayLayout.controlBarEdgePadding)
                    .opacity(topControlsVisible ? 1 : 0)
                    .offset(y: topControlsVisible ? 0 : -4)
                    .blur(radius: topControlsVisible ? 0 : 0.7)
                    .allowsHitTesting(topControlsVisible)
                    .visualHoverTracking(isHovering: $isHoveringTopControlRevealArea, shape: Capsule())
            }

            Spacer()
        }
    }

    private var topControlBar: some View {
        ViewerTopControlBar(
            store: store,
            isPinned: $isTopControlBarPinned,
            isHoveringRevealArea: $isHoveringTopControlRevealArea,
            slideshowIntervalDraft: $slideshowIntervalDraft
        )
    }

    private var bottomControlBar: some View {
        ViewerBottomControlBar(
            store: store,
            isPinned: $isControlBarPinned,
            onOpen: onOpenBrowser,
            onZoomOut: onZoomOut
        )
    }

    private var bottomControlsVisible: Bool {
        isControlBarPinned || isHoveringControlRevealArea
    }

    private var navigationCountOverlay: some View {
        VStack {
            HStack {
                ZStack {
                    Text(navigationCountSampleText)
                        .hidden()

                    Text(store.navigationCountText ?? navigationCountSampleText)
                }
                .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .frame(height: 34)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(VisualInteractionPalette.viewerSurfaceBorder)
                }
                .shadow(color: VisualInteractionPalette.viewerCardShadow, radius: 14, y: 7)
                .opacity(store.isNavigationCountVisible ? 1 : 0)
                .scaleEffect(store.isNavigationCountVisible ? 1 : 0.985, anchor: .topLeading)
                .offset(y: store.isNavigationCountVisible ? 0 : -5)
                .blur(radius: store.isNavigationCountVisible ? 0 : 1.1)

                Spacer()
            }
            .padding(.leading, 18)
            .padding(.top, 62)

            Spacer()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(!store.isNavigationCountVisible)
    }

    private var zoomPercentageOverlay: some View {
        VStack {
            HStack {
                Spacer()

                if store.isZoomPercentageVisible, let zoomPercentageText = store.zoomPercentageText {
                    Text(zoomPercentageText)
                        .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 13)
                        .frame(height: 34)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay {
                            Capsule().strokeBorder(VisualInteractionPalette.viewerSurfaceBorder)
                        }
                        .shadow(color: VisualInteractionPalette.viewerCardShadow, radius: 14, y: 7)
                        .transition(.opacity.combined(with: .scale(scale: 0.985, anchor: .topTrailing)))
                }
            }
            .padding(.trailing, 18)
            .padding(.top, 18)

            Spacer()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(!store.isZoomPercentageVisible)
    }

    @ViewBuilder
    private var animatedImageControlsOverlay: some View {
        if store.hasAnimatedImageFrames {
            HStack(spacing: 8) {
                Text(store.animatedImageFrameText ?? "1 / 1")
                    .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.leading, 12)
                    .frame(minWidth: 58, alignment: .leading)

                ViewerControlIconButton(
                    accessibilityLabel: "Previous GIF Frame",
                    systemImage: "minus",
                    action: store.showPreviousAnimatedImageFrame
                )

                ViewerControlIconButton(
                    accessibilityLabel: store.isAnimatedImagePlaying ? "Pause GIF" : "Play GIF",
                    systemImage: store.isAnimatedImagePlaying ? "pause.fill" : "play.fill",
                    action: store.toggleAnimatedImagePlayback
                )

                ViewerControlIconButton(
                    accessibilityLabel: "Next GIF Frame",
                    systemImage: "plus",
                    action: store.showNextAnimatedImageFrame
                )
            }
            .frame(height: PhotoViewerOverlayLayout.controlBarHeight)
            .animatedImageToolbarSurface()
            .padding(.leading, 18)
            .padding(.bottom, bottomControlsVisible ? 84 : 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var navigationCountSampleText: String {
        let totalCount = max(store.imageCount, 1)
        let digitCount = max(String(totalCount).count, 1)
        let digitBlock = String(repeating: "8", count: digitCount)
        return "\(digitBlock) / \(digitBlock)"
    }

    private var topControlsVisible: Bool {
        isTopControlBarPinned || isHoveringTopControlRevealArea
    }

    @ViewBuilder
    private var transientNoticeOverlay: some View {
        if let notice = store.transientNotice {
            VStack {
                Text(notice.message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(VisualInteractionPalette.viewerSurfaceBorder)
                    }
                    .shadow(color: VisualInteractionPalette.viewerCardShadow, radius: 14, y: 7)
                    .padding(.top, 18)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                Spacer()
            }
            .allowsHitTesting(false)
        }
    }

    private func scheduleTransientNoticeDismissal(for noticeID: ViewerTransientNotice.ID?) {
        transientNoticeDismissTask?.cancel()

        guard let noticeID else { return }
        transientNoticeDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.45))
            guard !Task.isCancelled else { return }
            store.clearTransientNotice(id: noticeID)
        }
    }

    private var hasImage: Bool {
        store.currentImageURL != nil
    }

    private var overlayKind: OverlayKind? {
        if let errorMessage = store.lastErrorMessage {
            return .error(message: errorMessage)
        }

        guard !areBrowserOverlaysVisible else { return nil }
        guard !hasImage else { return nil }
        return .empty
    }
}

private extension View {
    func animatedImageToolbarSurface() -> some View {
        VisualToolbarSurface(
            shape: Capsule(),
            style: VisualToolbarSurfaceStyle(
                backgroundStyle: .ultraThinMaterial,
                borderColor: VisualInteractionPalette.viewerSurfaceBorder,
                shadowColor: VisualInteractionPalette.viewerToolbarShadow,
                shadowRadius: 20,
                shadowYOffset: 10,
                horizontalPadding: 7,
                verticalPadding: 0
            )
        ) {
            self
        }
    }
}
