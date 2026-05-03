import SwiftUI
import AppKit

struct OpenBrowserOverlay: View {
    let initialDirectory: URL
    @Binding var displayMode: BrowserDisplayMode
    @Binding var thumbnailSize: CGFloat
    let onOpen: (URL) -> Void
    let onDismiss: () -> Void
    let preferences: OpenBrowserPreferences

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var currentDirectory: URL
    @State var entries: [OpenBrowserEntry] = []
    @State var searchText = ""
    @State var sortOption = OpenBrowserSortOption.name
    @State var sortAscending = true
    @State var selection = OpenBrowserSelectionState()
    @State var favoriteFileIDs: Set<String> = []
    @State var sidebarStore = OpenBrowserSidebarStore()
    @State var draggingSidebarItemID: String?
    @State var accessErrorMessage: String?
    @State var isSidebarVisible = true
    @State var sidebarWidth: CGFloat = OpenBrowserPreferences.defaultSidebarWidth
    @State var sidebarDragStartWidth: CGFloat?
    @State var isContentRevealed = false
    @State var navigationHistory = OpenBrowserNavigationHistory()
    @State var isSearchExpanded = false
    @State var searchExpansionExtra: CGFloat = 0
    @State var searchAnimationGeneration = 0
    @State var scrollCoordinator = OpenBrowserScrollCoordinator()
    @State var openBrowserScrollView: NSScrollView?
    @State var selectionDragStart: CGPoint?
    @State var selectionDragCurrent: CGPoint?
    @State var selectionDragMode = OpenBrowserSelectionDragMode.replace
    @State var selectionDragBaseEntryIDs: Set<String> = []
    @State var isPathEditing = false
    @State var editablePath = ""
    @FocusState var isPathEditorFocused: Bool
    @FocusState var isSearchFieldFocused: Bool

    init(
        initialDirectory: URL,
        displayMode: Binding<BrowserDisplayMode>,
        thumbnailSize: Binding<CGFloat>,
        onOpen: @escaping (URL) -> Void,
        onDismiss: @escaping () -> Void,
        prefersRecentDirectory: Bool = false
    ) {
        self.initialDirectory = initialDirectory
        self._displayMode = displayMode
        self._thumbnailSize = thumbnailSize
        self.onOpen = onOpen
        self.onDismiss = onDismiss
        let preferences = OpenBrowserPreferences()
        self.preferences = preferences
        let savedDirectory = prefersRecentDirectory ? preferences.recentDirectoryURL ?? initialDirectory : initialDirectory
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
}
