import Foundation

struct FolderImageIndex: Equatable {
    let imageURLs: [URL]
    let currentIndex: Int

    init(imageURLs: [URL], currentIndex: Int) {
        self.imageURLs = imageURLs
        self.currentIndex = imageURLs.indices.contains(currentIndex)
            ? currentIndex
            : imageURLs.indices.first ?? 0
    }

    var currentURL: URL? {
        guard imageURLs.indices.contains(currentIndex) else { return nil }
        return imageURLs[currentIndex]
    }

    var isValid: Bool {
        currentURL != nil
    }

    static func sortedImageURLs(from urls: [URL]) -> [URL] {
        urls
            .filter(SupportedImageTypes.isBrowsableImage)
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    static func currentIndex(for selectedURL: URL, in urls: [URL]) -> Int? {
        urls.firstIndex(of: selectedURL)
    }
}
