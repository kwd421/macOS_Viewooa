import SwiftUI
import AppKit

struct OpenBrowserThumbnailCell: View {
    let entry: OpenBrowserEntry
    let thumbnailSize: CGFloat
    let isSelected: Bool
    let isFavorite: Bool
    let onClick: (OpenBrowserEntry) -> Void
    let onDoubleClick: (OpenBrowserEntry) -> Void
    let onShare: ([OpenBrowserEntry]) -> Void
    let onToggleFavorite: (OpenBrowserEntry) -> Void
    let onAddFolderFavorite: (OpenBrowserEntry) -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)

        VisualSelectableContentButton(
            accessibilityLabel: entry.name,
            isSelected: isSelected,
            shape: shape,
            style: Self.thumbnailStyle
        ) {
            onClick(entry)
        } label: { _ in
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
        }
        .frame(width: thumbnailSize + 16, height: thumbnailSize * 0.72 + 57)
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
    }

    private static let thumbnailStyle = VisualSelectableContentStyle(
        backgroundColor: VisualInteractionPalette.openBrowserThumbnailBackground,
        borderColor: VisualInteractionPalette.openBrowserThumbnailBorder
    )

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
    let isSelected: Bool
    let isFavorite: Bool
    let onClick: (OpenBrowserEntry) -> Void
    let onDoubleClick: (OpenBrowserEntry) -> Void
    let onShare: ([OpenBrowserEntry]) -> Void
    let onToggleFavorite: (OpenBrowserEntry) -> Void
    let onAddFolderFavorite: (OpenBrowserEntry) -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)

        VisualSelectableContentButton(
            accessibilityLabel: entry.name,
            isSelected: isSelected,
            shape: shape,
            style: Self.listStyle
        ) {
            onClick(entry)
        } label: { _ in
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
        }
        .visualHitArea(shape)
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
    }

    private static let listStyle = VisualSelectableContentStyle(
        backgroundColor: VisualInteractionPalette.openBrowserListBackground,
        borderColor: VisualInteractionPalette.openBrowserListBorder
    )

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
                        .strokeBorder(VisualInteractionPalette.openBrowserStrongDivider)
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

                BrowserThumbnail(url: entry.url, targetPixelSize: targetPixelSize)
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
