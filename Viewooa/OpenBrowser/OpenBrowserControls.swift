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
        .visualHitArea(Capsule())
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
            OpenBrowserIconToolbarSurface(systemImage: systemImage, isActive: isActive)
        }
        .frame(width: OpenBrowserLayout.titlebarButtonSize, height: OpenBrowserLayout.titlebarButtonSize)
        .buttonStyle(.plain)
        .visualHitArea(Circle())
        .accessibilityLabel(accessibilityLabel)
    }
}

struct OpenBrowserIconToolbarSurface: View {
    let systemImage: String
    var isActive = false

    var body: some View {
        VisualHoverState(shape: Circle()) { isHovering in
            VisualIconButtonLabel(
                systemImage: systemImage,
                size: OpenBrowserLayout.titlebarButtonSize,
                fontSize: 12.5,
                foregroundColor: Self.iconColor(isActive: isActive),
                backgroundColor: Self.iconBackgroundColor.color(isHovering: isHovering)
            )
        }
        .frame(width: OpenBrowserLayout.titlebarButtonSize, height: OpenBrowserLayout.titlebarButtonSize)
    }

    private static func iconColor(isActive: Bool) -> Color {
        isActive ? Color.openBrowserSelection : .secondary
    }

    private static let iconBackgroundColor = VisualInteractionPalette.subtleToolbarHover
}

struct OpenBrowserSearchIconButton: View {
    let hasSearchText: Bool
    let action: () -> Void

    var body: some View {
        VisualHoverState(shape: Circle()) { isHovering in
            Button(action: action) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(hasSearchText ? 1 : 0.82))
                    .frame(width: OpenBrowserLayout.titlebarControlHeight, height: OpenBrowserLayout.titlebarControlHeight)
                    .background(.ultraThinMaterial, in: Circle())
                    .background(Self.backgroundColor.color(isHovering: isHovering), in: Circle())
                    .overlay {
                        Circle().strokeBorder(Color.openBrowserSeparator.opacity(0.18))
                    }
                    .visualHitArea(Circle())
            }
            .frame(width: OpenBrowserLayout.titlebarControlHeight, height: OpenBrowserLayout.titlebarControlHeight)
            .visualHitArea(Circle())
            .buttonStyle(.plain)
            .accessibilityLabel("Search")
        }
        .frame(width: OpenBrowserLayout.titlebarControlHeight, height: OpenBrowserLayout.titlebarControlHeight)
    }

    private static let backgroundColor = VisualInteractionPalette.vibrantToolbarHover
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
                OpenBrowserClearSearchButton {
                    searchText = ""
                    onClose?()
                }
            }
        }
        .padding(.horizontal, 9)
        .frame(height: isVibrant ? 32 : 28)
        .background(
            isVibrant ? Color.white.opacity(0.08) : Color.openBrowserControlFill,
            in: RoundedRectangle(cornerRadius: isVibrant ? 16 : 7, style: .continuous)
        )
        .visualHitArea(RoundedRectangle(cornerRadius: isVibrant ? 16 : 7, style: .continuous))
    }
}

private struct OpenBrowserClearSearchButton: View {
    let action: () -> Void

    var body: some View {
        VisualHoverState(shape: Circle()) { isHovering in
            Button(action: action) {
                VisualIconButtonLabel(
                    systemImage: "xmark.circle.fill",
                    size: 20,
                    fontSize: 11,
                    foregroundColor: .secondary,
                    backgroundColor: Self.backgroundColor.color(isHovering: isHovering)
                )
            }
            .frame(width: 20, height: 20)
            .visualHitArea(Circle())
            .buttonStyle(.plain)
            .accessibilityLabel("Clear Search")
        }
        .frame(width: 20, height: 20)
    }

    private static let backgroundColor = VisualInteractionPalette.subtleToolbarHover
}

struct OpenBrowserSortMenu: View {
    @Binding var sortOption: OpenBrowserSortOption
    @Binding var sortAscending: Bool
    var isVibrant = false

    var body: some View {
        OpenBrowserToolbarIconMenu(
            accessibilityLabel: "Sort",
            systemImage: "arrow.up.arrow.down",
            iconFontSize: 13,
            isVibrant: isVibrant
        ) {
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
        }
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
        OpenBrowserToolbarIconMenu(
            accessibilityLabel: "Actions",
            systemImage: "ellipsis.circle",
            iconFontSize: 14,
            isVibrant: isVibrant
        ) {
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
        }
    }
}

private struct OpenBrowserToolbarIconMenu<MenuContent: View>: View {
    let accessibilityLabel: String
    let systemImage: String
    let iconFontSize: CGFloat
    let isVibrant: Bool
    @ViewBuilder let menuContent: () -> MenuContent

    var body: some View {
        let size = Self.controlSize(isVibrant: isVibrant)

        let shape = RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous)

        VisualHoverState(shape: shape) { isHovering in
            Menu {
                menuContent()
            } label: {
                Image(systemName: systemImage)
                    .font(.system(size: iconFontSize, weight: .semibold))
                    .foregroundStyle(Self.iconColor(isVibrant: isVibrant))
                    .frame(width: size.width, height: size.height)
                    .background(
                        Self.backgroundColor(isVibrant: isVibrant).color(isHovering: isHovering),
                        in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                    )
                    .visualHitArea(shape)
            }
            .frame(width: size.width, height: size.height)
            .visualHitArea(shape)
            .menuStyle(.borderlessButton)
            .accessibilityLabel(accessibilityLabel)
        }
        .frame(width: size.width, height: size.height)
    }

    private static func controlSize(isVibrant: Bool) -> CGSize {
        CGSize(width: isVibrant ? 31 : 28, height: isVibrant ? 30 : 28)
    }

    private static func iconColor(isVibrant: Bool) -> Color {
        isVibrant ? Color.white.opacity(0.82) : .secondary
    }

    private static func backgroundColor(isVibrant: Bool) -> VisualHoverColorStyle {
        if isVibrant {
            return VisualInteractionPalette.vibrantToolbarHover
        }

        return VisualHoverColorStyle(
            normal: Color.openBrowserControlFill,
            hover: Color.openBrowserControlFill.opacity(1.25)
        )
    }
}

struct OpenBrowserViewModeControl: View {
    @Binding var displayMode: ImageBrowserDisplayMode
    var isVibrant = false
    @State private var hoveredDisplayMode: ImageBrowserDisplayMode?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImageBrowserDisplayMode.allCases) { displayModeOption in
                modeButton(for: displayModeOption)
            }
        }
        .padding(isVibrant ? 0 : 2)
        .background(
            isVibrant ? Color.clear : Color.openBrowserControlFill,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .visualHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func modeButton(for displayModeOption: ImageBrowserDisplayMode) -> some View {
        let size = Self.modeButtonSize(isVibrant: isVibrant)

        let shape = RoundedRectangle(cornerRadius: isVibrant ? 15 : 6, style: .continuous)

        return VisualHoveredSelection(id: displayModeOption, hoveredID: $hoveredDisplayMode, shape: shape) { isHovering in
            Button {
                displayMode = displayModeOption
            } label: {
                Image(systemName: displayModeOption.systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: size.width, height: size.height)
                    .foregroundStyle(Self.modeIconColor(isSelected: displayMode == displayModeOption, isVibrant: isVibrant))
                    .background(
                        Self.modeBackgroundColor(isVibrant: isVibrant)
                            .color(isSelected: displayMode == displayModeOption, isHovering: isHovering),
                        in: RoundedRectangle(cornerRadius: isVibrant ? 15 : 6, style: .continuous)
                    )
                    .visualHitArea(shape)
            }
            .frame(width: size.width, height: size.height)
            .visualHitArea(shape)
            .buttonStyle(.plain)
            .accessibilityLabel(displayModeOption.title)
        }
    }

    private static func modeButtonSize(isVibrant: Bool) -> CGSize {
        CGSize(width: isVibrant ? 31 : 32, height: isVibrant ? 30 : 26)
    }

    private static func modeIconColor(isSelected: Bool, isVibrant: Bool) -> Color {
        if isVibrant {
            return isSelected ? .white : Color.white.opacity(0.62)
        }

        return isSelected ? .primary : .secondary
    }

    private static func modeBackgroundColor(isVibrant: Bool) -> VisualInteractionColorStyle {
        if isVibrant {
            return VisualInteractionPalette.vibrantSegmentBackground
        }

        return VisualInteractionColorStyle(
            normal: .clear,
            hover: Color.primary.opacity(0.07),
            selected: Color(nsColor: .selectedControlColor).opacity(0.22),
            selectedHover: Color(nsColor: .selectedControlColor).opacity(0.30)
        )
    }
}
