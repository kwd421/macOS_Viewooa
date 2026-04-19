import AppKit
import Foundation

final class ImagePreloadQueue {
    private let cache = NSCache<NSURL, NSImage>()
    private let maxCachedImages: Int
    private var insertionOrder: [URL] = []

    init(maxCachedImages: Int = 4) {
        self.maxCachedImages = maxCachedImages
        cache.countLimit = maxCachedImages
    }

    func targetURLs(for urls: [URL], currentIndex: Int) -> [URL] {
        let candidateIndexes = [currentIndex - 1, currentIndex + 1, currentIndex + 2, currentIndex + 3]

        return candidateIndexes.compactMap { index in
            guard urls.indices.contains(index) else { return nil }
            return urls[index]
        }
    }

    func store(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
        insertionOrder.removeAll { $0 == url }
        insertionOrder.append(url)

        while insertionOrder.count > maxCachedImages {
            let evictedURL = insertionOrder.removeFirst()
            cache.removeObject(forKey: evictedURL as NSURL)
        }
    }

    func image(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }
}
