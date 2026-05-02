import SwiftUI

struct OpenBrowserContentView: View {
    let entries: [OpenBrowserEntry]
    let searchText: String
    let displayMode: BrowserDisplayMode
    let thumbnailSize: CGFloat
    let selection: OpenBrowserSelectionState
    let favoriteFileIDs: Set<String>
    let accessErrorMessage: String?
    let isContentRevealed: Bool
    let reduceMotion: Bool
    let scrollAnchorTopOffset: CGFloat
    let onRetry: () -> Void
    let onOpenPrivacySettings: () -> Void
    let onClick: (OpenBrowserEntry) -> Void
    let onDoubleClick: (OpenBrowserEntry) -> Void
    let onShare: ([OpenBrowserEntry], OpenBrowserEntry) -> Void
    let onToggleFavorite: (OpenBrowserEntry) -> Void
    let onAddFolderFavorite: (OpenBrowserEntry) -> Void

    var body: some View {
        if let accessErrorMessage {
            accessErrorView(accessErrorMessage)
        } else if entries.isEmpty {
            ContentUnavailableView(
                searchText.isEmpty ? "No Openable Items" : "No Results",
                systemImage: "folder",
                description: Text(searchText.isEmpty ? "This folder has no supported images, PDFs, or folders." : "Try another search term.")
            )
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 360)
        } else {
            populatedContent
                .opacity(isContentRevealed || reduceMotion ? 1 : 0)
                .scaleEffect(isContentRevealed || reduceMotion ? 1 : 0.985)
                .offset(y: isContentRevealed || reduceMotion ? 0 : 12)
                .animation(revealAnimation, value: isContentRevealed)
        }
    }

    private func accessErrorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.folder")
                .font(.system(size: 38, weight: .regular))
                .symbolRenderingMode(.hierarchical)

            Text("Folder Access Needed")
                .font(.system(size: 22, weight: .semibold))

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            HStack(spacing: 10) {
                Button("Retry", action: onRetry)
                Button("Open Privacy Settings", action: onOpenPrivacySettings)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
        .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var populatedContent: some View {
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
            ForEach(entries, id: \.id) { entry in
                entryContainer(entry: entry) {
                    OpenBrowserThumbnailCell(
                        entry: entry,
                        thumbnailSize: thumbnailSize,
                        isSelected: selection.contains(entry),
                        isFavorite: favoriteFileIDs.contains(entry.id),
                        onClick: onClick,
                        onDoubleClick: onDoubleClick,
                        onShare: { requestedEntries in onShare(requestedEntries, entry) },
                        onToggleFavorite: onToggleFavorite,
                        onAddFolderFavorite: onAddFolderFavorite
                    )
                }
            }
        }
    }

    private var listView: some View {
        LazyVStack(spacing: 6) {
            ForEach(entries, id: \.id) { entry in
                entryContainer(entry: entry) {
                    OpenBrowserListRow(
                        entry: entry,
                        isSelected: selection.contains(entry),
                        isFavorite: favoriteFileIDs.contains(entry.id),
                        onClick: onClick,
                        onDoubleClick: onDoubleClick,
                        onShare: { requestedEntries in onShare(requestedEntries, entry) },
                        onToggleFavorite: onToggleFavorite,
                        onAddFolderFavorite: onAddFolderFavorite
                    )
                }
            }
        }
        .frame(maxWidth: 820)
        .frame(maxWidth: .infinity)
    }

    private func entryContainer<Content: View>(
        entry: OpenBrowserEntry,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: .top) {
            content()

            Color.clear
                .frame(width: 1, height: 1)
                .offset(y: -scrollAnchorTopOffset)
                .id(OpenBrowserScrollAnchor.id(for: entry.id))
        }
        .id(entry.id)
        .openBrowserVisibleEntryFrame(id: entry.id)
    }

    private var revealAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .smooth(duration: 0.34, extraBounce: 0.04)
    }
}
