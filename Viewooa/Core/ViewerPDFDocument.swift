import AppKit
import Foundation
import PDFKit

final class ViewerPDFDocument {
    private enum CachePolicy {
        static let imageCountLimit = 8
        static let totalCostLimit = 96 * 1024 * 1024
        static let bytesPerPixel = 4
    }

    let fileURL: URL
    let pageCount: Int
    let pageURLs: [URL]

    private let document: PDFDocument
    private let imageCache = NSCache<NSNumber, NSImage>()

    init(fileURL: URL, document: PDFDocument) {
        self.fileURL = fileURL
        self.document = document
        self.pageCount = document.pageCount
        self.pageURLs = (0..<document.pageCount).map { Self.pageURL(for: fileURL, pageIndex: $0) }
        imageCache.countLimit = CachePolicy.imageCountLimit
        imageCache.totalCostLimit = CachePolicy.totalCostLimit
    }

    func image(at pageIndex: Int) -> NSImage? {
        guard (0..<pageCount).contains(pageIndex) else { return nil }

        let cacheKey = NSNumber(value: pageIndex)
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }

        guard let page = document.page(at: pageIndex) else { return nil }

        let renderedImage = Self.render(page)
        imageCache.setObject(renderedImage, forKey: cacheKey, cost: Self.cacheCost(for: renderedImage))
        return renderedImage
    }

    func pageIndexes(
        currentIndex: Int,
        layout: ViewerPageLayout,
        spreadDirection: SpreadDirection,
        coverModeEnabled: Bool
    ) -> [Int] {
        switch layout {
        case .single:
            return [currentIndex]
        case .spread:
            let indexes = ViewerPageLayoutResolver.spreadIndexes(
                currentIndex: currentIndex,
                itemCount: pageCount,
                coverModeEnabled: coverModeEnabled
            )
            return spreadDirection == .leftToRight ? indexes : indexes.reversed()
        case .verticalStrip:
            return Array(0..<pageCount)
        }
    }

    private static func render(_ page: PDFPage) -> NSImage {
        let bounds = page.bounds(for: .mediaBox)
        let targetSize = NSSize(width: bounds.width * 2, height: bounds.height * 2)
        return page.thumbnail(of: targetSize, for: .mediaBox)
    }

    private static func cacheCost(for image: NSImage) -> Int {
        let pixelWidth = max(1, Int(image.size.width))
        let pixelHeight = max(1, Int(image.size.height))
        return pixelWidth * pixelHeight * CachePolicy.bytesPerPixel
    }

    private static func pageURL(for fileURL: URL, pageIndex: Int) -> URL {
        var components = URLComponents(url: fileURL, resolvingAgainstBaseURL: false)
        components?.fragment = "page-\(pageIndex + 1)"
        return components?.url ?? fileURL
    }
}

enum ViewerPDFDocumentLoader {
    static func load(from fileURL: URL) -> ViewerPDFDocument? {
        guard let document = PDFDocument(url: fileURL), document.pageCount > 0 else { return nil }

        return ViewerPDFDocument(fileURL: fileURL, document: document)
    }
}
