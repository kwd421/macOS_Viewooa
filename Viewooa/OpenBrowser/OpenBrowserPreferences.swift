import Foundation
import CoreGraphics

struct OpenBrowserPreferences {
    var defaults: UserDefaults = .standard

    var recentDirectoryURL: URL? {
        guard let path = defaults.string(forKey: Self.recentDirectoryKey), !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path)
    }

    var sidebarVisible: Bool {
        defaults.object(forKey: Self.sidebarVisibilityKey) as? Bool ?? true
    }

    var initialSidebarWidth: CGFloat {
        let savedWidth = defaults.double(forKey: Self.sidebarWidthKey)
        let width = abs(savedWidth - Self.previousDefaultSidebarWidth) < 0.5
            ? Self.defaultSidebarWidth
            : (savedWidth > 0 ? CGFloat(savedWidth) : Self.defaultSidebarWidth)
        return Self.clampedSidebarWidth(width)
    }

    var sortOption: OpenBrowserSortOption {
        OpenBrowserSortOption(rawValue: defaults.string(forKey: Self.sortOptionKey) ?? "") ?? .name
    }

    var sortAscending: Bool {
        defaults.object(forKey: Self.sortAscendingKey) as? Bool ?? true
    }

    var favoriteFileIDs: Set<String> {
        Set(defaults.stringArray(forKey: Self.favoriteFilesKey) ?? [])
    }

    var displayMode: BrowserDisplayMode? {
        guard let rawValue = defaults.string(forKey: Self.displayModeKey) else { return nil }
        return BrowserDisplayMode(rawValue: rawValue)
    }

    var thumbnailSize: CGFloat? {
        let savedSize = defaults.double(forKey: Self.thumbnailSizeKey)
        guard savedSize > 0 else { return nil }
        return BrowserThumbnailSizing.clamped(CGFloat(savedSize))
    }

    func sidebarStore() -> OpenBrowserSidebarStore {
        OpenBrowserSidebarStore(
            customFavoriteFolders: loadCustomFavoriteFolders(),
            hiddenFavoriteSidebarIDs: Set(defaults.stringArray(forKey: Self.hiddenFavoriteSidebarKey) ?? []),
            favoriteSidebarOrder: defaults.stringArray(forKey: Self.favoriteSidebarOrderKey) ?? []
        )
    }

    func saveRecentDirectory(_ url: URL) {
        defaults.set(url.path, forKey: Self.recentDirectoryKey)
    }

    func saveSidebarVisible(_ isVisible: Bool) {
        defaults.set(isVisible, forKey: Self.sidebarVisibilityKey)
    }

    func saveSidebarWidth(_ width: CGFloat) {
        defaults.set(Double(Self.clampedSidebarWidth(width)), forKey: Self.sidebarWidthKey)
    }

    func saveSortOption(_ option: OpenBrowserSortOption) {
        defaults.set(option.rawValue, forKey: Self.sortOptionKey)
    }

    func saveSortAscending(_ isAscending: Bool) {
        defaults.set(isAscending, forKey: Self.sortAscendingKey)
    }

    func saveFavoriteFileIDs(_ ids: Set<String>) {
        defaults.set(Array(ids), forKey: Self.favoriteFilesKey)
    }

    func saveDisplayMode(_ mode: BrowserDisplayMode) {
        defaults.set(mode.rawValue, forKey: Self.displayModeKey)
    }

    func saveThumbnailSize(_ size: CGFloat) {
        defaults.set(Double(size), forKey: Self.thumbnailSizeKey)
    }

    func saveSidebarStore(_ store: OpenBrowserSidebarStore) {
        defaults.set(store.customFavoriteFolders.map(\.url.path), forKey: Self.customFavoriteFoldersKey)
        defaults.set(Array(store.hiddenFavoriteSidebarIDs), forKey: Self.hiddenFavoriteSidebarKey)
        defaults.set(store.favoriteSidebarOrder, forKey: Self.favoriteSidebarOrderKey)
    }

    static func clampedSidebarWidth(_ width: CGFloat) -> CGFloat {
        min(max(width, minimumSidebarWidth), maximumSidebarWidth)
    }

    private func loadCustomFavoriteFolders() -> [OpenBrowserSidebarItem] {
        let paths = defaults.stringArray(forKey: Self.customFavoriteFoldersKey) ?? []
        return paths.compactMap { path in
            let url = URL(fileURLWithPath: path)
            guard OpenBrowserDataSource.validDirectory(url) != nil else { return nil }
            return OpenBrowserSidebarItem.folder(url: url)
        }
    }

    static let minimumSidebarWidth: CGFloat = 118
    static let defaultSidebarWidth: CGFloat = 156
    static let maximumSidebarWidth: CGFloat = 320

    private static let previousDefaultSidebarWidth = 186.0
    private static let recentDirectoryKey = "OpenBrowserRecentDirectory"
    private static let sidebarVisibilityKey = "OpenBrowserSidebarVisible"
    private static let sidebarWidthKey = "OpenBrowserSidebarWidth"
    private static let sortOptionKey = "OpenBrowserSortOption"
    private static let sortAscendingKey = "OpenBrowserSortAscending"
    private static let favoriteFilesKey = "OpenBrowserFavoriteFiles"
    private static let customFavoriteFoldersKey = "OpenBrowserCustomFavoriteFolders"
    private static let hiddenFavoriteSidebarKey = "OpenBrowserHiddenFavoriteSidebarItems"
    private static let favoriteSidebarOrderKey = "OpenBrowserFavoriteSidebarOrder"
    private static let displayModeKey = "OpenBrowserDisplayMode"
    private static let thumbnailSizeKey = "OpenBrowserThumbnailSize"
}
