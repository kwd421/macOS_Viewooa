import SwiftUI

private enum OpenBrowserIconActionStyle {
    static func toolbarIcon(isActive: Bool) -> VisualIconActionStyle {
        VisualIconActionStyle(
            size: OpenBrowserLayout.titlebarButtonSize,
            fontSize: 12.5,
            foregroundColor: { _ in isActive ? Color.openBrowserSelection : .secondary },
            backgroundColor: { isHovering in
                VisualInteractionPalette.subtleToolbarHover.color(isHovering: isHovering)
            },
            hoverEmphasis: VisualInteractionPalette.plainHoverEmphasis
        )
    }

    static func search(hasSearchText: Bool) -> VisualIconActionStyle {
        VisualIconActionStyle(
            size: OpenBrowserLayout.titlebarControlHeight,
            fontSize: 14,
            foregroundColor: { _ in Color.white.opacity(hasSearchText ? 1 : 0.82) },
            backgroundColor: { isHovering in
                VisualInteractionPalette.vibrantToolbarHover.color(isHovering: isHovering)
            },
            hoverEmphasis: VisualInteractionPalette.vibrantHoverEmphasis,
            overlay: { _ in AnyView(Circle().strokeBorder(VisualInteractionPalette.openBrowserToolbarBorder)) }
        )
    }

    static var clearSearch: VisualIconActionStyle {
        VisualIconActionStyle(
            size: 20,
            fontSize: 11,
            foregroundColor: { _ in .secondary },
            backgroundColor: { isHovering in
                VisualInteractionPalette.subtleToolbarHover.color(isHovering: isHovering)
            },
            hoverEmphasis: VisualInteractionPalette.plainHoverEmphasis
        )
    }
}

struct OpenBrowserToolbarCapsule<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            content()
        }
        .frame(height: OpenBrowserLayout.titlebarControlHeight)
        .openBrowserToolbarSurface(shape: Capsule(), horizontalPadding: 1, verticalPadding: 1)
    }
}

struct OpenBrowserIconToolbarButton: View {
    let accessibilityLabel: String
    let systemImage: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        VisualIconActionButton(
            accessibilityLabel: accessibilityLabel,
            systemImage: systemImage,
            style: OpenBrowserIconActionStyle.toolbarIcon(isActive: isActive),
            shape: Circle(),
            action: action
        )
    }
}

struct OpenBrowserSearchIconButton: View {
    let hasSearchText: Bool
    let action: () -> Void

    var body: some View {
        VisualIconActionButton(
            accessibilityLabel: "Search",
            systemImage: "magnifyingglass",
            style: OpenBrowserIconActionStyle.search(hasSearchText: hasSearchText),
            shape: Circle(),
            action: action
        )
        .background(.ultraThinMaterial, in: Circle())
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
                .foregroundStyle(isVibrant ? VisualInteractionPalette.openBrowserVibrantSearchIcon : .secondary)

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
            isVibrant ? VisualInteractionPalette.openBrowserVibrantSearchFill : Color.openBrowserControlFill,
            in: RoundedRectangle(cornerRadius: isVibrant ? 16 : 7, style: .continuous)
        )
        .visualHitArea(RoundedRectangle(cornerRadius: isVibrant ? 16 : 7, style: .continuous))
    }
}

private struct OpenBrowserClearSearchButton: View {
    let action: () -> Void

    var body: some View {
        VisualIconActionButton(
            accessibilityLabel: "Clear Search",
            systemImage: "xmark.circle.fill",
            style: OpenBrowserIconActionStyle.clearSearch,
            shape: Circle(),
            action: action
        )
    }
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
        VisualIconMenuButton(
            accessibilityLabel: accessibilityLabel,
            systemImage: systemImage,
            style: Self.style(iconFontSize: iconFontSize, isVibrant: isVibrant),
            shape: RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous),
            menuContent: menuContent
        )
    }

    private static func style(iconFontSize: CGFloat, isVibrant: Bool) -> VisualIconMenuStyle {
        VisualIconMenuStyle(
            size: CGSize(width: isVibrant ? 43 : 38, height: isVibrant ? 30 : 28),
            iconFontSize: iconFontSize,
            foregroundColor: isVibrant ? VisualInteractionPalette.openBrowserVibrantIcon : .secondary,
            backgroundColor: isVibrant ? VisualInteractionPalette.vibrantToolbarHover : VisualInteractionPalette.openBrowserPlainControlHover,
            hoverEmphasis: isVibrant ? VisualInteractionPalette.vibrantHoverEmphasis : VisualInteractionPalette.plainHoverEmphasis
        )
    }
}

struct OpenBrowserViewModeControl: View {
    @Binding var displayMode: BrowserDisplayMode
    var isVibrant = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BrowserDisplayMode.allCases) { displayModeOption in
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

    private func modeButton(for displayModeOption: BrowserDisplayMode) -> some View {
        let shape = RoundedRectangle(cornerRadius: isVibrant ? 15 : 6, style: .continuous)

        return VisualSelectableIconButton(
            accessibilityLabel: displayModeOption.title,
            systemImage: displayModeOption.systemImage,
            isSelected: displayMode == displayModeOption,
            style: Self.modeButtonStyle(isVibrant: isVibrant),
            shape: shape,
        ) {
                displayMode = displayModeOption
        }
    }

    private static func modeButtonStyle(isVibrant: Bool) -> VisualSelectableIconStyle {
        VisualSelectableIconStyle(
            size: CGSize(width: isVibrant ? 31 : 32, height: isVibrant ? 30 : 26),
            foregroundColor: { isSelected, _ in
                modeIconColor(isSelected: isSelected, isVibrant: isVibrant)
            },
            backgroundColor: { isSelected, isHovering in
                modeBackgroundColor(isVibrant: isVibrant).color(isSelected: isSelected, isHovering: isHovering)
            },
            hoverEmphasis: isVibrant ? VisualInteractionPalette.vibrantHoverEmphasis : VisualInteractionPalette.plainHoverEmphasis
        )
    }

    private static func modeIconColor(isSelected: Bool, isVibrant: Bool) -> Color {
        if isVibrant {
            return isSelected ? .white : VisualInteractionPalette.openBrowserVibrantSecondaryIcon
        }

        return isSelected ? .primary : .secondary
    }

    private static func modeBackgroundColor(isVibrant: Bool) -> VisualInteractionColorStyle {
        if isVibrant {
            return VisualInteractionPalette.vibrantSegmentBackground
        }

        return VisualInteractionPalette.openBrowserSegmentBackground
    }
}

extension View {
    func openBrowserToolbarSurface<ShapeType: InsettableShape>(
        shape: ShapeType,
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat
    ) -> some View {
        VisualToolbarSurface(
            shape: shape,
            style: OpenBrowserToolbarSurfaceStyle.toolbar(
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding
            )
        ) {
            self
        }
    }
}

private enum OpenBrowserToolbarSurfaceStyle {
    static func toolbar(horizontalPadding: CGFloat, verticalPadding: CGFloat) -> VisualToolbarSurfaceStyle<Material> {
        VisualToolbarSurfaceStyle(
            backgroundStyle: .ultraThinMaterial,
            borderColor: VisualInteractionPalette.openBrowserToolbarBorder,
            shadowColor: VisualInteractionPalette.openBrowserToolbarShadow,
            shadowRadius: 6,
            shadowYOffset: 2,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding
        )
    }
}
