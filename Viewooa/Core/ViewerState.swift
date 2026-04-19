import AppKit
import Foundation
import SwiftUI

enum ZoomMode: Equatable {
    case fit
    case actualSize
    case custom(CGFloat)
}

private enum ViewerZoom {
    static let step: CGFloat = 1.25
    static let minimumScale: CGFloat = 0.05
    static let maximumScale: CGFloat = 8.0
}

@MainActor
final class ViewerState: ObservableObject {
    @Published var index: FolderImageIndex?
    @Published var currentImageURL: URL?
    @Published private(set) var currentResolvedImage: NSImage?
    @Published var zoomMode: ZoomMode = .fit
    @Published var rotationQuarterTurns: Int = 0
    @Published var lastErrorMessage: String?

    private let fileManager: FileManager
    private let preloadQueue: ImagePreloadQueue

    init(
        index: FolderImageIndex? = nil,
        fileManager: FileManager = .default,
        preloadQueue: ImagePreloadQueue = ImagePreloadQueue()
    ) {
        self.index = index
        self.currentImageURL = index.map { $0.imageURLs[$0.currentIndex] }
        self.fileManager = fileManager
        self.preloadQueue = preloadQueue
        self.currentResolvedImage = currentImageURL.flatMap { preloadQueue.image(for: $0) }
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

    func rotateClockwise() {
        rotationQuarterTurns = (rotationQuarterTurns + 1) % 4
    }

    func zoomIn() {
        zoomMode = .custom(clampedZoomScale(currentZoomScale * ViewerZoom.step))
    }

    func zoomOut() {
        zoomMode = .custom(clampedZoomScale(currentZoomScale / ViewerZoom.step))
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
        currentResolvedImage = currentImageURL.flatMap { preloadQueue.image(for: $0) }
        zoomMode = .fit
        rotationQuarterTurns = 0
        lastErrorMessage = nil
        refreshPreloadTargets()
    }

    private func setError(message: String) {
        lastErrorMessage = message
    }

    private var currentZoomScale: CGFloat {
        switch zoomMode {
        case .fit:
            1.0
        case .actualSize:
            1.0
        case let .custom(scale):
            scale
        }
    }

    private func clampedZoomScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, ViewerZoom.minimumScale), ViewerZoom.maximumScale)
    }

    private func refreshPreloadTargets() {
        guard let index else { return }

        let targets = preloadQueue.targetURLs(for: index.imageURLs, currentIndex: index.currentIndex)
        preloadQueue.preload(urls: targets)
    }
}
