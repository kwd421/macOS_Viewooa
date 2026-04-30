import AppKit
import SwiftUI

struct ImageBrowserOverlay: View {
    let imageURLs: [URL]
    let currentIndex: Int?
    @Binding var displayMode: ImageBrowserDisplayMode
    @Binding var thumbnailSize: CGFloat
    let onSelect: (Int) -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isContentRevealed = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(VisualInteractionPalette.imageBrowserOverlayScrim)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Divider()
                    .overlay(VisualInteractionPalette.imageBrowserDivider)
                    .padding(.horizontal, 28)
                    .opacity(isContentRevealed || reduceMotion ? 1 : 0)

                ScrollViewReader { proxy in
                    ScrollView {
                        content
                            .padding(.horizontal, 30)
                            .padding(.top, 24)
                            .padding(.bottom, 34)
                    }
                    .scrollIndicators(.hidden)
                    .onAppear {
                        scrollToCurrentImage(with: proxy)
                    }
                    .onChange(of: displayMode) { _, _ in
                        revealContent()
                        scrollToCurrentImage(with: proxy)
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .onAppear(perform: revealContent)
        .overlay {
            ImageBrowserEscapeCatcher(onEscape: onDismiss)
                .frame(width: 0, height: 0)
        }
        .onExitCommand(perform: onDismiss)
        .accessibilityLabel("Image Browser")
    }

    private var header: some View {
        HStack(spacing: 14) {
            ImageBrowserCloseButton(action: onDismiss)

            VStack(alignment: .leading, spacing: 2) {
                Text("Images")
                    .font(.system(size: 16, weight: .semibold))
                Text(browserPositionText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(VisualInteractionPalette.imageBrowserSecondaryText)
            }

            Spacer()

            ThumbnailSizeStepperControl(thumbnailSize: $thumbnailSize, isVibrant: true)

            ImageBrowserViewModeControl(displayMode: $displayMode)
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .opacity(isContentRevealed || reduceMotion ? 1 : 0)
        .offset(y: isContentRevealed || reduceMotion ? 0 : -10)
        .animation(.smooth(duration: 0.32, extraBounce: 0), value: isContentRevealed)
    }

    @ViewBuilder
    private var content: some View {
        switch displayMode {
        case .thumbnails:
            thumbnailGrid
        case .list:
            listView
        }
    }

    private var thumbnailGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: thumbnailSize, maximum: thumbnailSize), spacing: 18)],
            alignment: .center,
            spacing: 22
        ) {
            ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                ImageBrowserThumbnailCell(
                    url: url,
                    index: index,
                    thumbnailSize: thumbnailSize,
                    isSelected: index == currentIndex,
                    isRevealed: isContentRevealed,
                    reduceMotion: reduceMotion,
                    onSelect: onSelect
                )
                .id(index)
            }
        }
    }

    private var listView: some View {
        LazyVStack(spacing: 6) {
            ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                ImageBrowserListRow(
                    url: url,
                    index: index,
                    isSelected: index == currentIndex,
                    isRevealed: isContentRevealed,
                    reduceMotion: reduceMotion,
                    onSelect: onSelect
                )
                .id(index)
            }
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
    }

    private var browserPositionText: String {
        guard let currentIndex else {
            return "\(imageURLs.count) images"
        }

        return "\(currentIndex + 1) of \(imageURLs.count)"
    }

    private func scrollToCurrentImage(with proxy: ScrollViewProxy) {
        guard let currentIndex else { return }
        DispatchQueue.main.async {
            withAnimation(.smooth(duration: 0.36, extraBounce: 0)) {
                proxy.scrollTo(currentIndex, anchor: .center)
            }
        }
    }

    private func revealContent() {
        guard !reduceMotion else {
            isContentRevealed = true
            return
        }

        isContentRevealed = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.035) {
            isContentRevealed = true
        }
    }
}

private struct ImageBrowserCloseButton: View {
    let action: () -> Void

    var body: some View {
        VisualIconActionButton(
            accessibilityLabel: "Close Image Browser",
            systemImage: "xmark",
            style: Self.style,
            shape: Circle(),
            action: action
        )
    }

    private static var style: VisualIconActionStyle {
        VisualIconActionStyle(
            size: 28,
            fontSize: 12,
            fontWeight: .bold,
            foregroundColor: { _ in .white },
            backgroundColor: { isHovering in
                VisualInteractionPalette.imageBrowserCloseButtonBackground.color(isHovering: isHovering)
            }
        )
    }
}
