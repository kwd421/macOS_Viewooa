import Foundation

extension ViewerState {
    var hasAnimatedImageFrames: Bool {
        animatedImageFrameCount > 1
    }

    var animatedImageFrameText: String? {
        guard hasAnimatedImageFrames else { return nil }
        return "\(animatedImageFrameIndex + 1) / \(animatedImageFrameCount)"
    }

    func loadAnimatedImageIfNeeded() {
        guard let currentImageURL,
              AnimatedImageLoader.isAnimatedGIF(currentImageURL) else {
            resetAnimatedImageState()
            return
        }

        let frames = AnimatedImageLoader.loadGIFFrames(at: currentImageURL)
        guard frames.count > 1 else {
            resetAnimatedImageState()
            return
        }

        animatedImagePlaybackTask?.cancel()
        animatedImageFrames = frames
        animatedImageFrameIndex = 0
        animatedImageFrameCount = frames.count
        currentResolvedImage = frames[0].image
        imageRevision += 1
        startAnimatedImagePlayback()
    }

    func toggleAnimatedImagePlayback() {
        if isAnimatedImagePlaying {
            stopAnimatedImagePlayback()
        } else {
            startAnimatedImagePlayback()
        }
    }

    func showPreviousAnimatedImageFrame() {
        stopAnimatedImagePlayback()
        stepAnimatedImageFrame(by: -1)
    }

    func showNextAnimatedImageFrame() {
        stopAnimatedImagePlayback()
        stepAnimatedImageFrame(by: 1)
    }

    func resetAnimatedImageState() {
        animatedImagePlaybackTask?.cancel()
        animatedImageFrames = []
        animatedImageFrameIndex = 0
        animatedImageFrameCount = 0
        isAnimatedImagePlaying = false
    }

    private func startAnimatedImagePlayback() {
        guard hasAnimatedImageFrames else { return }

        animatedImagePlaybackTask?.cancel()
        isAnimatedImagePlaying = true
        animatedImagePlaybackTask = Task { @MainActor in
            while !Task.isCancelled {
                let frameDuration = animatedImageFrames[animatedImageFrameIndex].duration
                try? await Task.sleep(for: .seconds(frameDuration))
                guard !Task.isCancelled else { return }
                stepAnimatedImageFrame(by: 1)
            }
        }
    }

    private func stopAnimatedImagePlayback() {
        animatedImagePlaybackTask?.cancel()
        isAnimatedImagePlaying = false
    }

    private func stepAnimatedImageFrame(by offset: Int) {
        guard hasAnimatedImageFrames else { return }

        let count = animatedImageFrames.count
        let index = (animatedImageFrameIndex + offset + count) % count
        animatedImageFrameIndex = index
        currentResolvedImage = animatedImageFrames[index].image
        imageRevision += 1
    }
}
