import AppKit
import SwiftUI

private enum PhotoViewerOverlayLayout {
    static let controlBarEdgePadding: CGFloat = 20
    static let metadataPanelTopPadding: CGFloat = 76
    static let metadataPanelTopPaddingWithNavigationCount: CGFloat = 98
}

struct PhotoViewerFeatureView<Store: PhotoViewerControlling>: View {
    @ObservedObject var store: Store
    let areBrowserOverlaysVisible: Bool
    let onOpenBrowser: () -> Void
    let onZoomOut: () -> Void
    let onFitZoomOutRequest: () -> Bool

    @State private var isControlBarPinned = true
    @State private var isHoveringControlRevealArea = false
    @State private var isTopControlBarPinned = true
    @State private var isHoveringTopControlRevealArea = false
    @State private var transientNoticeDismissTask: Task<Void, Never>?
    @State private var slideshowIntervalDraft = "3"

    var body: some View {
        ZStack {
            ImageViewerContainerView(
                configuration: store.imageViewerConfiguration,
                actions: store.imageViewerActions(onFitZoomOutRequest: onFitZoomOutRequest)
            )

            if hasImage, !areBrowserOverlaysVisible {
                topControlRevealArea
                navigationCountOverlay
                metadataOverlay
                bottomControlRevealArea
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
                    Capsule().strokeBorder(.white.opacity(0.14))
                }
                .shadow(color: .black.opacity(0.28), radius: 14, y: 7)
                .opacity(store.isNavigationCountVisible ? 1 : 0)
                .scaleEffect(store.isNavigationCountVisible ? 1 : 0.985, anchor: .topLeading)
                .offset(y: store.isNavigationCountVisible ? 0 : -5)
                .blur(radius: store.isNavigationCountVisible ? 0 : 1.1)

                Spacer()
            }
            .padding(.leading, 18)
            .padding(.top, 18)

            Spacer()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(!store.isNavigationCountVisible)
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
                        Capsule().strokeBorder(.white.opacity(0.14))
                    }
                    .shadow(color: .black.opacity(0.28), radius: 14, y: 7)
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
