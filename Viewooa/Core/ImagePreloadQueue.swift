import AppKit
import Foundation
import ImageIO

enum ImageFileLoader {
    private static let rawImageExtensions: Set<String> = [
        "3fr", "ari", "arw", "bay", "cr2", "cr3", "crw", "dcr", "dng", "erf",
        "fff", "iiq", "k25", "kdc", "mef", "mos", "mrw", "nef", "nrw", "orf",
        "pef", "raf", "raw", "rwl", "rw2", "sr2", "srf", "srw", "x3f"
    ]

    static func loadDisplayImage(at url: URL) -> NSImage? {
        loadImage(at: url, rawMaxPixelSize: 4096)
    }

    static func loadPreloadImage(at url: URL) -> NSImage? {
        loadImage(at: url, rawMaxPixelSize: 4096)
    }

    static func isRawImage(_ url: URL) -> Bool {
        rawImageExtensions.contains(url.pathExtension.lowercased())
    }

    private static func loadImage(at url: URL, rawMaxPixelSize: Int) -> NSImage? {
        guard isRawImage(url) else {
            return NSImage(contentsOf: url)
        }

        return autoreleasepool {
            let sourceOptions: [CFString: Any] = [
                kCGImageSourceShouldCache: false
            ]
            let thumbnailOptions: [CFString: Any] = [
                kCGImageSourceShouldCache: false,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: rawMaxPixelSize
            ]

            guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary),
                  let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
                return NSImage(contentsOf: url)
            }

            return NSImage(
                cgImage: cgImage,
                size: NSSize(width: cgImage.width, height: cgImage.height)
            )
        }
    }
}

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
        let isRawBrowsing = urls.indices.contains(currentIndex) && ImageFileLoader.isRawImage(urls[currentIndex])
        let candidateIndexes = isRawBrowsing
            ? [currentIndex - 1, currentIndex + 1]
            : [currentIndex - 1, currentIndex + 1, currentIndex + 2, currentIndex + 3]

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
        ImageFileLoader.loadPreloadImage(at: url)
    }
}
