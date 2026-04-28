import SwiftUI
import AppKit

struct OpenBrowserOverlay: View {
    let initialDirectory: URL
    @Binding var displayMode: ImageBrowserDisplayMode
    @Binding var thumbnailSize: CGFloat
    let onOpen: (URL) -> Void
    let onDismiss: () -> Void
    private let preferences: OpenBrowserPreferences

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentDirectory: URL
    @State private var entries: [OpenBrowserEntry] = []
    @State private var searchText = ""
    @State private var sortOption = OpenBrowserSortOption.name
    @State private var sortAscending = true
    @State private var selection = OpenBrowserSelectionState()
    @State private var favoriteFileIDs: Set<String> = []
    @State private var sidebarStore = OpenBrowserSidebarStore()
    @State private var draggingSidebarItemID: String?
    @State private var accessErrorMessage: String?
    @State private var isSidebarVisible = true
    @State private var sidebarWidth: CGFloat = OpenBrowserPreferences.defaultSidebarWidth
    @State private var sidebarDragStartWidth: CGFloat?
    @State private var isContentRevealed = false
    @State private var navigationHistory = OpenBrowserNavigationHistory()
    @State private var isSearchExpanded = false
    @State private var searchExpansionExtra: CGFloat = 0
    @State private var scrollCoordinator = OpenBrowserScrollCoordinator()
    @State private var openBrowserScrollView: NSScrollView?
    @State private var isPathEditing = false
    @State private var editablePath = ""
    @FocusState private var isPathEditorFocused: Bool
    @FocusState private var isSearchFieldFocused: Bool

    init(
        initialDirectory: URL,
        displayMode: Binding<ImageBrowserDisplayMode>,
        thumbnailSize: Binding<CGFloat>,
        onOpen: @escaping (URL) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.initialDirectory = initialDirectory
        self._displayMode = displayMode
        self._thumbnailSize = thumbnailSize
        self.onOpen = onOpen
        self.onDismiss = onDismiss
        let preferences = OpenBrowserPreferences()
        self.preferences = preferences
        let savedDirectory = preferences.recentDirectoryURL ?? initialDirectory
        self._currentDirectory = State(initialValue: OpenBrowserDataSource.validDirectory(savedDirectory) ?? initialDirectory)
        self._isSidebarVisible = State(initialValue: preferences.sidebarVisible)
        self._sidebarWidth = State(initialValue: preferences.initialSidebarWidth)
        self._sortOption = State(initialValue: preferences.sortOption)
        self._sortAscending = State(initialValue: preferences.sortAscending)
        self._favoriteFileIDs = State(initialValue: preferences.favoriteFileIDs)
        self._sidebarStore = State(initialValue: preferences.sidebarStore())
    }

    var body: some View {
        AnyView(browserContent.foregroundStyle(.primary))
            .ignoresSafeArea(.container, edges: .top)
            .onAppear(perform: handleAppear)
            .onChange(of: currentDirectory) { _, _ in handleDirectoryChange() }
            .onChange(of: searchText) { _, value in handleSearchChange(value) }
            .onChange(of: sortOption) { _, value in handleSortOptionChange(value) }
            .onChange(of: sortAscending) { _, value in handleSortAscendingChange(value) }
            .onChange(of: isSidebarVisible) { _, value in handleSidebarVisibilityChange(value) }
            .onChange(of: sidebarWidth) { _, value in handleSidebarWidthChange(value) }
            .onChange(of: thumbnailSize) { _, value in handleThumbnailSizeChange(value) }
            .onChange(of: displayMode) { _, value in handleDisplayModeChange(value) }
            .onChange(of: isSearchExpanded) { _, value in handleSearchExpansionChange(value) }
            .onChange(of: isSearchFieldFocused) { _, value in handleSearchFocusChange(value) }
            .overlay {
                OpenBrowserKeyboardCatcher(
                    onEscape: handleEscape,
                    onSelectAll: selectAllVisibleEntries,
                    onOpen: openFocusedOrFirstSelectedEntry,
                    onParent: navigateToParent
                )
                    .frame(width: 0, height: 0)
            }
            .onExitCommand(perform: handleEscape)
            .accessibilityLabel("Open Browser")
    }

    private var browserContent: some View {
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

    private func contentPane(availableWidth: CGFloat, sidebarTotalWidth: CGFloat) -> some View {
        GeometryReader { viewportProxy in
            ScrollViewReader { proxy in
                ScrollView {
                    content
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
                .coordinateSpace(name: OpenBrowserScrollCoordinateSpace.name)
                .scrollIndicators(.hidden)
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

    private var sidebarResizeHandle: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: Self.sidebarHandleWidth)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.openBrowserSeparator.opacity(0.55))
                    .frame(width: 1)
            }
            .contentShape(Rectangle())
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

    private func handleAppear() {
        restoreBrowserPreferences()
        loadEntries()
        revealContent()
    }

    private func restoreBrowserPreferences() {
        if let savedDisplayMode = preferences.displayMode {
            displayMode = savedDisplayMode
        }

        if let savedThumbnailSize = preferences.thumbnailSize {
            thumbnailSize = savedThumbnailSize
        }
    }

    private func handleDirectoryChange() {
        searchText = ""
        loadEntries()
        selection.clear()
        preferences.saveRecentDirectory(currentDirectory)
        revealContent()
    }

    private func handleSearchChange(_ value: String) {
        trimSelectionToVisibleEntries()
    }

    private func handleSearchExpansionChange(_ value: Bool) {
        guard value else {
            isSearchFieldFocused = false
            return
        }

        DispatchQueue.main.async {
            isSearchFieldFocused = true
        }
    }

    private func handleSearchFocusChange(_ value: Bool) {
        guard !value, searchText.isEmpty, isSearchExpanded else { return }
        closeSearch()
    }

    private func openSearch() {
        guard !isSearchExpanded else { return }

        searchExpansionExtra = Self.searchExpansionOvershoot
        withAnimation(Self.searchOpenAnimation) {
            isSearchExpanded = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.searchOvershootDuration) {
            guard isSearchExpanded else { return }
            withAnimation(Self.searchSettleAnimation) {
                searchExpansionExtra = 0
            }
        }
    }

    private func closeSearch() {
        withAnimation(Self.searchCloseAnimation) {
            searchExpansionExtra = 0
            isSearchExpanded = false
        }
    }

    private func handleEscape() {
        if isSearchExpanded || !searchText.isEmpty {
            searchText = ""
            closeSearch()
            return
        }

        if isPathEditing {
            isPathEditing = false
            editablePath = currentDirectory.path
            return
        }

        onDismiss()
    }

    private func handleSortOptionChange(_ value: OpenBrowserSortOption) {
        preferences.saveSortOption(value)
        loadEntries()
    }

    private func handleSortAscendingChange(_ value: Bool) {
        preferences.saveSortAscending(value)
        loadEntries()
    }

    private func handleSidebarVisibilityChange(_ value: Bool) {
        preferences.saveSidebarVisible(value)
    }

    private func handleSidebarWidthChange(_ value: CGFloat) {
        preferences.saveSidebarWidth(value)
    }

    private func handleThumbnailSizeChange(_ value: CGFloat) {
        preferences.saveThumbnailSize(value)
    }

    private func handleDisplayModeChange(_ value: ImageBrowserDisplayMode) {
        preferences.saveDisplayMode(value)
    }

    private var sidebar: some View {
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
    private var content: some View {
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

    private var visibleEntries: [OpenBrowserEntry] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return entries }

        return entries.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    private var footerBar: some View {
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

    private var statusText: String {
        if selection.isEmpty {
            return "\(visibleEntries.count) \(visibleEntries.count == 1 ? "item" : "items")"
        }

        return "\(selection.count) of \(visibleEntries.count) selected"
    }

    private var currentFolderTitle: String {
        currentDirectory.lastPathComponent.isEmpty ? currentDirectory.path : currentDirectory.lastPathComponent
    }

    private var selectedEntries: [OpenBrowserEntry] {
        visibleEntries.filter { selection.contains($0) }
    }

    private var openButtonTitle: String {
        "Open"
    }

    private var pathComponents: [OpenBrowserPathComponent] {
        OpenBrowserPathResolver.components(for: currentDirectory)
    }

    private func openOrNavigate(_ entry: OpenBrowserEntry) {
        if entry.isDirectory {
            navigate(to: entry.url)
        } else {
            onOpen(entry.url)
        }
    }

    private func selectEntry(_ entry: OpenBrowserEntry) {
        selection.select(entry, visibleEntries: visibleEntries, modifiers: NSEvent.modifierFlags)
    }

    private func selectAllVisibleEntries() {
        selection.selectAll(visibleEntries)
    }

    private func openFocusedOrFirstSelectedEntry() {
        guard let entry = visibleEntries.first(where: { $0.id == selection.focusedEntryID }) ?? selectedEntries.first else { return }
        openOrNavigate(entry)
    }

    private func openFocusedOrFirstSelectedEntryOrCurrentFolder() {
        if let entry = visibleEntries.first(where: { $0.id == selection.focusedEntryID }) ?? selectedEntries.first {
            openOrNavigate(entry)
        } else {
            onOpen(currentDirectory)
        }
    }

    private func navigateToParent() {
        let parent = currentDirectory.deletingLastPathComponent()
        guard parent.path != currentDirectory.path else { return }
        navigate(to: parent)
    }

    private func navigate(to url: URL, recordsHistory: Bool = true) {
        let standardizedURL = url.standardizedFileURL
        guard standardizedURL != currentDirectory.standardizedFileURL else { return }

        if recordsHistory {
            navigationHistory.recordNavigation(from: currentDirectory)
        }

        currentDirectory = standardizedURL
    }

    private func navigateBack() {
        guard let previousURL = navigationHistory.popBack(currentURL: currentDirectory) else { return }
        navigate(to: previousURL, recordsHistory: false)
    }

    private func navigateForward() {
        guard let nextURL = navigationHistory.popForward(currentURL: currentDirectory) else { return }
        navigate(to: nextURL, recordsHistory: false)
    }

    private func beginPathEditing() {
        editablePath = currentDirectory.path
        isPathEditing = true
        DispatchQueue.main.async {
            isPathEditorFocused = true
        }
    }

    private func commitEditedPath() {
        guard let url = OpenBrowserPathResolver.readableDirectory(from: editablePath) else {
            accessErrorMessage = OpenBrowserPathResolver.unreadablePathMessage(for: editablePath)
            isPathEditing = false
            return
        }

        navigate(to: url)
        isPathEditing = false
    }

    private func loadEntries() {
        do {
            entries = try OpenBrowserDataSource.loadEntries(in: currentDirectory, sortOption: sortOption, ascending: sortAscending)
            accessErrorMessage = nil
        } catch {
            entries = []
            accessErrorMessage = OpenBrowserPathResolver.accessErrorMessage(for: currentDirectory)
        }
        trimSelectionToVisibleEntries()
    }

    private func trimSelectionToVisibleEntries() {
        selection.trim(toVisibleEntries: visibleEntries)
    }

    private func prepareThumbnailResizeAnchor() {
        scrollCoordinator.prepareResizeAnchor(
            visibleEntries: visibleEntries,
            selection: selection,
            contentTopInset: Self.contentTopInset
        )
    }

    private func scrollToThumbnailAnchor(with proxy: ScrollViewProxy) {
        guard let thumbnailScrollAnchorID = scrollCoordinator.thumbnailScrollAnchorID else { return }
        guard scrollCoordinator.pendingResizeAnchor == nil || openBrowserScrollView == nil else { return }
        DispatchQueue.main.async {
            withAnimation(.smooth(duration: 0.24, extraBounce: 0)) {
                proxy.scrollTo(OpenBrowserScrollAnchor.id(for: thumbnailScrollAnchorID), anchor: .top)
            }
        }
    }

    private func adjustScrollForPendingThumbnailResize(with frames: [String: CGRect]) {
        guard let deltaY = scrollCoordinator.resizeDelta(after: frames),
              let openBrowserScrollView else { return }

        DispatchQueue.main.async {
            var origin = openBrowserScrollView.contentView.bounds.origin
            origin.y += deltaY
            origin.y = max(0, origin.y)
            openBrowserScrollView.contentView.scroll(to: origin)
            openBrowserScrollView.reflectScrolledClipView(openBrowserScrollView.contentView)
        }
    }

    private func revealContent() {
        guard !reduceMotion else {
            isContentRevealed = true
            return
        }

        isContentRevealed = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.035) {
            isContentRevealed = true
        }
    }

    private func toggleFavorite(_ entry: OpenBrowserEntry) {
        guard !entry.isDirectory else {
            addFolderToFavorites(entry)
            return
        }

        if favoriteFileIDs.contains(entry.id) {
            favoriteFileIDs.remove(entry.id)
        } else {
            favoriteFileIDs.insert(entry.id)
        }
        preferences.saveFavoriteFileIDs(favoriteFileIDs)
    }

    private func addFolderToFavorites(_ entry: OpenBrowserEntry) {
        guard entry.isDirectory else { return }
        addFavoriteFolder(url: entry.url)
    }

    private func addCurrentFolderToFavorites() {
        addFavoriteFolder(url: currentDirectory)
    }

    private func addFavoriteFolder(url: URL) {
        sidebarStore.addFavoriteFolder(url: url)
        preferences.saveSidebarStore(sidebarStore)
    }

    private func removeSidebarFavorite(_ item: OpenBrowserSidebarItem) {
        sidebarStore.removeSidebarFavorite(item)
        preferences.saveSidebarStore(sidebarStore)
    }

    private func moveFavoriteSidebarItem(draggedID: String, before targetID: String) {
        sidebarStore.moveFavoriteItem(draggedID: draggedID, before: targetID)
        preferences.saveSidebarStore(sidebarStore)
    }

    private func shareEntries(_ entries: [OpenBrowserEntry]) {
        let urls = entries.map(\.url)
        guard !urls.isEmpty, let contentView = NSApp.keyWindow?.contentView else { return }
        NSSharingServicePicker(items: urls).show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
    }

    private func shareContextEntries(_ requestedEntries: [OpenBrowserEntry], sourceEntry: OpenBrowserEntry) {
        if selection.contains(sourceEntry), !selectedEntries.isEmpty {
            shareEntries(selectedEntries.filter { !$0.isDirectory })
        } else {
            shareEntries(requestedEntries.filter { !$0.isDirectory })
        }
    }

    private func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders") else { return }
        NSWorkspace.shared.open(url)
    }

    private static func contentHorizontalPadding(for windowWidth: CGFloat, isSidebarVisible: Bool) -> CGFloat {
        let effectiveWidth = isSidebarVisible ? windowWidth - OpenBrowserPreferences.defaultSidebarWidth : windowWidth
        if effectiveWidth < 620 {
            return 16
        }
        if effectiveWidth < 860 {
            return 22
        }
        return 30
    }

    private static let contentTopInset: CGFloat = 86
    private static let sidebarContentTopInset: CGFloat = 86
    private static let collapsedSidebarLeadingInset: CGFloat = 116
    private static let footerHeight: CGFloat = 42
    private static let sidebarHandleWidth: CGFloat = 12
    private static let openBrowserGridHorizontalPadding: CGFloat = 30
    private static let thumbnailScrollAnchorTopOffset: CGFloat = contentTopInset - 6
    private static let searchExpansionOvershoot: CGFloat = 24
    private static let searchOvershootDuration: TimeInterval = 0.16
    private static let searchOpenAnimation = Animation.timingCurve(0.16, 1.0, 0.30, 1.0, duration: 0.24)
    private static let searchSettleAnimation = Animation.timingCurve(0.18, 0.92, 0.22, 1.0, duration: 0.22)
    private static let searchCloseAnimation = Animation.timingCurve(0.18, 0.88, 0.20, 1.0, duration: 0.24)
}
