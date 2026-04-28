import AppKit
import Foundation
import PDFKit

struct ViewerPDFDocument {
    let fileURL: URL
    let pageImages: [NSImage]
    let pageURLs: [URL]

    var pageCount: Int {
        pageImages.count
    }

    func image(at pageIndex: Int) -> NSImage? {
        guard pageImages.indices.contains(pageIndex) else { return nil }
        return pageImages[pageIndex]
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
}

enum ViewerPDFDocumentLoader {
    static func load(from fileURL: URL) -> ViewerPDFDocument? {
        guard let document = PDFDocument(url: fileURL), document.pageCount > 0 else { return nil }

        let pageImages = (0..<document.pageCount).compactMap { pageIndex -> NSImage? in
            guard let page = document.page(at: pageIndex) else { return nil }
            return render(page)
        }

        guard pageImages.count == document.pageCount else { return nil }

        return ViewerPDFDocument(
            fileURL: fileURL,
            pageImages: pageImages,
            pageURLs: (0..<document.pageCount).map { pageURL(for: fileURL, pageIndex: $0) }
        )
    }

    private static func render(_ page: PDFPage) -> NSImage {
        let bounds = page.bounds(for: .mediaBox)
        let targetSize = NSSize(width: bounds.width * 2, height: bounds.height * 2)
        return page.thumbnail(of: targetSize, for: .mediaBox)
    }

    private static func pageURL(for fileURL: URL, pageIndex: Int) -> URL {
        var components = URLComponents(url: fileURL, resolvingAgainstBaseURL: false)
        components?.fragment = "page-\(pageIndex + 1)"
        return components?.url ?? fileURL
    }
}
