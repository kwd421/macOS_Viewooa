import AppKit
import SwiftUI

struct ViewerWindowShell: View {
    @StateObject private var viewerState = ViewerState()

    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text(statusText)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button("Open File...", action: openFile)
                    Button("Open Folder...", action: openFolder)
                }

                if let currentImageURL = viewerState.currentImageURL {
                    Text(currentImageURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    HStack(spacing: 12) {
                        Button("Previous", action: viewerState.showPreviousImage)
                            .disabled(!canShowPreviousImage)
                        Button("Next", action: viewerState.showNextImage)
                            .disabled(!canShowNextImage)
                    }
                }
            }
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

    private func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK, let url = panel.url {
            viewerState.openFile(at: url)
        }
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            viewerState.openFolder(at: url)
        }
    }
}
