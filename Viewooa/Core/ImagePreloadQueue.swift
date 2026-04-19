import AppKit
import Foundation

final class ImagePreloadQueue: @unchecked Sendable {
    typealias ImageLoader = @Sendable (URL) -> NSImage?

    private let cache = NSCache<NSURL, NSImage>()
    private let maxCachedImages: Int
    private let imageLoader: ImageLoader
    private let preloadQueue = DispatchQueue(label: "com.seinel.Viewooa.ImagePreloadQueue", qos: .userInitiated)
    private let lock = NSLock()
    private var insertionOrder: [URL] = []

    init(
        maxCachedImages: Int = 4,
        imageLoader: @escaping ImageLoader = ImagePreloadQueue.loadImage
    ) {
        self.maxCachedImages = maxCachedImages
        self.imageLoader = imageLoader
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
        lock.lock()
        defer { lock.unlock() }

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

    func preload(urls: [URL]) {
        for url in urls where image(for: url) == nil {
            preloadQueue.async { [weak self] in
                guard let self, self.image(for: url) == nil, let image = self.imageLoader(url) else { return }
                self.store(image, for: url)
            }
        }
    }

    private static func loadImage(at url: URL) -> NSImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return NSImage(data: data)
    }
}
