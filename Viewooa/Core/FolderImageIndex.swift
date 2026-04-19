import Foundation

struct FolderImageIndex: Equatable {
    let imageURLs: [URL]
    let currentIndex: Int

    static func sortedImageURLs(from urls: [URL]) -> [URL] {
        urls
            .filter(SupportedImageTypes.isSupported)
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    static func currentIndex(for selectedURL: URL, in urls: [URL]) -> Int? {
        urls.firstIndex(of: selectedURL)
    }
}
