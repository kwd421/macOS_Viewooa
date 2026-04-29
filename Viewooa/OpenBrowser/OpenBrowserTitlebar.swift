import SwiftUI

struct OpenBrowserTitlebar: View {
    let availableWidth: CGFloat
    let sidebarTotalWidth: CGFloat
    let currentFolderTitle: String
    let statusText: String
    let navigationHistory: OpenBrowserNavigationHistory
    let selectedEntries: [OpenBrowserEntry]
    let isContentRevealed: Bool
    let reduceMotion: Bool
    let collapsedSidebarLeadingInset: CGFloat
    let openBrowserGridHorizontalPadding: CGFloat
    @Binding var isSidebarVisible: Bool
    @Binding var thumbnailSize: CGFloat
    @Binding var displayMode: ImageBrowserDisplayMode
    @Binding var sortOption: OpenBrowserSortOption
    @Binding var sortAscending: Bool
    @Binding var searchText: String
    @Binding var isSearchExpanded: Bool
    @Binding var searchExpansionExtra: CGFloat
    let isSearchFieldFocused: FocusState<Bool>.Binding
    let onNavigateBack: () -> Void
    let onNavigateForward: () -> Void
    let onOpenSearch: () -> Void
    let onCloseSearch: () -> Void
    let onPrepareThumbnailResizeAnchor: () -> Void
    let onShareEntries: ([OpenBrowserEntry]) -> Void
    let onToggleFavorite: (OpenBrowserEntry) -> Void
    let onAddCurrentFolderToSidebar: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isSidebarVisible {
                sidebarHeaderGroup
                    .frame(width: sidebarTotalWidth, alignment: .trailing)

                historyToolbarGroup
            } else {
                leadingToolbarGroup
            }

            contentTitleGroup
                .layoutPriority(1)

            Spacer(minLength: 10)

            trailingToolbarGroup(availableWidth: availableWidth - sidebarTotalWidth)
        }
        .padding(.leading, isSidebarVisible ? 0 : collapsedSidebarLeadingInset)
        .padding(.trailing, 13)
        .padding(.top, 6)
        .opacity(isContentRevealed || reduceMotion ? 1 : 0)
        .offset(y: isContentRevealed || reduceMotion ? 0 : -10)
        .animation(.smooth(duration: 0.32, extraBounce: 0), value: isContentRevealed)
    }

    private var sidebarHeaderGroup: some View {
        HStack(spacing: 0) {
            OpenBrowserIconToolbarButton(
                accessibilityLabel: "Hide Sidebar",
                systemImage: "sidebar.left",
                isActive: true
            ) {
                withAnimation(.smooth(duration: 0.22, extraBounce: 0)) {
                    isSidebarVisible = false
                }
            }
        }
        .padding(1)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(Color.openBrowserSeparator.opacity(0.18))
        }
        .visualHitArea(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .padding(.trailing, 9)
    }

    private var leadingToolbarGroup: some View {
        HStack(spacing: 3) {
            OpenBrowserIconToolbarButton(
                accessibilityLabel: isSidebarVisible ? "Hide Sidebar" : "Show Sidebar",
                systemImage: "sidebar.left",
                isActive: isSidebarVisible
            ) {
                withAnimation(.smooth(duration: 0.22, extraBounce: 0)) {
                    isSidebarVisible.toggle()
                }
            }

            Divider()
                .frame(height: 22)
                .overlay(Color.openBrowserSeparator.opacity(0.42))

            historyButtons
        }
        .padding(1)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(Color.openBrowserSeparator.opacity(0.18))
        }
        .visualHitArea(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private var historyToolbarGroup: some View {
        HStack(spacing: 2) {
            historyButtons
        }
        .padding(1)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(Color.openBrowserSeparator.opacity(0.18))
        }
        .visualHitArea(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private var historyButtons: some View {
        HStack(spacing: 0) {
            OpenBrowserIconToolbarButton(accessibilityLabel: "Back", systemImage: "chevron.left", action: onNavigateBack)
                .disabled(!navigationHistory.canGoBack)
                .opacity(navigationHistory.canGoBack ? 1 : 0.35)

            OpenBrowserIconToolbarButton(accessibilityLabel: "Forward", systemImage: "chevron.right", action: onNavigateForward)
                .disabled(!navigationHistory.canGoForward)
                .opacity(navigationHistory.canGoForward ? 1 : 0.35)
        }
    }

    private var contentTitleGroup: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(currentFolderTitle)
                .font(.system(size: 18, weight: .semibold))
                .lineLimit(1)

            Text(statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.top, 3)
        .shadow(color: Color.openBrowserContentBackground.opacity(0.75), radius: 6)
    }

    private func trailingToolbarGroup(availableWidth: CGFloat) -> some View {
        let searchWidth = min(max(availableWidth * 0.34, 220), 340)

        return HStack(spacing: 8) {
            if isSearchExpanded {
                OpenBrowserToolbarCapsule {
                    OpenBrowserSearchField(
                        searchText: $searchText,
                        width: searchWidth + searchExpansionExtra,
                        isVibrant: true,
                        isFocused: isSearchFieldFocused,
                        onClose: onCloseSearch
                    )
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .scale(scale: 0.92, anchor: .trailing).combined(with: .opacity)
                ))
            } else {
                OpenBrowserToolbarCapsule {
                    ThumbnailSizeStepperControl(
                        thumbnailSize: $thumbnailSize,
                        isVibrant: true,
                        availableWidth: availableWidth - openBrowserGridHorizontalPadding * 2,
                        onWillChange: onPrepareThumbnailResizeAnchor
                    )
                }

                OpenBrowserToolbarCapsule {
                    HStack(spacing: 2) {
                        OpenBrowserViewModeControl(displayMode: $displayMode, isVibrant: true)
                        OpenBrowserSortMenu(sortOption: $sortOption, sortAscending: $sortAscending, isVibrant: true)
                        OpenBrowserActionMenu(
                            selectedEntries: selectedEntries,
                            isVibrant: true,
                            onShare: onShareEntries,
                            onFavorite: onToggleFavorite,
                            onAddCurrentFolderToSidebar: onAddCurrentFolderToSidebar
                        )
                    }
                }

                OpenBrowserSearchIconButton(hasSearchText: !searchText.isEmpty, action: onOpenSearch)
                    .transition(.scale(scale: 0.88, anchor: .trailing).combined(with: .opacity))
            }
        }
        .animation(Self.searchOpenAnimation, value: isSearchExpanded)
        .animation(Self.searchSettleAnimation, value: searchExpansionExtra)
    }

    private static let searchOpenAnimation = Animation.timingCurve(0.16, 1.0, 0.30, 1.0, duration: 0.24)
    private static let searchSettleAnimation = Animation.timingCurve(0.18, 0.92, 0.22, 1.0, duration: 0.22)
}
