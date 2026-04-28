import XCTest
@testable import Viewooa

final class OpenBrowserSidebarStoreTests: XCTestCase {
    func testAddsCustomFolderAndDoesNotDuplicateIt() {
        let url = URL(fileURLWithPath: "/tmp/viewooa-sidebar-folder")
        var store = OpenBrowserSidebarStore()

        store.addFavoriteFolder(url: url)
        store.addFavoriteFolder(url: url)

        XCTAssertEqual(store.customFavoriteFolders.map(\.id), [url.path])
        XCTAssertEqual(store.favoriteSidebarOrder.filter { $0 == url.path }.count, 1)
    }

    func testRemovingCustomFavoriteRemovesItFromOrder() {
        let url = URL(fileURLWithPath: "/tmp/viewooa-custom")
        var store = OpenBrowserSidebarStore()
        store.addFavoriteFolder(url: url)

        store.removeSidebarFavorite(OpenBrowserSidebarItem.folder(url: url))

        XCTAssertTrue(store.customFavoriteFolders.isEmpty)
        XCTAssertFalse(store.favoriteSidebarOrder.contains(url.path))
    }

    func testRemovingStandardFavoriteHidesItInsteadOfDeletingOthers() {
        var store = OpenBrowserSidebarStore()
        let desktop = store.standardFavoriteItems.first { $0.title == "Desktop" }!

        store.removeSidebarFavorite(desktop)

        XCTAssertTrue(store.hiddenFavoriteSidebarIDs.contains(desktop.id))
        XCTAssertFalse(store.favoriteItems.contains { $0.id == desktop.id })
    }

    func testMovingFavoriteItemUpdatesOrder() {
        let first = URL(fileURLWithPath: "/tmp/viewooa-first")
        let second = URL(fileURLWithPath: "/tmp/viewooa-second")
        var store = OpenBrowserSidebarStore()
        store.addFavoriteFolder(url: first)
        store.addFavoriteFolder(url: second)

        store.moveFavoriteItem(draggedID: second.path, before: first.path)

        XCTAssertLessThan(
            store.favoriteSidebarOrder.firstIndex(of: second.path)!,
            store.favoriteSidebarOrder.firstIndex(of: first.path)!
        )
    }
}
