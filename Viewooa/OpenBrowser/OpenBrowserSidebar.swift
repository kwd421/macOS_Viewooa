import SwiftUI
import UniformTypeIdentifiers

struct OpenBrowserSidebar: View {
    let currentDirectory: URL
    let favoriteItems: [OpenBrowserSidebarItem]
    let locationItems: [OpenBrowserSidebarItem]
    let contentTopInset: CGFloat
    @Binding var draggingItemID: String?
    let onNavigate: (URL) -> Void
    let onAddCurrentFolder: () -> Void
    let onRemoveFavorite: (OpenBrowserSidebarItem) -> Void
    let onMoveFavorite: (String, String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                favoriteSection
                sidebarSection("Locations", items: locationItems)
                addCurrentFolderButton
            }
            .padding(.horizontal, 10)
            .padding(.top, contentTopInset)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
        .background(Color.openBrowserSidebarBackground)
    }

    private var favoriteSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle("FAVORITES")

            ForEach(favoriteItems) { item in
                sidebarRow(item, allowsRemoval: true)
                    .onDrag {
                        draggingItemID = item.id
                        return NSItemProvider(object: item.id as NSString)
                    }
                    .onDrop(
                        of: [UTType.plainText],
                        delegate: OpenBrowserSidebarDropDelegate(
                            targetItem: item,
                            items: favoriteItems,
                            draggingItemID: $draggingItemID,
                            onMove: onMoveFavorite
                        )
                    )
            }
        }
    }

    private func sidebarSection(_ title: String, items: [OpenBrowserSidebarItem]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionTitle(title.uppercased())

            ForEach(items) { item in
                sidebarRow(item, allowsRemoval: false)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
    }

    private var addCurrentFolderButton: some View {
        VisualHoverContentButton(
            accessibilityLabel: "Add Current Folder",
            shape: RoundedRectangle(cornerRadius: 6, style: .continuous),
            style: Self.addButtonStyle
        ) {
            onAddCurrentFolder()
        } label: { _ in
            Label("Add Current Folder", systemImage: "plus")
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .frame(height: 26)
        }
        .foregroundStyle(.secondary)
    }

    private func sidebarRow(_ item: OpenBrowserSidebarItem, allowsRemoval: Bool) -> some View {
        let isSelected = item.url.standardizedFileURL == currentDirectory.standardizedFileURL

        return VisualSelectableContentButton(
            accessibilityLabel: item.title,
            isSelected: isSelected,
            shape: RoundedRectangle(cornerRadius: 6, style: .continuous),
            style: Self.sidebarRowStyle
        ) {
            onNavigate(item.url)
        } label: { _ in
            HStack(spacing: 9) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 13, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 18, alignment: .center)
                    .foregroundStyle(isSelected ? Color.openBrowserSelection : .secondary)

                Text(item.title)
                    .font(.system(size: 12, weight: .regular))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .foregroundStyle(isSelected ? Color.openBrowserSelection : .primary)
        }
        .contextMenu {
            if allowsRemoval {
                Button("Remove from Sidebar") {
                    onRemoveFavorite(item)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(.isButton)
    }

    private static let addButtonStyle = VisualHoverContentStyle(
        backgroundColor: VisualInteractionPalette.subtleToolbarHover
    )

    private static let sidebarRowStyle = VisualSelectableContentStyle(
        backgroundColor: VisualInteractionPalette.openBrowserSidebarRowBackground
    )
}
