import AppKit
import SwiftUI

struct ViewerWindowShell: View {
    @ObservedObject var viewerState: ViewerState
    @State private var isControlBarPinned = true
    @State private var isHoveringControlRevealArea = false
    @State private var isTopControlBarPinned = true
    @State private var isHoveringTopControlRevealArea = false
    @State private var transientNoticeDismissTask: Task<Void, Never>?
    @State private var slideshowIntervalDraft = "3"

    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()
            ImageViewerContainerView(viewerState: viewerState)

            if hasImage, !viewerState.isImageBrowserVisible, !viewerState.isOpenBrowserVisible {
                topControlRevealArea
                navigationCountOverlay
                metadataOverlay
                bottomControlRevealArea
            }

            if viewerState.isImageBrowserVisible {
                ImageBrowserOverlay(
                    imageURLs: viewerState.browserImageURLs,
                    currentIndex: viewerState.currentBrowserIndex,
                    displayMode: Binding(
                        get: { viewerState.imageBrowserDisplayMode },
                        set: { viewerState.setImageBrowserDisplayMode($0) }
                    ),
                    thumbnailSize: Binding(
                        get: { viewerState.imageBrowserThumbnailSize },
                        set: { viewerState.setImageBrowserThumbnailSize($0) }
                    ),
                    onSelect: viewerState.selectImageFromBrowser,
                    onDismiss: viewerState.hideImageBrowser
                )
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
                .zIndex(10)
            }

            if viewerState.isOpenBrowserVisible {
                OpenBrowserOverlay(
                    initialDirectory: initialOpenBrowserDirectory,
                    displayMode: Binding(
                        get: { viewerState.imageBrowserDisplayMode },
                        set: { viewerState.setImageBrowserDisplayMode($0) }
                    ),
                    thumbnailSize: Binding(
                        get: { viewerState.imageBrowserThumbnailSize },
                        set: { viewerState.setImageBrowserThumbnailSize($0) }
                    ),
                    onOpen: viewerState.openSelectionFromBrowser,
                    onDismiss: viewerState.hideOpenBrowser
                )
                .ignoresSafeArea()
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
                .zIndex(11)
            }

            if let overlayKind {
                ViewerOverlayCard(
                    kind: overlayKind,
                    onOpen: viewerState.presentOpenSelectionPanel,
                    onDismissError: viewerState.clearError
                )
            }

            transientNoticeOverlay
        }
        .animation(.easeOut(duration: 0.16), value: topControlsVisible)
        .animation(.easeOut(duration: 0.16), value: bottomControlsVisible)
        .animation(.easeOut(duration: 0.16), value: viewerState.isMetadataVisible)
        .animation(.smooth(duration: 0.58, extraBounce: 0), value: viewerState.isNavigationCountVisible)
        .animation(.easeOut(duration: 0.16), value: viewerState.transientNotice)
        .animation(.smooth(duration: 0.24, extraBounce: 0), value: viewerState.isImageBrowserVisible)
        .animation(.smooth(duration: 0.24, extraBounce: 0), value: viewerState.isOpenBrowserVisible)
        .onChange(of: viewerState.transientNotice?.id) { _, noticeID in
            scheduleTransientNoticeDismissal(for: noticeID)
        }
        .onChange(of: viewerState.slideshowIntervalSeconds) { _, seconds in
            slideshowIntervalDraft = ViewerSlideshowIntervalFormatter.string(for: seconds)
        }
        .onDisappear {
            transientNoticeDismissTask?.cancel()
        }
        .background(WindowChromeConfigurator())
    }

    @ViewBuilder
    private var metadataOverlay: some View {
        if viewerState.isMetadataVisible {
            VStack {
                HStack(alignment: .top) {
                    ImageMetadataPanel(rows: viewerState.imageMetadataRows)
                    Spacer()
                }
                .padding(.leading, 18)
                .padding(.top, viewerState.isNavigationCountVisible ? 62 : 18)

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
                    .contentShape(Rectangle())
                    .onHover { isHoveringControlRevealArea = $0 }

                if bottomControlsVisible {
                    bottomControlBar
                        .padding(.bottom, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .onHover { isHoveringControlRevealArea = $0 }
                }
            }
        }
    }

    private var topControlRevealArea: some View {
        VStack {
            ZStack(alignment: .top) {
                Color.clear
                    .frame(height: 78)
                    .contentShape(Rectangle())
                    .onHover { isHoveringTopControlRevealArea = $0 }

                topControlBar
                    .padding(.top, 8)
                    .opacity(topControlsVisible ? 1 : 0)
                    .offset(y: topControlsVisible ? 0 : -4)
                    .blur(radius: topControlsVisible ? 0 : 0.7)
                    .allowsHitTesting(topControlsVisible)
                    .onHover { isHoveringTopControlRevealArea = $0 }
            }

            Spacer()
        }
    }

    private var topControlBar: some View {
        ViewerTopControlBar(
            viewerState: viewerState,
            isPinned: $isTopControlBarPinned,
            isHoveringRevealArea: $isHoveringTopControlRevealArea,
            slideshowIntervalDraft: $slideshowIntervalDraft
        )
    }

    private var bottomControlBar: some View {
        ViewerBottomControlBar(
            viewerState: viewerState,
            isPinned: $isControlBarPinned
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

                    Text(viewerState.navigationCountText ?? navigationCountSampleText)
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
                .opacity(viewerState.isNavigationCountVisible ? 1 : 0)
                .scaleEffect(viewerState.isNavigationCountVisible ? 1 : 0.985, anchor: .topLeading)
                .offset(y: viewerState.isNavigationCountVisible ? 0 : -5)
                .blur(radius: viewerState.isNavigationCountVisible ? 0 : 1.1)

                Spacer()
            }
            .padding(.leading, 18)
            .padding(.top, 18)

            Spacer()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(!viewerState.isNavigationCountVisible)
    }

    private var navigationCountSampleText: String {
        let totalCount = max(viewerState.index?.imageURLs.count ?? 1, 1)
        let digitCount = max(String(totalCount).count, 1)
        let digitBlock = String(repeating: "8", count: digitCount)
        return "\(digitBlock) / \(digitBlock)"
    }

    private var topControlsVisible: Bool {
        isTopControlBarPinned || isHoveringTopControlRevealArea
    }

    @ViewBuilder
    private var transientNoticeOverlay: some View {
        if let notice = viewerState.transientNotice {
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
            viewerState.clearTransientNotice(id: noticeID)
        }
    }

    private var hasImage: Bool {
        viewerState.currentImageURL != nil
    }

    private var initialOpenBrowserDirectory: URL {
        guard let directory = viewerState.currentImageURL?.deletingLastPathComponent() else {
            return FileManager.default.homeDirectoryForCurrentUser
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return FileManager.default.homeDirectoryForCurrentUser
        }

        return directory
    }

    private var overlayKind: OverlayKind? {
        if let errorMessage = viewerState.lastErrorMessage {
            return .error(message: errorMessage)
        }

        guard !viewerState.isOpenBrowserVisible else { return nil }
        guard !hasImage else { return nil }
        return .empty
    }
}
