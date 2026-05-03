import SwiftUI

extension OpenBrowserOverlay {
    var browserContent: some View {
        GeometryReader { proxy in
            let footerHeight = Self.footerHeight
            let sidebarTotalWidth = isSidebarVisible ? sidebarWidth + Self.sidebarHandleWidth : 0

            ZStack {
                Rectangle()
                    .fill(Color.openBrowserWindowBackground)
                    .ignoresSafeArea()

                HStack(spacing: 0) {
                    if isSidebarVisible {
                        sidebar
                            .frame(width: sidebarWidth)
                            .transition(.move(edge: .leading).combined(with: .opacity))

                        sidebarResizeHandle
                    }

                    contentPane(
                        availableWidth: proxy.size.width,
                        sidebarTotalWidth: sidebarTotalWidth
                    )
                }
                .padding(.bottom, footerHeight)

                topToolbarBackdrop
                    .frame(height: Self.contentTopInset)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .zIndex(2)

                OpenBrowserTitlebar(
                    availableWidth: proxy.size.width,
                    sidebarTotalWidth: sidebarTotalWidth,
                    currentFolderTitle: currentFolderTitle,
                    statusText: statusText,
                    navigationHistory: navigationHistory,
                    selectedEntries: selectedEntries,
                    isContentRevealed: isContentRevealed,
                    reduceMotion: reduceMotion,
                    collapsedSidebarLeadingInset: Self.collapsedSidebarLeadingInset,
                    openBrowserGridHorizontalPadding: Self.openBrowserGridHorizontalPadding,
                    isSidebarVisible: $isSidebarVisible,
                    thumbnailSize: $thumbnailSize,
                    displayMode: $displayMode,
                    sortOption: $sortOption,
                    sortAscending: $sortAscending,
                    searchText: $searchText,
                    isSearchExpanded: $isSearchExpanded,
                    searchExpansionExtra: $searchExpansionExtra,
                    isSearchFieldFocused: $isSearchFieldFocused,
                    onNavigateBack: navigateBack,
                    onNavigateForward: navigateForward,
                    onOpenSearch: openSearch,
                    onCloseSearch: closeSearch,
                    onPrepareThumbnailResizeAnchor: prepareThumbnailResizeAnchor,
                    onShareEntries: shareEntries,
                    onToggleFavorite: toggleFavorite,
                    onAddCurrentFolderToSidebar: addCurrentFolderToFavorites
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .zIndex(3)

                footerBar
                    .frame(height: footerHeight)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .zIndex(3)
            }
        }
    }

    func contentPane(availableWidth: CGFloat, sidebarTotalWidth: CGFloat) -> some View {
        GeometryReader { viewportProxy in
            ScrollViewReader { proxy in
                ZStack(alignment: .topLeading) {
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture(perform: clearSelection)

                            content
                                .allowsHitTesting(selectionDragStart == nil)
                                .background {
                                    OpenBrowserScrollViewResolver { scrollView in
                                        openBrowserScrollView = scrollView
                                    }
                                    .frame(width: 0, height: 0)
                                }
                                .padding(.horizontal, Self.contentHorizontalPadding(for: availableWidth - sidebarTotalWidth, isSidebarVisible: false))
                                .padding(.top, Self.contentTopInset)
                                .padding(.bottom, 24)
                        }
                        .frame(maxWidth: .infinity, minHeight: viewportProxy.size.height, alignment: .topLeading)
                    }
                    .coordinateSpace(name: OpenBrowserScrollCoordinateSpace.name)
                    .scrollIndicators(.hidden)
                    .simultaneousGesture(selectionDragGesture)

                    selectionDragOverlay
                }
                .onAppear {
                    scrollCoordinator.updateViewportSize(viewportProxy.size)
                }
                .onChange(of: viewportProxy.size) { _, size in
                    scrollCoordinator.updateViewportSize(size)
                }
                .onPreferenceChange(OpenBrowserVisibleEntryFramePreferenceKey.self) { frames in
                    scrollCoordinator.updateVisibleEntryFrames(frames)
                    adjustScrollForPendingThumbnailResize(with: frames)
                }
                .onChange(of: thumbnailSize) { _, _ in
                    scrollToThumbnailAnchor(with: proxy)
                }
            }
        }
        .background(Color.openBrowserContentBackground)
    }

    var topToolbarBackdrop: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Color.openBrowserWindowBackground.opacity(0.24))
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.72),
                        .init(color: .black.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .allowsHitTesting(false)
    }

    var selectionDragGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(OpenBrowserScrollCoordinateSpace.name))
            .onChanged { value in
                if selectionDragStart == nil {
                    beginSelectionDrag(at: value.startLocation, modifiers: NSEvent.modifierFlags)
                }
                updateSelectionDrag(to: value.location)
            }
            .onEnded { _ in
                endSelectionDrag()
            }
    }

    @ViewBuilder
    var selectionDragOverlay: some View {
        if let rect = currentSelectionDragRect {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.primary.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.24), lineWidth: 1)
                }
                .frame(width: rect.width, height: rect.height)
                .offset(x: rect.minX, y: rect.minY)
                .allowsHitTesting(false)
        }
    }

    var sidebarResizeHandle: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: Self.sidebarHandleWidth)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(VisualInteractionPalette.openBrowserContentDivider)
                    .frame(width: 1)
            }
            .visualHitArea(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let startWidth = sidebarDragStartWidth ?? sidebarWidth
                        sidebarDragStartWidth = startWidth
                        sidebarWidth = OpenBrowserPreferences.clampedSidebarWidth(startWidth + value.translation.width)
                    }
                    .onEnded { _ in
                        sidebarDragStartWidth = nil
                    }
            )
            .accessibilityLabel("Resize Sidebar")
    }

    var sidebar: some View {
        OpenBrowserSidebar(
            currentDirectory: currentDirectory,
            favoriteItems: sidebarStore.favoriteItems,
            locationItems: sidebarStore.locationItems,
            contentTopInset: Self.sidebarContentTopInset,
            draggingItemID: $draggingSidebarItemID,
            onNavigate: { url in navigate(to: url) },
            onAddCurrentFolder: addCurrentFolderToFavorites,
            onRemoveFavorite: removeSidebarFavorite,
            onMoveFavorite: moveFavoriteSidebarItem
        )
    }

    @ViewBuilder
    var content: some View {
        OpenBrowserContentView(
            entries: visibleEntries,
            searchText: searchText,
            displayMode: displayMode,
            thumbnailSize: thumbnailSize,
            selection: selection,
            favoriteFileIDs: favoriteFileIDs,
            accessErrorMessage: accessErrorMessage,
            isContentRevealed: isContentRevealed,
            reduceMotion: reduceMotion,
            scrollAnchorTopOffset: Self.thumbnailScrollAnchorTopOffset,
            onRetry: loadEntries,
            onOpenPrivacySettings: openPrivacySettings,
            onClick: selectEntry,
            onDoubleClick: openOrNavigate,
            onShare: shareContextEntries,
            onToggleFavorite: toggleFavorite,
            onAddFolderFavorite: addFolderToFavorites
        )
    }

    var footerBar: some View {
        OpenBrowserFooter(
            currentDirectory: currentDirectory,
            pathComponents: pathComponents,
            openButtonTitle: openButtonTitle,
            isPathEditing: $isPathEditing,
            editablePath: $editablePath,
            isPathEditorFocused: $isPathEditorFocused,
            onNavigate: { url in navigate(to: url) },
            onBeginPathEditing: beginPathEditing,
            onCommitEditedPath: commitEditedPath,
            onDismiss: onDismiss,
            onOpen: openFocusedOrFirstSelectedEntryOrCurrentFolder
        )
    }

    var visibleEntries: [OpenBrowserEntry] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return entries }

        return entries.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var statusText: String {
        if selection.isEmpty {
            return "\(visibleEntries.count) \(visibleEntries.count == 1 ? "item" : "items")"
        }

        return "\(selection.count) of \(visibleEntries.count) selected"
    }

    var currentFolderTitle: String {
        currentDirectory.lastPathComponent.isEmpty ? currentDirectory.path : currentDirectory.lastPathComponent
    }

    var selectedEntries: [OpenBrowserEntry] {
        visibleEntries.filter { selection.contains($0) }
    }

    var openButtonTitle: String {
        "Open"
    }

    var pathComponents: [OpenBrowserPathComponent] {
        OpenBrowserPathResolver.components(for: currentDirectory)
    }

    static func contentHorizontalPadding(for windowWidth: CGFloat, isSidebarVisible: Bool) -> CGFloat {
        let effectiveWidth = isSidebarVisible ? windowWidth - OpenBrowserPreferences.defaultSidebarWidth : windowWidth
        if effectiveWidth < 620 {
            return 16
        }
        if effectiveWidth < 860 {
            return 22
        }
        return 30
    }

    static let contentTopInset: CGFloat = 86
    static let sidebarContentTopInset: CGFloat = 86
    static let collapsedSidebarLeadingInset: CGFloat = 116
    static let footerHeight: CGFloat = 42
    static let sidebarHandleWidth: CGFloat = 12
    static let openBrowserGridHorizontalPadding: CGFloat = 30
    static let thumbnailScrollAnchorTopOffset: CGFloat = contentTopInset - 6
    static let searchExpansionOvershoot: CGFloat = 24
    static let searchOvershootDuration: TimeInterval = 0.16
    static let searchOpenAnimation = Animation.timingCurve(0.16, 1.0, 0.30, 1.0, duration: 0.24)
    static let searchSettleAnimation = Animation.timingCurve(0.18, 0.92, 0.22, 1.0, duration: 0.22)
    static let searchCloseAnimation = Animation.timingCurve(0.18, 0.88, 0.20, 1.0, duration: 0.24)
}

extension OpenBrowserOverlay {
    var currentSelectionDragRect: CGRect? {
        guard let selectionDragStart, let selectionDragCurrent else { return nil }
        return CGRect(
            x: min(selectionDragStart.x, selectionDragCurrent.x),
            y: min(selectionDragStart.y, selectionDragCurrent.y),
            width: abs(selectionDragStart.x - selectionDragCurrent.x),
            height: abs(selectionDragStart.y - selectionDragCurrent.y)
        )
    }
}
