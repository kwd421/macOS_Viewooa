import AppKit

extension ViewerState {
    func toggleSlideshow() {
        if isSlideshowPlaying {
            stopSlideshow()
        } else {
            startSlideshow()
        }
    }

    func startSlideshow() {
        guard index != nil else { return }
        isSlideshowPlaying = true
        configureSlideshowTask()
    }

    func stopSlideshow() {
        isSlideshowPlaying = false
        slideshowTask?.cancel()
        slideshowTask = nil
    }

    func setSlideshowInterval(_ interval: Double) {
        let clampedInterval = min(max(interval, Self.minimumSlideshowIntervalSeconds), Self.maximumSlideshowIntervalSeconds)
        slideshowIntervalSeconds = (clampedInterval * 2).rounded() / 2
        restartSlideshowIfNeeded()
    }

    var verticalSlideshowScrollSpeed: CGFloat {
        CGFloat(640.0 / slideshowIntervalSeconds)
    }

    var activeVerticalSlideshowScrollSpeed: CGFloat {
        guard isSlideshowPlaying, pageLayout == .verticalStrip else { return 0 }
        return verticalSlideshowScrollSpeed
    }

    func restartSlideshowIfNeeded() {
        guard isSlideshowPlaying else { return }
        configureSlideshowTask()
    }

    func configureSlideshowTask() {
        slideshowTask?.cancel()
        slideshowTask = nil

        guard isSlideshowPlaying, pageLayout != .verticalStrip else { return }

        slideshowTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                try? await Task.sleep(for: .milliseconds(Int(self.slideshowIntervalSeconds * 1000)))
                guard !Task.isCancelled, self.isSlideshowPlaying else { return }

                guard self.canShowNextImage else {
                    self.showTransientNotice("마지막 파일입니다")
                    self.stopSlideshow()
                    return
                }

                self.showNextImage()
            }
        }
    }
}
