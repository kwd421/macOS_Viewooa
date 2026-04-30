import SwiftUI

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
            size: OpenBrowserLayout.titlebarButtonSize,
            fontSize: 12.5,
            shape: Circle(),
            foregroundColor: { _ in Self.iconColor(isActive: isActive) },
            backgroundColor: { isHovering in Self.iconBackgroundColor.color(isHovering: isHovering) },
            action: action
        )
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
        VisualIconActionButton(
            accessibilityLabel: "Search",
            systemImage: "magnifyingglass",
            size: OpenBrowserLayout.titlebarControlHeight,
            fontSize: 14,
            shape: Circle(),
            foregroundColor: { _ in Color.white.opacity(hasSearchText ? 1 : 0.82) },
            backgroundColor: { isHovering in Self.backgroundColor.color(isHovering: isHovering) },
            overlay: { _ in AnyView(Circle().strokeBorder(VisualInteractionPalette.openBrowserToolbarBorder)) },
            action: action
        )
        .background(.ultraThinMaterial, in: Circle())
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
            size: 20,
            fontSize: 11,
            shape: Circle(),
            foregroundColor: { _ in .secondary },
            backgroundColor: { isHovering in Self.backgroundColor.color(isHovering: isHovering) },
            action: action
        )
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
        isVibrant ? VisualInteractionPalette.openBrowserVibrantIcon : .secondary
    }

    private static func backgroundColor(isVibrant: Bool) -> VisualHoverColorStyle {
        if isVibrant {
            return VisualInteractionPalette.vibrantToolbarHover
        }

        return VisualInteractionPalette.openBrowserPlainControlHover
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
            backgroundStyle: .ultraThinMaterial,
            borderColor: VisualInteractionPalette.openBrowserToolbarBorder,
            shadowColor: VisualInteractionPalette.openBrowserToolbarShadow,
            shadowRadius: 6,
            shadowYOffset: 2,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding
        ) {
            self
        }
    }
}
