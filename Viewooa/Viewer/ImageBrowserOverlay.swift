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
                .fill(.black.opacity(0.34))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Divider()
                    .overlay(.white.opacity(0.16))
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
                    .foregroundStyle(.white.opacity(0.58))
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
        VisualHoverState(shape: Circle()) { isHovering in
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(Self.backgroundColor.color(isHovering: isHovering), in: Circle())
                    .visualHitArea(Circle())
            }
            .frame(width: 28, height: 28)
            .visualHitArea(Circle())
            .buttonStyle(.plain)
            .accessibilityLabel("Close Image Browser")
        }
        .frame(width: 28, height: 28)
    }

    private static let backgroundColor = VisualHoverColorStyle(
        normal: .white.opacity(0.12),
        hover: .white.opacity(0.28)
    )
}
