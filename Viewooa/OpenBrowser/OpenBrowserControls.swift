import SwiftUI

struct OpenBrowserToolbarCapsule<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            content()
        }
        .padding(1)
        .frame(height: OpenBrowserLayout.titlebarControlHeight)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule().strokeBorder(Color.openBrowserSeparator.opacity(0.18))
        }
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

struct OpenBrowserIconToolbarButton: View {
    let accessibilityLabel: String
    let systemImage: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12.5, weight: .semibold))
                .frame(width: OpenBrowserLayout.titlebarButtonSize, height: OpenBrowserLayout.titlebarButtonSize)
                .foregroundStyle(isActive ? Color.openBrowserSelection : .secondary)
                .contentShape(RoundedRectangle(cornerRadius: OpenBrowserLayout.titlebarButtonSize / 2, style: .continuous))
        }
        .frame(width: OpenBrowserLayout.titlebarButtonSize, height: OpenBrowserLayout.titlebarButtonSize)
        .contentShape(RoundedRectangle(cornerRadius: OpenBrowserLayout.titlebarButtonSize / 2, style: .continuous))
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct OpenBrowserSearchIconButton: View {
    let hasSearchText: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white.opacity(hasSearchText ? 1 : 0.82))
                .frame(width: OpenBrowserLayout.titlebarControlHeight, height: OpenBrowserLayout.titlebarControlHeight)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(Color.openBrowserSeparator.opacity(0.18))
                }
                .contentShape(Circle())
        }
        .frame(width: OpenBrowserLayout.titlebarControlHeight, height: OpenBrowserLayout.titlebarControlHeight)
        .contentShape(Circle())
        .buttonStyle(.plain)
        .accessibilityLabel("Search")
    }
}

struct OpenBrowserSearchField: View {
    @Binding var searchText: String
    let width: CGFloat
    var isVibrant = false
    let isFocused: FocusState<Bool>.Binding
    let onClose: (() -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isVibrant ? Color.white.opacity(0.76) : .secondary)

            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .frame(width: width)
                .focused(isFocused)

            if !searchText.isEmpty || onClose != nil {
                Button {
                    searchText = ""
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear Search")
            }
        }
        .padding(.horizontal, 9)
        .frame(height: isVibrant ? 32 : 28)
        .background(
            isVibrant ? Color.white.opacity(0.08) : Color.openBrowserControlFill,
            in: RoundedRectangle(cornerRadius: isVibrant ? 16 : 7, style: .continuous)
        )
    }
}

struct OpenBrowserSortMenu: View {
    @Binding var sortOption: OpenBrowserSortOption
    @Binding var sortAscending: Bool
    var isVibrant = false

    var body: some View {
        Menu {
            ForEach(OpenBrowserSortOption.allCases) { option in
                Button {
                    sortOption = option
                } label: {
                    Label(option.title, systemImage: sortOption == option ? "checkmark" : "")
                }
            }

            Divider()

            Button {
                sortAscending.toggle()
            } label: {
                Label(sortAscending ? "Ascending" : "Descending", systemImage: sortAscending ? "arrow.up" : "arrow.down")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isVibrant ? Color.white.opacity(0.82) : .secondary)
                .frame(width: isVibrant ? 31 : 28, height: isVibrant ? 30 : 28)
                .background(
                    isVibrant ? Color.clear : Color.openBrowserControlFill,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous))
        }
        .frame(width: isVibrant ? 31 : 28, height: isVibrant ? 30 : 28)
        .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous))
        .menuStyle(.borderlessButton)
        .accessibilityLabel("Sort")
    }
}

struct OpenBrowserActionMenu: View {
    let selectedEntries: [OpenBrowserEntry]
    var isVibrant = false
    let onShare: ([OpenBrowserEntry]) -> Void
    let onFavorite: (OpenBrowserEntry) -> Void
    let onAddCurrentFolderToSidebar: () -> Void

    private var selectedFiles: [OpenBrowserEntry] {
        selectedEntries.filter { !$0.isDirectory }
    }

    var body: some View {
        Menu {
            Button("Share...") {
                onShare(selectedFiles)
            }
            .disabled(selectedFiles.isEmpty)

            Button("Favorite") {
                selectedFiles.forEach(onFavorite)
            }
            .disabled(selectedFiles.isEmpty)

            Divider()

            Button("Add Current Folder to Sidebar", action: onAddCurrentFolderToSidebar)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isVibrant ? Color.white.opacity(0.82) : .secondary)
                .frame(width: isVibrant ? 31 : 28, height: isVibrant ? 30 : 28)
                .background(
                    isVibrant ? Color.clear : Color.openBrowserControlFill,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous))
        }
        .frame(width: isVibrant ? 31 : 28, height: isVibrant ? 30 : 28)
        .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous))
        .menuStyle(.borderlessButton)
        .accessibilityLabel("Actions")
    }
}

struct OpenBrowserViewModeControl: View {
    @Binding var displayMode: ImageBrowserDisplayMode
    var isVibrant = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImageBrowserDisplayMode.allCases) { mode in
                Button {
                    displayMode = mode
                } label: {
                    Image(systemName: mode.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: isVibrant ? 31 : 32, height: isVibrant ? 30 : 26)
                        .foregroundStyle(viewModeForeground(for: mode))
                        .background(
                            viewModeBackground(for: mode),
                            in: RoundedRectangle(cornerRadius: isVibrant ? 15 : 6, style: .continuous)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 6, style: .continuous))
                }
                .frame(width: isVibrant ? 31 : 32, height: isVibrant ? 30 : 26)
                .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 6, style: .continuous))
                .buttonStyle(.plain)
                .accessibilityLabel(mode.title)
            }
        }
        .padding(isVibrant ? 0 : 2)
        .background(
            isVibrant ? Color.clear : Color.openBrowserControlFill,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func viewModeForeground(for mode: ImageBrowserDisplayMode) -> Color {
        if isVibrant {
            return displayMode == mode ? .white : Color.white.opacity(0.62)
        }

        return displayMode == mode ? .primary : .secondary
    }

    private func viewModeBackground(for mode: ImageBrowserDisplayMode) -> Color {
        if isVibrant {
            return displayMode == mode ? Color.white.opacity(0.16) : .clear
        }

        return displayMode == mode ? Color(nsColor: .selectedControlColor).opacity(0.22) : .clear
    }
}
