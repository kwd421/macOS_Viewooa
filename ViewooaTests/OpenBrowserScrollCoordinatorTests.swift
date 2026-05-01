import XCTest
@testable import Viewooa

final class OpenBrowserScrollCoordinatorTests: XCTestCase {
    func testFirstFullyVisibleEntryChoosesTopLeftVisibleItem() {
        let entries = [entry("a"), entry("b"), entry("c")]
        var coordinator = OpenBrowserScrollCoordinator()
        coordinator.updateViewportSize(CGSize(width: 300, height: 400))
        coordinator.updateVisibleEntryFrames([
            entries[0].id: CGRect(x: 20, y: 90, width: 80, height: 80),
            entries[1].id: CGRect(x: 120, y: 90, width: 80, height: 80),
            entries[2].id: CGRect(x: 0, y: 20, width: 80, height: 80)
        ])

        XCTAssertEqual(
            coordinator.firstFullyVisibleEntryID(visibleEntries: entries, contentTopInset: 86),
            entries[0].id
        )
    }

    func testPreferredAnchorFallsBackToFocusedSelectionWhenNoFullyVisibleEntryExists() {
        let entries = [entry("a"), entry("b")]
        var selection = OpenBrowserSelectionState()
        selection.select(entries[1], visibleEntries: entries, modifiers: [])
        var coordinator = OpenBrowserScrollCoordinator()
        coordinator.updateViewportSize(CGSize(width: 300, height: 400))
        coordinator.updateVisibleEntryFrames([
            entries[0].id: CGRect(x: 20, y: 20, width: 80, height: 80),
            entries[1].id: CGRect(x: 20, y: 405, width: 80, height: 80)
        ])

        XCTAssertEqual(
            coordinator.preferredAnchorID(visibleEntries: entries, selection: selection, contentTopInset: 86),
            entries[1].id
        )
    }

    func testResizeDeltaReturnsMovementAndClearsPendingAnchor() {
        let entries = [entry("a")]
        var coordinator = OpenBrowserScrollCoordinator()
        coordinator.updateViewportSize(CGSize(width: 300, height: 400))
        coordinator.updateVisibleEntryFrames([entries[0].id: CGRect(x: 20, y: 100, width: 80, height: 80)])
        coordinator.prepareResizeAnchor(visibleEntries: entries, selection: OpenBrowserSelectionState(), contentTopInset: 86)

        let delta = coordinator.resizeDelta(after: [entries[0].id: CGRect(x: 20, y: 128, width: 120, height: 120)])

        XCTAssertEqual(delta, 28)
        XCTAssertNil(coordinator.pendingResizeAnchor)
        XCTAssertNil(coordinator.thumbnailScrollAnchorID)
    }

    func testDragSelectionEntryIDsSetFocusAndAnchor() {
        var selection = OpenBrowserSelectionState()

        selection.select(entryIDs: ["a", "b", "c"])

        XCTAssertEqual(selection.selectedEntryIDs, ["a", "b", "c"])
        XCTAssertEqual(selection.focusedEntryID, "c")
        XCTAssertEqual(selection.anchorEntryID, "a")
    }

    func testEmptyDragSelectionClearsFocusAndAnchor() {
        var selection = OpenBrowserSelectionState()
        selection.select(entryIDs: ["a", "b"])

        selection.select(entryIDs: [])

        XCTAssertTrue(selection.isEmpty)
        XCTAssertNil(selection.focusedEntryID)
        XCTAssertNil(selection.anchorEntryID)
    }

    func testTrimSelectionKeepsDeterministicFocusAndAnchor() {
        let entries = [entry("a"), entry("b"), entry("c"), entry("d")]
        var selection = OpenBrowserSelectionState()
        selection.selectAll(entries)

        selection.trim(toVisibleEntries: [entries[1], entries[2]])

        XCTAssertEqual(selection.selectedEntryIDs, [entries[1].id, entries[2].id])
        XCTAssertEqual(selection.anchorEntryID, entries[1].id)
        XCTAssertEqual(selection.focusedEntryID, entries[2].id)
    }

    private func entry(_ name: String) -> OpenBrowserEntry {
        OpenBrowserEntry(
            url: URL(fileURLWithPath: "/tmp/\(name).jpg"),
            name: "\(name).jpg",
            isDirectory: false,
            modificationDate: nil,
            fileSize: 0,
            typeIdentifier: nil
        )
    }
}
