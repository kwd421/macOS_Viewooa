import Foundation

enum ViewerDocumentOpenResult {
    case imageIndex(FolderImageIndex)
    case pdf(ViewerPDFDocument)
}

enum ViewerDocumentOpenError: LocalizedError {
    case unsupportedFile
    case selectedImageMissing
    case emptyFolder
    case unreadablePDF

    var errorDescription: String? {
        switch self {
        case .unsupportedFile:
            "The selected file is not a supported image."
        case .selectedImageMissing:
            "The selected image could not be found in its folder."
        case .emptyFolder:
            "The selected folder does not contain supported images."
        case .unreadablePDF:
            "The selected PDF could not be opened."
        }
    }
}

final class ViewerDocumentLoader {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func openFile(at fileURL: URL) throws -> ViewerDocumentOpenResult {
        if SupportedImageTypes.isPDF(fileURL) {
            guard let document = ViewerPDFDocumentLoader.load(from: fileURL) else {
                throw ViewerDocumentOpenError.unreadablePDF
            }

            return .pdf(document)
        }

        guard SupportedImageTypes.isBrowsableImage(fileURL) else {
            throw ViewerDocumentOpenError.unsupportedFile
        }

        let imageURLs = try imageURLs(in: fileURL.deletingLastPathComponent())
        guard let currentIndex = FolderImageIndex.currentIndex(for: fileURL, in: imageURLs) else {
            throw ViewerDocumentOpenError.selectedImageMissing
        }

        return .imageIndex(FolderImageIndex(imageURLs: imageURLs, currentIndex: currentIndex))
    }

    func openFolder(at folderURL: URL) throws -> FolderImageIndex {
        let imageURLs = try imageURLs(in: folderURL)

        guard !imageURLs.isEmpty else {
            throw ViewerDocumentOpenError.emptyFolder
        }

        return FolderImageIndex(imageURLs: imageURLs, currentIndex: 0)
    }

    func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func imageURLs(in folderURL: URL) throws -> [URL] {
        let contents = try fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return FolderImageIndex.sortedImageURLs(from: contents)
    }
}
