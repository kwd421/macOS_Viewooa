import AppKit
import Foundation
import SwiftUI

enum ZoomMode: Equatable {
    case fit
    case actualSize
    case custom(CGFloat)
}

@MainActor
final class ViewerState: ObservableObject {
    @Published var index: FolderImageIndex?
    @Published var currentImageURL: URL?
    @Published var zoomMode: ZoomMode = .fit
    @Published var rotationQuarterTurns: Int = 0
    @Published var lastErrorMessage: String?

    private let fileManager: FileManager

    init(index: FolderImageIndex? = nil, fileManager: FileManager = .default) {
        self.index = index
        self.currentImageURL = index.map { $0.imageURLs[$0.currentIndex] }
        self.fileManager = fileManager
    }

    func openFile(at fileURL: URL) {
        guard SupportedImageTypes.isSupported(fileURL) else {
            setError(message: "The selected file is not a supported image.")
            return
        }

        let folderURL = fileURL.deletingLastPathComponent()

        do {
            let imageURLs = try imageURLs(in: folderURL)

            guard let currentIndex = FolderImageIndex.currentIndex(for: fileURL, in: imageURLs) else {
                setError(message: "The selected image could not be found in its folder.")
                return
            }

            apply(index: FolderImageIndex(imageURLs: imageURLs, currentIndex: currentIndex))
        } catch {
            setError(message: error.localizedDescription)
        }
    }

    func openFolder(at folderURL: URL) {
        do {
            let imageURLs = try imageURLs(in: folderURL)

            guard !imageURLs.isEmpty else {
                setError(message: "The selected folder does not contain supported images.")
                return
            }

            apply(index: FolderImageIndex(imageURLs: imageURLs, currentIndex: 0))
        } catch {
            setError(message: error.localizedDescription)
        }
    }

    func presentOpenFilePanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK, let url = panel.url {
            openFile(at: url)
        }
    }

    func presentOpenFolderPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            openFolder(at: url)
        }
    }

    func showNextImage() {
        guard let index, index.currentIndex + 1 < index.imageURLs.count else { return }
        apply(index: FolderImageIndex(imageURLs: index.imageURLs, currentIndex: index.currentIndex + 1))
    }

    func showPreviousImage() {
        guard let index, index.currentIndex > 0 else { return }
        apply(index: FolderImageIndex(imageURLs: index.imageURLs, currentIndex: index.currentIndex - 1))
    }

    func clearError() {
        lastErrorMessage = nil
    }

    private func imageURLs(in folderURL: URL) throws -> [URL] {
        let contents = try fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return FolderImageIndex.sortedImageURLs(from: contents)
    }

    private func apply(index: FolderImageIndex) {
        self.index = index
        currentImageURL = index.imageURLs[index.currentIndex]
        zoomMode = .fit
        rotationQuarterTurns = 0
        lastErrorMessage = nil
    }

    private func setError(message: String) {
        lastErrorMessage = message
    }
}
