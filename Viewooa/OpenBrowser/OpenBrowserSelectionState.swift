import AppKit
import Foundation

struct OpenBrowserSelectionState {
    private(set) var selectedEntryIDs: Set<String> = []
    private(set) var focusedEntryID: String?
    private(set) var anchorEntryID: String?

    var isEmpty: Bool {
        selectedEntryIDs.isEmpty
    }

    var count: Int {
        selectedEntryIDs.count
    }

    mutating func clear() {
        selectedEntryIDs.removeAll()
        focusedEntryID = nil
        anchorEntryID = nil
    }

    mutating func select(entryIDs: [String]) {
        selectedEntryIDs = Set(entryIDs)
        focusedEntryID = entryIDs.last
        anchorEntryID = entryIDs.first
    }

    mutating func select(_ entry: OpenBrowserEntry, visibleEntries: [OpenBrowserEntry], modifiers: NSEvent.ModifierFlags) {
        let visibleIDs = visibleEntries.map(\.id)

        if modifiers.contains(.shift),
           let anchorEntryID,
           let anchorIndex = visibleIDs.firstIndex(of: anchorEntryID),
           let targetIndex = visibleIDs.firstIndex(of: entry.id) {
            let range = min(anchorIndex, targetIndex)...max(anchorIndex, targetIndex)
            selectedEntryIDs = Set(visibleIDs[range])
        } else if modifiers.contains(.command) {
            if selectedEntryIDs.contains(entry.id) {
                selectedEntryIDs.remove(entry.id)
            } else {
                selectedEntryIDs.insert(entry.id)
            }
            anchorEntryID = entry.id
        } else {
            selectedEntryIDs = [entry.id]
            anchorEntryID = entry.id
        }

        focusedEntryID = entry.id
    }

    mutating func selectAll(_ entries: [OpenBrowserEntry]) {
        selectedEntryIDs = Set(entries.map(\.id))
        focusedEntryID = entries.last?.id
        anchorEntryID = entries.first?.id
    }

    mutating func trim(toVisibleEntries entries: [OpenBrowserEntry]) {
        let visibleIDs = Set(entries.map(\.id))
        selectedEntryIDs = selectedEntryIDs.intersection(visibleIDs)
        if let focusedEntryID, !visibleIDs.contains(focusedEntryID) {
            self.focusedEntryID = selectedEntryIDs.first
        }
        if let anchorEntryID, !visibleIDs.contains(anchorEntryID) {
            self.anchorEntryID = selectedEntryIDs.first
        }
    }

    func contains(_ entry: OpenBrowserEntry) -> Bool {
        selectedEntryIDs.contains(entry.id)
    }
}
