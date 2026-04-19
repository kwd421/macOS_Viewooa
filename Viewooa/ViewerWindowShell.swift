import SwiftUI

struct ViewerWindowShell: View {
    @ObservedObject var viewerState: ViewerState

    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()
            ImageViewerContainerView(viewerState: viewerState)

            if viewerState.currentImageURL == nil {
                placeholderView
            }
        }
        .toolbar {
            Button("Open File...", action: viewerState.presentOpenFilePanel)
            Button("Open Folder...", action: viewerState.presentOpenFolderPanel)
            Button("Previous", action: viewerState.showPreviousImage)
                .disabled(!canShowPreviousImage)
            Button("Next", action: viewerState.showNextImage)
                .disabled(!canShowNextImage)
            Button("Fit") { viewerState.zoomMode = .fit }
                .disabled(viewerState.currentImageURL == nil)
            Button("100%") { viewerState.zoomMode = .actualSize }
                .disabled(viewerState.currentImageURL == nil)
        }
        .alert("Unable to Open Selection", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) {
                viewerState.clearError()
            }
        } message: {
            Text(viewerState.lastErrorMessage ?? "")
        }
    }

    private var statusText: String {
        if let currentImageURL = viewerState.currentImageURL {
            return "Opened \(currentImageURL.lastPathComponent)"
        }

        return "Open a file or folder to begin"
    }

    private var placeholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(statusText)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Open File...", action: viewerState.presentOpenFilePanel)
                Button("Open Folder...", action: viewerState.presentOpenFolderPanel)
            }
        }
    }

    private var canShowPreviousImage: Bool {
        guard let index = viewerState.index else { return false }
        return index.currentIndex > 0
    }

    private var canShowNextImage: Bool {
        guard let index = viewerState.index else { return false }
        return index.currentIndex + 1 < index.imageURLs.count
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewerState.lastErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewerState.clearError()
                }
            }
        )
    }
}
