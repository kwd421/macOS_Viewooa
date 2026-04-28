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
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close Image Browser")

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

private struct ImageBrowserViewModeControl: View {
    @Binding var displayMode: ImageBrowserDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImageBrowserDisplayMode.allCases) { mode in
                Button {
                    displayMode = mode
                } label: {
                    Image(systemName: mode.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 32, height: 26)
                        .foregroundStyle(displayMode == mode ? .white : .white.opacity(0.58))
                        .background(
                            displayMode == mode ? .white.opacity(0.18) : .clear,
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.title)
            }
        }
        .padding(2)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ImageBrowserThumbnailCell: View {
    let url: URL
    let index: Int
    let thumbnailSize: CGFloat
    let isSelected: Bool
    let isRevealed: Bool
    let reduceMotion: Bool
    let onSelect: (Int) -> Void

    var body: some View {
        Button {
            onSelect(index)
        } label: {
            VStack(spacing: 9) {
                ImageBrowserThumbnail(url: url, targetPixelSize: max(thumbnailSize * 1.6, 160))
                    .frame(width: thumbnailSize, height: thumbnailSize * 0.72)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(isSelected ? .white : .white.opacity(0.14), lineWidth: isSelected ? 2 : 1)
                    }
                    .shadow(color: .black.opacity(isSelected ? 0.42 : 0.24), radius: isSelected ? 18 : 10, y: isSelected ? 9 : 5)

                Text(url.lastPathComponent)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.74))
                    .frame(width: thumbnailSize)
            }
            .padding(8)
            .background(isSelected ? .white.opacity(0.15) : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(url.lastPathComponent)
        .opacity(isRevealed || reduceMotion ? 1 : 0)
        .scaleEffect(isRevealed || reduceMotion ? 1 : 0.965)
        .offset(y: isRevealed || reduceMotion ? 0 : 18)
        .animation(revealAnimation, value: isRevealed)
    }

    private var revealAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .smooth(duration: 0.46, extraBounce: 0.08)
            .delay(Self.revealDelay(for: index))
    }

    private static func revealDelay(for index: Int) -> Double {
        min(Double(index % 24) * 0.018, 0.26)
    }
}

private struct ImageBrowserListRow: View {
    let url: URL
    let index: Int
    let isSelected: Bool
    let isRevealed: Bool
    let reduceMotion: Bool
    let onSelect: (Int) -> Void

    var body: some View {
        Button {
            onSelect(index)
        } label: {
            HStack(spacing: 12) {
                ImageBrowserThumbnail(url: url, targetPixelSize: 96)
                    .frame(width: 58, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(.white.opacity(0.14))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(url.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(url.deletingLastPathComponent().lastPathComponent)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.54))
                        .lineLimit(1)
                }

                Spacer()

                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.52))
            }
            .padding(.horizontal, 12)
            .frame(height: 58)
            .background(isSelected ? .white.opacity(0.16) : .white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? .white.opacity(0.48) : .white.opacity(0.08))
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(url.lastPathComponent)
        .opacity(isRevealed || reduceMotion ? 1 : 0)
        .scaleEffect(isRevealed || reduceMotion ? 1 : 0.985)
        .offset(y: isRevealed || reduceMotion ? 0 : 12)
        .animation(revealAnimation, value: isRevealed)
    }

    private var revealAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .smooth(duration: 0.38, extraBounce: 0.04)
            .delay(Self.revealDelay(for: index))
    }

    private static func revealDelay(for index: Int) -> Double {
        min(Double(index % 18) * 0.015, 0.2)
    }
}

private struct ImageBrowserEscapeCatcher: NSViewRepresentable {
    let onEscape: () -> Void

    func makeNSView(context: Context) -> EscapeCatcherView {
        let view = EscapeCatcherView()
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: EscapeCatcherView, context: Context) {
        nsView.onEscape = onEscape
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    final class EscapeCatcherView: NSView {
        var onEscape: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            guard event.keyCode == 53 else {
                super.keyDown(with: event)
                return
            }

            onEscape?()
        }
    }
}
