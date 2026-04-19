import SwiftUI

struct ViewerWindowShell: View {
    @ObservedObject var viewerState: ViewerState

    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()
            ImageViewerContainerView(viewerState: viewerState)

            if let overlayKind {
                overlayCard(for: overlayKind)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Open File...", action: viewerState.presentOpenFilePanel)
                Button("Open Folder...", action: viewerState.presentOpenFolderPanel)
            }

            ToolbarItemGroup {
                Button("Previous", action: viewerState.showPreviousImage)
                    .disabled(!canShowPreviousImage)
                Button("Next", action: viewerState.showNextImage)
                    .disabled(!canShowNextImage)
            }

            ToolbarItemGroup {
                Button("Rotate Right", systemImage: "rotate.right", action: viewerState.rotateClockwise)
                    .disabled(!hasImage)
                Button("Zoom Out", systemImage: "minus.magnifyingglass", action: viewerState.zoomOut)
                    .disabled(!hasImage)
                Button("Zoom In", systemImage: "plus.magnifyingglass", action: viewerState.zoomIn)
                    .disabled(!hasImage)
                Button("Fit") { viewerState.zoomMode = .fit }
                    .disabled(!hasImage)
                Button("100%") { viewerState.zoomMode = .actualSize }
                    .disabled(!hasImage)
            }
        }
    }

    private var statusText: String {
        if let currentImageURL = viewerState.currentImageURL {
            return "Opened \(currentImageURL.lastPathComponent)"
        }

        return "Open a file or folder to begin"
    }

    @ViewBuilder
    private func overlayCard(for kind: OverlayKind) -> some View {
        VStack(spacing: 12) {
            Image(systemName: kind.symbolName)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.secondary)
            Text(kind.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(kind.message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Open File...", action: viewerState.presentOpenFilePanel)
                Button("Open Folder...", action: viewerState.presentOpenFolderPanel)

                if case .error = kind {
                    Button("Dismiss", action: viewerState.clearError)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        }
        .frame(maxWidth: 360)
        .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
    }

    private var canShowPreviousImage: Bool {
        guard let index = viewerState.index else { return false }
        return index.currentIndex > 0
    }

    private var canShowNextImage: Bool {
        guard let index = viewerState.index else { return false }
        return index.currentIndex + 1 < index.imageURLs.count
    }

    private var hasImage: Bool {
        viewerState.currentImageURL != nil
    }

    private var overlayKind: OverlayKind? {
        if let errorMessage = viewerState.lastErrorMessage {
            return .error(message: errorMessage)
        }

        guard !hasImage else { return nil }
        return .empty
    }
}

private enum OverlayKind {
    case empty
    case error(message: String)

    var symbolName: String {
        switch self {
        case .empty:
            "photo"
        case .error:
            "exclamationmark.triangle"
        }
    }

    var title: String {
        switch self {
        case .empty:
            "Open an Image to Begin"
        case .error:
            "Unable to Open Selection"
        }
    }

    var message: String {
        switch self {
        case .empty:
            "Use Open File or Open Folder to start browsing images."
        case let .error(message):
            message
        }
    }
}
