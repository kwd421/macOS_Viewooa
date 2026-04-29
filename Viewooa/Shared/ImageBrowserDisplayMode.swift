import Foundation

enum ImageBrowserDisplayMode: String, CaseIterable, Equatable, Identifiable {
    case thumbnails
    case list

    var id: Self { self }

    var title: String {
        switch self {
        case .thumbnails:
            "Thumbnails"
        case .list:
            "List"
        }
    }

    var systemImage: String {
        switch self {
        case .thumbnails:
            "square.grid.3x3"
        case .list:
            "list.bullet"
        }
    }
}
