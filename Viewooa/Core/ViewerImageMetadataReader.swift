import AppKit
import Foundation
import ImageIO

enum ViewerImageMetadataReader {
    static func rows(
        for currentImageURL: URL?,
        currentResolvedImage: NSImage?,
        index: FolderImageIndex?,
        isViewingPDF: Bool
    ) -> [ImageMetadataRow] {
        guard let currentImageURL else { return [] }

        var rows: [ImageMetadataRow] = [
            ImageMetadataRow(label: "Name", value: currentImageURL.lastPathComponent)
        ]

        if isViewingPDF, let index {
            rows.append(ImageMetadataRow(label: "Position", value: "Page \(index.currentIndex + 1) / \(index.imageURLs.count)"))
        } else if let index {
            rows.append(
                ImageMetadataRow(
                    label: "Position",
                    value: "\(index.currentIndex + 1) / \(index.imageURLs.count)"
                )
            )
        }

        if let dimensions = imageDimensions(at: currentImageURL, fallbackImage: currentResolvedImage) {
            rows.append(ImageMetadataRow(label: "Dimensions", value: "\(dimensions.width) x \(dimensions.height) px"))
        }

        let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .contentTypeKey, .contentModificationDateKey]
        if let values = try? currentImageURL.resourceValues(forKeys: resourceKeys) {
            if let fileSize = values.fileSize {
                rows.append(ImageMetadataRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)))
            }

            if let contentType = values.contentType {
                rows.append(ImageMetadataRow(label: "Type", value: contentType.localizedDescription ?? contentType.identifier))
            }

            if let modificationDate = values.contentModificationDate {
                rows.append(ImageMetadataRow(label: "Modified", value: dateFormatter.string(from: modificationDate)))
            }
        }

        rows.append(ImageMetadataRow(label: "Folder", value: currentImageURL.deletingLastPathComponent().path))
        return rows
    }

    private static func imageDimensions(at url: URL, fallbackImage: NSImage?) -> (width: Int, height: Int)? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return fallbackImage.map { (Int($0.size.width), Int($0.size.height)) }
        }

        return (width, height)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
