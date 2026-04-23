import Foundation
import UniformTypeIdentifiers

enum SupportedImageTypes {
    static func isSupported(_ url: URL) -> Bool {
        isBrowsableImage(url)
    }

    static func isBrowsableImage(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return false
        }

        return type.conforms(to: .image) && !type.conforms(to: .pdf)
    }

    static func isOpenableFile(_ url: URL) -> Bool {
        isBrowsableImage(url) || isPDF(url)
    }

    static func isPDF(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return false
        }

        return type.conforms(to: .pdf)
    }
}
