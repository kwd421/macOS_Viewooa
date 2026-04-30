import SwiftUI
import AppKit
import ImageIO
import QuickLookThumbnailing

struct ImageBrowserThumbnail: View {
    let url: URL
    let targetPixelSize: CGFloat
    @State private var image: NSImage?

    private var requestedPixelSize: CGFloat {
        ImageBrowserThumbnailCache.normalizedPixelSize(targetPixelSize)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(VisualInteractionPalette.imageBrowserPreviewFill)

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(VisualInteractionPalette.imageBrowserPreviewPlaceholder)
            }
        }
        .clipped()
        .task(id: "\(url.path)-\(Int(requestedPixelSize))") {
            image = await ImageBrowserThumbnailCache.shared.image(
                for: url,
                targetPixelSize: requestedPixelSize
            )
        }
    }
}

private final class ImageBrowserThumbnailCache: @unchecked Sendable {
    static let shared = ImageBrowserThumbnailCache()

    private let cache = NSCache<NSString, NSImage>()
    private let renderQueue = DispatchQueue(label: "com.seinel.Viewooa.ImageBrowserThumbnailCache", qos: .utility)
    private let renderLimiter = DispatchSemaphore(value: 2)

    private init() {
        cache.countLimit = 384
        cache.totalCostLimit = 80 * 1024 * 1024
    }

    func image(for url: URL, targetPixelSize: CGFloat) async -> NSImage? {
        let pixelSize = Self.normalizedPixelSize(targetPixelSize)
        let cacheKey = Self.cacheKey(for: url, pixelSize: pixelSize)

        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        if let quickLookImage = await quickLookThumbnail(for: url, pixelSize: pixelSize) {
            store(quickLookImage, forKey: cacheKey)
            return quickLookImage
        }

        guard let imageSourceThumbnail = await imageIOLimitedThumbnail(for: url, pixelSize: pixelSize) else {
            return nil
        }

        store(imageSourceThumbnail, forKey: cacheKey)
        return imageSourceThumbnail
    }

    static func normalizedPixelSize(_ targetPixelSize: CGFloat) -> CGFloat {
        let clampedSize = min(max(targetPixelSize, 96), 512)
        return (clampedSize / 32).rounded(.up) * 32
    }

    private static func cacheKey(for url: URL, pixelSize: CGFloat) -> NSString {
        "\(url.path)|\(Int(pixelSize))" as NSString
    }

    private func store(_ image: NSImage, forKey key: NSString) {
        let estimatedCost = max(1, Int(image.size.width * image.size.height * 4))
        cache.setObject(image, forKey: key, cost: estimatedCost)
    }

    private func quickLookThumbnail(for url: URL, pixelSize: CGFloat) async -> NSImage? {
        await withCheckedContinuation { continuation in
            let request = QLThumbnailGenerator.Request(
                fileAt: url,
                size: CGSize(width: pixelSize, height: pixelSize),
                scale: NSScreen.main?.backingScaleFactor ?? 2,
                representationTypes: .thumbnail
            )

            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
                continuation.resume(returning: representation?.nsImage)
            }
        }
    }

    private func imageIOLimitedThumbnail(for url: URL, pixelSize: CGFloat) async -> NSImage? {
        await withCheckedContinuation { continuation in
            renderQueue.async { [renderLimiter] in
                renderLimiter.wait()
                defer { renderLimiter.signal() }

                continuation.resume(returning: Self.makeImageIOThumbnail(for: url, pixelSize: pixelSize))
            }
        }
    }

    private static func makeImageIOThumbnail(for url: URL, pixelSize: CGFloat) -> NSImage? {
        autoreleasepool {
            let options: [CFString: Any] = [
                kCGImageSourceShouldCache: false,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: Int(pixelSize)
            ]

            if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
               let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                return NSImage(
                    cgImage: cgImage,
                    size: NSSize(width: cgImage.width, height: cgImage.height)
                )
            }

            return nil
        }
    }
}
