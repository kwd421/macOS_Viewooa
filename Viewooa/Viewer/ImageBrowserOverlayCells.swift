import SwiftUI

struct ImageBrowserThumbnailCell: View {
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

struct ImageBrowserListRow: View {
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
