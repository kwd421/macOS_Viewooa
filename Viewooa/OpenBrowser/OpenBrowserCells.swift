import SwiftUI
import AppKit

struct OpenBrowserThumbnailCell: View {
    let entry: OpenBrowserEntry
    let index: Int
    let thumbnailSize: CGFloat
    let isSelected: Bool
    let isFavorite: Bool
    let isRevealed: Bool
    let reduceMotion: Bool
    let onClick: (OpenBrowserEntry) -> Void
    let onDoubleClick: (OpenBrowserEntry) -> Void
    let onShare: ([OpenBrowserEntry]) -> Void
    let onToggleFavorite: (OpenBrowserEntry) -> Void
    let onAddFolderFavorite: (OpenBrowserEntry) -> Void

    var body: some View {
        Button {
            onClick(entry)
        } label: {
            VStack(spacing: 9) {
                thumbnailPreview

                Text(entry.name)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .frame(width: thumbnailSize, height: 28, alignment: .top)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(width: thumbnailSize + 16, height: thumbnailSize * 0.72 + 57, alignment: .top)
            .background(isSelected ? Color.openBrowserSelection.opacity(0.07) : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Color.openBrowserSelection.opacity(0.46) : .clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.name)
        .simultaneousGesture(TapGesture(count: 2).onEnded {
            onDoubleClick(entry)
        })
        .contextMenu {
            Button(entry.isDirectory ? "Open Folder" : "Open") {
                onDoubleClick(entry)
            }

            Button("Share...") {
                onShare([entry])
            }
            .disabled(entry.isDirectory)

            if entry.isDirectory {
                Button("Add to Sidebar") {
                    onAddFolderFavorite(entry)
                }
            } else {
                Button(isFavorite ? "Remove Favorite" : "Favorite") {
                    onToggleFavorite(entry)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if isFavorite && !entry.isDirectory {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red)
                    .padding(6)
            }
        }
        .opacity(isRevealed || reduceMotion ? 1 : 0)
        .scaleEffect(isRevealed || reduceMotion ? 1 : 0.965)
        .offset(y: isRevealed || reduceMotion ? 0 : 18)
        .animation(revealAnimation, value: isRevealed)
    }

    private var revealAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .smooth(duration: 0.46, extraBounce: 0.08)
            .delay(min(Double(index % 24) * 0.018, 0.26))
    }

    @ViewBuilder
    private var thumbnailPreview: some View {
        if entry.isDirectory {
            OpenBrowserItemPreview(entry: entry, targetPixelSize: max(thumbnailSize * 1.6, 160))
                .frame(width: thumbnailSize, height: thumbnailSize * 0.58)
                .shadow(color: .black.opacity(0.16), radius: 9, y: 5)
        } else {
            OpenBrowserItemPreview(entry: entry, targetPixelSize: max(thumbnailSize * 1.6, 160))
                .frame(width: thumbnailSize, height: thumbnailSize * 0.72)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(.separator.opacity(0.55))
                }
                .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
        }
    }
}

struct OpenBrowserListRow: View {
    let entry: OpenBrowserEntry
    let index: Int
    let isSelected: Bool
    let isFavorite: Bool
    let isRevealed: Bool
    let reduceMotion: Bool
    let onClick: (OpenBrowserEntry) -> Void
    let onDoubleClick: (OpenBrowserEntry) -> Void
    let onShare: ([OpenBrowserEntry]) -> Void
    let onToggleFavorite: (OpenBrowserEntry) -> Void
    let onAddFolderFavorite: (OpenBrowserEntry) -> Void

    var body: some View {
        Button {
            onClick(entry)
        } label: {
            HStack(spacing: 12) {
                listPreview

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.system(size: 13, weight: .regular))
                        .lineLimit(1)
                    Text(entry.isDirectory ? "Folder" : entry.url.pathExtension.uppercased())
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isFavorite && !entry.isDirectory {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 9)
            .frame(height: 40)
            .background(isSelected ? Color.openBrowserSelection.opacity(0.16) : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.openBrowserSelection.opacity(0.24) : .clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.name)
        .simultaneousGesture(TapGesture(count: 2).onEnded {
            onDoubleClick(entry)
        })
        .contextMenu {
            Button(entry.isDirectory ? "Open Folder" : "Open") {
                onDoubleClick(entry)
            }

            Button("Share...") {
                onShare([entry])
            }
            .disabled(entry.isDirectory)

            if entry.isDirectory {
                Button("Add to Sidebar") {
                    onAddFolderFavorite(entry)
                }
            } else {
                Button(isFavorite ? "Remove Favorite" : "Favorite") {
                    onToggleFavorite(entry)
                }
            }
        }
        .opacity(isRevealed || reduceMotion ? 1 : 0)
        .scaleEffect(isRevealed || reduceMotion ? 1 : 0.985)
        .offset(y: isRevealed || reduceMotion ? 0 : 12)
        .animation(revealAnimation, value: isRevealed)
    }

    private var revealAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .smooth(duration: 0.38, extraBounce: 0.04)
            .delay(min(Double(index % 18) * 0.015, 0.2))
    }

    @ViewBuilder
    private var listPreview: some View {
        if entry.isDirectory {
            OpenBrowserItemPreview(entry: entry, targetPixelSize: 96)
                .frame(width: 44, height: 32)
        } else {
            OpenBrowserItemPreview(entry: entry, targetPixelSize: 96)
                .frame(width: 44, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(Color.openBrowserSeparator.opacity(0.65))
                }
        }
    }
}

struct OpenBrowserItemPreview: View {
    let entry: OpenBrowserEntry
    let targetPixelSize: CGFloat

    var body: some View {
        ZStack {
            if entry.isDirectory {
                OpenBrowserFolderPreview(url: entry.url)
            } else if SupportedImageTypes.isPDF(entry.url) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.openBrowserControlFill)

                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 34, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            } else {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.openBrowserControlFill)

                ImageBrowserThumbnail(url: entry.url, targetPixelSize: targetPixelSize)
            }
        }
    }
}

struct OpenBrowserFolderPreview: View {
    let url: URL

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .scaledToFit()
            .padding(.horizontal, 2)
    }
}
