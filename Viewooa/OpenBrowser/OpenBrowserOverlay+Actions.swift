import AppKit
import SwiftUI

extension OpenBrowserOverlay {
    func handleAppear() {
        restoreBrowserPreferences()
        loadEntries()
        revealContent()
    }

    func restoreBrowserPreferences() {
        if let savedDisplayMode = preferences.displayMode {
            displayMode = savedDisplayMode
        }

        if let savedThumbnailSize = preferences.thumbnailSize {
            thumbnailSize = savedThumbnailSize
        }
    }

    func handleDirectoryChange() {
        searchText = ""
        loadEntries()
        selection.clear()
        preferences.saveRecentDirectory(currentDirectory)
        revealContent()
    }

    func handleSearchChange(_ value: String) {
        trimSelectionToVisibleEntries()
    }

    func handleSearchExpansionChange(_ value: Bool) {
        guard value else {
            isSearchFieldFocused = false
            return
        }

        DispatchQueue.main.async {
            isSearchFieldFocused = true
        }
    }

    func handleSearchFocusChange(_ value: Bool) {
        guard !value, searchText.isEmpty, isSearchExpanded else { return }
        closeSearch()
    }

    func openSearch() {
        guard !isSearchExpanded else { return }

        searchAnimationGeneration += 1
        guard !reduceMotion else {
            searchExpansionExtra = 0
            isSearchExpanded = true
            return
        }

        let generation = searchAnimationGeneration
        searchExpansionExtra = Self.searchExpansionOvershoot
        withAnimation(Self.searchOpenAnimation) {
            isSearchExpanded = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.searchOvershootDuration) {
            guard isSearchExpanded, searchAnimationGeneration == generation else { return }
            withAnimation(Self.searchSettleAnimation) {
                searchExpansionExtra = 0
            }
        }
    }

    func closeSearch() {
        searchAnimationGeneration += 1
        guard !reduceMotion else {
            searchExpansionExtra = 0
            isSearchExpanded = false
            return
        }

        withAnimation(Self.searchCloseAnimation) {
            searchExpansionExtra = 0
            isSearchExpanded = false
        }
    }

    func handleEscape() {
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

        if !selection.isEmpty {
            selection.clear()
        }
    }

    func handleSortOptionChange(_ value: OpenBrowserSortOption) {
        preferences.saveSortOption(value)
        loadEntries()
    }

    func handleSortAscendingChange(_ value: Bool) {
        preferences.saveSortAscending(value)
        loadEntries()
    }

    func handleSidebarVisibilityChange(_ value: Bool) {
        preferences.saveSidebarVisible(value)
    }

    func handleSidebarWidthChange(_ value: CGFloat) {
        preferences.saveSidebarWidth(value)
    }

    func handleThumbnailSizeChange(_ value: CGFloat) {
        preferences.saveThumbnailSize(value)
    }

    func handleDisplayModeChange(_ value: BrowserDisplayMode) {
        preferences.saveDisplayMode(value)
    }

    func openOrNavigate(_ entry: OpenBrowserEntry) {
        if entry.isDirectory {
            navigate(to: entry.url)
        } else {
            onOpen(entry.url)
        }
    }

    func selectEntry(_ entry: OpenBrowserEntry) {
        selection.select(entry, visibleEntries: visibleEntries, modifiers: NSEvent.modifierFlags)
    }

    func clearSelection() {
        selection.clear()
    }

    func selectAllVisibleEntries() {
        selection.selectAll(visibleEntries)
    }

    func beginSelectionDrag(at point: CGPoint, modifiers: NSEvent.ModifierFlags) {
        selectionDragStart = point
        selectionDragCurrent = point
        selectionDragBaseEntryIDs = selection.selectedEntryIDs

        if modifiers.contains(.command) {
            if let startingEntryID = entryID(at: point),
               selection.selectedEntryIDs.contains(startingEntryID) {
                selectionDragMode = .subtract
            } else {
                selectionDragMode = .add
            }
        } else {
            selectionDragMode = .replace
            selection.clear()
            selectionDragBaseEntryIDs = []
        }
    }

    func updateSelectionDrag(to point: CGPoint) {
        guard selectionDragStart != nil else {
            beginSelectionDrag(at: point, modifiers: NSEvent.modifierFlags)
            return
        }

        selectionDragCurrent = point
        selection.select(
            entryIDs: entryIDs(in: currentSelectionDragRect),
            mode: selectionDragMode,
            baseSelection: selectionDragBaseEntryIDs
        )
    }

    func endSelectionDrag() {
        selectionDragStart = nil
        selectionDragCurrent = nil
        selectionDragMode = .replace
        selectionDragBaseEntryIDs = []
    }

    private func entryIDs(in rect: CGRect?) -> [String] {
        guard let rect, rect.width > 2 || rect.height > 2 else { return [] }
        let visibleIDs = Set(visibleEntries.map(\.id))
        return scrollCoordinator.visibleEntryFrames
            .filter { id, frame in
                visibleIDs.contains(id) && frame.intersects(rect)
            }
            .sorted { lhs, rhs in
                if abs(lhs.value.minY - rhs.value.minY) > 1 {
                    return lhs.value.minY < rhs.value.minY
                }
                return lhs.value.minX < rhs.value.minX
            }
            .map(\.key)
    }

    private func entryID(at point: CGPoint) -> String? {
        let visibleIDs = Set(visibleEntries.map(\.id))
        return scrollCoordinator.visibleEntryFrames
            .filter { id, frame in
                visibleIDs.contains(id) && frame.contains(point)
            }
            .sorted { lhs, rhs in
                if abs(lhs.value.minY - rhs.value.minY) > 1 {
                    return lhs.value.minY < rhs.value.minY
                }
                return lhs.value.minX < rhs.value.minX
            }
            .first?.key
    }

    func openFocusedOrFirstSelectedEntry() {
        guard let entry = visibleEntries.first(where: { $0.id == selection.focusedEntryID }) ?? selectedEntries.first else { return }
        openOrNavigate(entry)
    }

    func openFocusedOrFirstSelectedEntryOrCurrentFolder() {
        if let entry = visibleEntries.first(where: { $0.id == selection.focusedEntryID }) ?? selectedEntries.first {
            openOrNavigate(entry)
        } else {
            onOpen(currentDirectory)
        }
    }

    func navigateToParent() {
        let parent = currentDirectory.deletingLastPathComponent()
        guard parent.path != currentDirectory.path else { return }
        navigate(to: parent)
    }

    func navigate(to url: URL, recordsHistory: Bool = true) {
        let standardizedURL = url.standardizedFileURL
        guard standardizedURL != currentDirectory.standardizedFileURL else { return }

        if recordsHistory {
            navigationHistory.recordNavigation(from: currentDirectory)
        }

        currentDirectory = standardizedURL
    }

    func navigateBack() {
        guard let previousURL = navigationHistory.popBack(currentURL: currentDirectory) else { return }
        navigate(to: previousURL, recordsHistory: false)
    }

    func navigateForward() {
        guard let nextURL = navigationHistory.popForward(currentURL: currentDirectory) else { return }
        navigate(to: nextURL, recordsHistory: false)
    }

    func beginPathEditing() {
        editablePath = currentDirectory.path
        isPathEditing = true
        DispatchQueue.main.async {
            isPathEditorFocused = true
        }
    }

    func commitEditedPath() {
        guard let url = OpenBrowserPathResolver.readableDirectory(from: editablePath) else {
            accessErrorMessage = OpenBrowserPathResolver.unreadablePathMessage(for: editablePath)
            isPathEditing = false
            return
        }

        navigate(to: url)
        isPathEditing = false
    }

    func loadEntries() {
        do {
            entries = try OpenBrowserDataSource.loadEntries(in: currentDirectory, sortOption: sortOption, ascending: sortAscending)
            accessErrorMessage = nil
        } catch {
            entries = []
            accessErrorMessage = OpenBrowserPathResolver.accessErrorMessage(for: currentDirectory)
        }
        trimSelectionToVisibleEntries()
    }

    func trimSelectionToVisibleEntries() {
        selection.trim(toVisibleEntries: visibleEntries)
    }

    func prepareThumbnailResizeAnchor() {
        scrollCoordinator.prepareResizeAnchor(
            visibleEntries: visibleEntries,
            selection: selection,
            contentTopInset: Self.contentTopInset
        )
    }

    func scrollToThumbnailAnchor(with proxy: ScrollViewProxy) {
        guard let thumbnailScrollAnchorID = scrollCoordinator.thumbnailScrollAnchorID else { return }
        guard scrollCoordinator.pendingResizeAnchor == nil || openBrowserScrollView == nil else { return }
        DispatchQueue.main.async {
            withAnimation(.smooth(duration: 0.24, extraBounce: 0)) {
                proxy.scrollTo(OpenBrowserScrollAnchor.id(for: thumbnailScrollAnchorID), anchor: .top)
            }
        }
    }

    func adjustScrollForPendingThumbnailResize(with frames: [String: CGRect]) {
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

    func revealContent() {
        isContentRevealed = true
    }

    func toggleFavorite(_ entry: OpenBrowserEntry) {
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

    func addFolderToFavorites(_ entry: OpenBrowserEntry) {
        guard entry.isDirectory else { return }
        addFavoriteFolder(url: entry.url)
    }

    func addCurrentFolderToFavorites() {
        addFavoriteFolder(url: currentDirectory)
    }

    func addFavoriteFolder(url: URL) {
        sidebarStore.addFavoriteFolder(url: url)
        preferences.saveSidebarStore(sidebarStore)
    }

    func removeSidebarFavorite(_ item: OpenBrowserSidebarItem) {
        sidebarStore.removeSidebarFavorite(item)
        preferences.saveSidebarStore(sidebarStore)
    }

    func moveFavoriteSidebarItem(draggedID: String, before targetID: String) {
        sidebarStore.moveFavoriteItem(draggedID: draggedID, before: targetID)
        preferences.saveSidebarStore(sidebarStore)
    }

    func shareEntries(_ entries: [OpenBrowserEntry]) {
        let urls = entries.map(\.url)
        guard !urls.isEmpty, let contentView = NSApp.keyWindow?.contentView else { return }
        NSSharingServicePicker(items: urls).show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
    }

    func shareContextEntries(_ requestedEntries: [OpenBrowserEntry], sourceEntry: OpenBrowserEntry) {
        if selection.contains(sourceEntry), !selectedEntries.isEmpty {
            shareEntries(selectedEntries.filter { !$0.isDirectory })
        } else {
            shareEntries(requestedEntries.filter { !$0.isDirectory })
        }
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders") else { return }
        NSWorkspace.shared.open(url)
    }
}
