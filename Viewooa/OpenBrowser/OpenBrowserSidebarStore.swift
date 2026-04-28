import Foundation

struct OpenBrowserSidebarStore {
    var customFavoriteFolders: [OpenBrowserSidebarItem] = []
    var hiddenFavoriteSidebarIDs: Set<String> = []
    var favoriteSidebarOrder: [String] = []

    var standardFavoriteItems: [OpenBrowserSidebarItem] {
        [
            OpenBrowserSidebarItem(title: "Home", systemImage: "house", url: FileManager.default.homeDirectoryForCurrentUser),
            directoryItem("Desktop", "desktopcomputer", .desktopDirectory),
            directoryItem("Downloads", "arrow.down.circle", .downloadsDirectory),
            directoryItem("Pictures", "photo.on.rectangle", .picturesDirectory),
            directoryItem("Documents", "doc.text", .documentDirectory),
            directoryItem("Movies", "film", .moviesDirectory)
        ].compactMap { $0 }
    }

    var favoriteItems: [OpenBrowserSidebarItem] {
        let allItems = (standardFavoriteItems + customFavoriteFolders)
            .filter { !hiddenFavoriteSidebarIDs.contains($0.id) }
        var itemsByID: [String: OpenBrowserSidebarItem] = [:]
        for item in allItems {
            itemsByID[item.id] = itemsByID[item.id] ?? item
        }

        let orderedItems = favoriteSidebarOrder.compactMap { itemsByID[$0] }
        let orderedIDs = Set(orderedItems.map(\.id))
        let remainingItems = allItems.filter { !orderedIDs.contains($0.id) }
        return orderedItems + remainingItems
    }

    var locationItems: [OpenBrowserSidebarItem] {
        var items = [OpenBrowserSidebarItem(title: "Macintosh HD", systemImage: "internaldrive", url: URL(fileURLWithPath: "/"))]
        let volumes = (try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: "/Volumes"),
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        items.append(contentsOf: volumes.compactMap { url in
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { return nil }
            return OpenBrowserSidebarItem(title: url.lastPathComponent, systemImage: "externaldrive", url: url)
        })

        return items
    }

    mutating func addFavoriteFolder(url: URL) {
        let item = OpenBrowserSidebarItem.folder(url: url)
        hiddenFavoriteSidebarIDs.remove(item.id)
        guard !(standardFavoriteItems + customFavoriteFolders).contains(where: { $0.id == item.id }) else { return }
        customFavoriteFolders.append(item)
        favoriteSidebarOrder.append(item.id)
    }

    mutating func removeSidebarFavorite(_ item: OpenBrowserSidebarItem) {
        if customFavoriteFolders.contains(where: { $0.id == item.id }) {
            customFavoriteFolders.removeAll { $0.id == item.id }
        } else {
            hiddenFavoriteSidebarIDs.insert(item.id)
        }

        favoriteSidebarOrder.removeAll { $0 == item.id }
    }

    mutating func moveFavoriteItem(draggedID: String, before targetID: String) {
        guard draggedID != targetID else { return }
        var ids = favoriteItems.map(\.id)
        guard let fromIndex = ids.firstIndex(of: draggedID), let toIndex = ids.firstIndex(of: targetID) else { return }
        let dragged = ids.remove(at: fromIndex)
        ids.insert(dragged, at: toIndex > fromIndex ? toIndex - 1 : toIndex)
        favoriteSidebarOrder = ids
    }

    private func directoryItem(
        _ title: String,
        _ systemImage: String,
        _ directory: FileManager.SearchPathDirectory
    ) -> OpenBrowserSidebarItem? {
        guard let url = FileManager.default.urls(for: directory, in: .userDomainMask).first else { return nil }
        return OpenBrowserSidebarItem(title: title, systemImage: systemImage, url: url)
    }
}

extension OpenBrowserSidebarItem {
    static func folder(url: URL) -> OpenBrowserSidebarItem {
        OpenBrowserSidebarItem(
            title: url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent,
            systemImage: "folder",
            url: url
        )
    }
}
