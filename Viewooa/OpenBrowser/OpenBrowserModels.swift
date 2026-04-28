import SwiftUI
import UniformTypeIdentifiers

struct OpenBrowserPathComponent: Identifiable {
    let title: String
    let url: URL

    var id: String { url.path }
}

struct OpenBrowserEntry: Identifiable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let modificationDate: Date?
    let fileSize: Int
    let typeIdentifier: String?

    var id: String { url.path }

    var kindTitle: String {
        if isDirectory {
            return "Folder"
        }

        if SupportedImageTypes.isPDF(url) {
            return "PDF"
        }

        return url.pathExtension.uppercased()
    }
}

enum OpenBrowserSortOption: String, CaseIterable, Identifiable {
    case name
    case kind
    case dateModified
    case size

    var id: Self { self }

    var title: String {
        switch self {
        case .name:
            "Name"
        case .kind:
            "Kind"
        case .dateModified:
            "Date Modified"
        case .size:
            "Size"
        }
    }
}

struct OpenBrowserSidebarItem: Identifiable {
    let title: String
    let systemImage: String
    let url: URL

    var id: String { url.path }
}

struct OpenBrowserSidebarDropDelegate: DropDelegate {
    let targetItem: OpenBrowserSidebarItem
    let items: [OpenBrowserSidebarItem]
    @Binding var draggingItemID: String?
    let onMove: (String, String) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggingItemID, draggingItemID != targetItem.id else { return }
        guard items.contains(where: { $0.id == draggingItemID }) else { return }
        onMove(draggingItemID, targetItem.id)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItemID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
