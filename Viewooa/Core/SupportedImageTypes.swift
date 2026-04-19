import Foundation
import UniformTypeIdentifiers

enum SupportedImageTypes {
    static func isSupported(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return false
        }

        return type.conforms(to: .image)
    }
}
