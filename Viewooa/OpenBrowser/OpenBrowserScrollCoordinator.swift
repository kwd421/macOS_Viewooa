import CoreGraphics
import Foundation

struct OpenBrowserScrollCoordinator {
    var thumbnailScrollAnchorID: String?
    var visibleEntryFrames: [String: CGRect] = [:]
    var viewportSize: CGSize = .zero
    var pendingResizeAnchor: OpenBrowserResizeAnchor?

    mutating func updateViewportSize(_ size: CGSize) {
        viewportSize = size
    }

    mutating func updateVisibleEntryFrames(_ frames: [String: CGRect]) {
        visibleEntryFrames = frames
    }

    mutating func prepareResizeAnchor(
        visibleEntries: [OpenBrowserEntry],
        selection: OpenBrowserSelectionState,
        contentTopInset: CGFloat
    ) {
        let anchorID = preferredAnchorID(
            visibleEntries: visibleEntries,
            selection: selection,
            contentTopInset: contentTopInset
        )
        thumbnailScrollAnchorID = anchorID

        if let anchorID, let frame = visibleEntryFrames[anchorID] {
            pendingResizeAnchor = OpenBrowserResizeAnchor(id: anchorID, minY: frame.minY)
        } else {
            pendingResizeAnchor = nil
        }
    }

    mutating func resizeDelta(after frames: [String: CGRect]) -> CGFloat? {
        guard let pendingResizeAnchor,
              let newFrame = frames[pendingResizeAnchor.id] else { return nil }

        let deltaY = newFrame.minY - pendingResizeAnchor.minY
        self.pendingResizeAnchor = nil
        thumbnailScrollAnchorID = nil

        guard abs(deltaY) > 0.5 else { return nil }
        return deltaY
    }

    func preferredAnchorID(
        visibleEntries: [OpenBrowserEntry],
        selection: OpenBrowserSelectionState,
        contentTopInset: CGFloat
    ) -> String? {
        if let firstVisibleID = firstFullyVisibleEntryID(
            visibleEntries: visibleEntries,
            contentTopInset: contentTopInset
        ) {
            return firstVisibleID
        }

        if let focusedEntryID = selection.focusedEntryID,
           visibleEntries.contains(where: { $0.id == focusedEntryID }) {
            return focusedEntryID
        }

        if let selectedID = selection.selectedEntryIDs.first(where: { selectedID in
            visibleEntries.contains(where: { $0.id == selectedID })
        }) {
            return selectedID
        }

        return nil
    }

    func firstFullyVisibleEntryID(
        visibleEntries: [OpenBrowserEntry],
        contentTopInset: CGFloat
    ) -> String? {
        guard viewportSize.height > 0 else { return nil }

        let visibleIDs = Set(visibleEntries.map(\.id))
        let topEdge = contentTopInset - 6
        let bottomEdge = viewportSize.height - 8

        return visibleEntryFrames
            .filter { id, frame in
                visibleIDs.contains(id)
                    && frame.minY >= topEdge
                    && frame.maxY <= bottomEdge
                    && frame.maxX > 0
                    && frame.minX < viewportSize.width
            }
            .sorted { lhs, rhs in
                if abs(lhs.value.minY - rhs.value.minY) > 1 {
                    return lhs.value.minY < rhs.value.minY
                }
                return lhs.value.minX < rhs.value.minX
            }
            .first?.key
    }
}
