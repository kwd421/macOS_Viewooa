import XCTest
@testable import Viewooa

final class OpenBrowserPreferencesTests: XCTestCase {
    func testPersistsBrowserPreferencesInInjectedDefaults() {
        let defaults = makeDefaults()
        let preferences = OpenBrowserPreferences(defaults: defaults)
        let directory = URL(fileURLWithPath: "/tmp/viewooa-prefs")

        preferences.saveRecentDirectory(directory)
        preferences.saveSidebarVisible(false)
        preferences.saveSidebarWidth(999)
        preferences.saveSortOption(.size)
        preferences.saveSortAscending(false)
        preferences.saveFavoriteFileIDs(["/tmp/a.jpg", "/tmp/b.jpg"])
        preferences.saveDisplayMode(.list)
        preferences.saveThumbnailSize(180)

        XCTAssertEqual(preferences.recentDirectoryURL?.path, directory.path)
        XCTAssertFalse(preferences.sidebarVisible)
        XCTAssertEqual(preferences.initialSidebarWidth, OpenBrowserPreferences.maximumSidebarWidth)
        XCTAssertEqual(preferences.sortOption, .size)
        XCTAssertFalse(preferences.sortAscending)
        XCTAssertEqual(preferences.favoriteFileIDs, ["/tmp/a.jpg", "/tmp/b.jpg"])
        XCTAssertEqual(preferences.displayMode, .list)
        XCTAssertEqual(preferences.thumbnailSize, 180)
    }

    func testSidebarWidthMigratesPreviousDefaultToCurrentDefault() {
        let defaults = makeDefaults()
        defaults.set(186.0, forKey: "OpenBrowserSidebarWidth")

        let preferences = OpenBrowserPreferences(defaults: defaults)

        XCTAssertEqual(preferences.initialSidebarWidth, OpenBrowserPreferences.defaultSidebarWidth)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "ViewooaTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
