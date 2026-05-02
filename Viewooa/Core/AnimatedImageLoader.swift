import AppKit
import Foundation
import ImageIO

struct AnimatedImageFrame {
    let image: NSImage
    let duration: TimeInterval
}

enum AnimatedImageLoader {
    private enum Limits {
        static let maximumFrameCount = 600
        static let maximumPixelCountPerFrame = 2_500_000
    }

    static func isAnimatedGIF(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "gif"
    }

    static func loadGIFFrames(at url: URL) -> [AnimatedImageFrame] {
        guard isAnimatedGIF(url),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return []
        }

        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 1,
              frameCount <= Limits.maximumFrameCount,
              isWithinPixelLimit(source: source) else { return [] }

        return (0..<frameCount).compactMap { index in
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                return nil
            }

            let image = NSImage(
                cgImage: cgImage,
                size: NSSize(width: cgImage.width, height: cgImage.height)
            )
            return AnimatedImageFrame(
                image: image,
                duration: frameDuration(at: index, source: source)
            )
        }
    }

    private static func frameDuration(at index: Int, source: CGImageSource) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 0.1
        }

        let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let delay = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval
        return max(unclampedDelay ?? delay ?? 0.1, 0.02)
    }

    private static func isWithinPixelLimit(source: CGImageSource) -> Bool {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return true
        }

        return width * height <= Limits.maximumPixelCountPerFrame
    }
}
