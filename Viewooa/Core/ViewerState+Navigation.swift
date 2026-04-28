import Foundation

extension ViewerState {
    func showNextImage() {
        guard let index else { return }
        let nextIndex = ViewerNavigationResolver.nextIndex(
            currentIndex: index.currentIndex,
            itemCount: index.imageURLs.count,
            layout: pageLayout,
            coverModeEnabled: isCoverModeEnabled
        )
        guard nextIndex < index.imageURLs.count, nextIndex != index.currentIndex else {
            showTransientNotice("마지막 파일입니다")
            return
        }
        if isViewingPDF {
            applyPDFPage(at: nextIndex, hidesNavigationCount: false)
        } else {
            apply(index: FolderImageIndex(imageURLs: index.imageURLs, currentIndex: nextIndex), hidesNavigationCount: false)
        }
    }

    func showPreviousImage() {
        guard let index else { return }
        let previousIndex = ViewerNavigationResolver.previousIndex(
            currentIndex: index.currentIndex,
            itemCount: index.imageURLs.count,
            layout: pageLayout,
            coverModeEnabled: isCoverModeEnabled
        )
        guard previousIndex >= 0, previousIndex != index.currentIndex else {
            showTransientNotice("첫번째 파일입니다")
            return
        }
        if isViewingPDF {
            applyPDFPage(at: previousIndex, hidesNavigationCount: false)
        } else {
            apply(index: FolderImageIndex(imageURLs: index.imageURLs, currentIndex: previousIndex), hidesNavigationCount: false)
        }
    }

    func showNextImageFromDirectionalInput() {
        guard isEntireImageVisible else { return }
        showNextImage()
    }

    func showPreviousImageFromDirectionalInput() {
        guard isEntireImageVisible else { return }
        showPreviousImage()
    }

    func showNextImageFromNavigationShortcut() {
        beginNavigationHoldIndicator()
        showNextImage()
        endNavigationHoldIndicator()
    }

    func showPreviousImageFromNavigationShortcut() {
        beginNavigationHoldIndicator()
        showPreviousImage()
        endNavigationHoldIndicator()
    }

    func beginNavigationHoldIndicator() {
        guard index != nil else { return }
        navigationCountDismissTask?.cancel()
        isNavigationCountVisible = true
    }

    func endNavigationHoldIndicator() {
        scheduleNavigationCountDismissal()
    }

    func scheduleNavigationCountDismissal() {
        navigationCountDismissTask?.cancel()
        navigationCountDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            isNavigationCountVisible = false
        }
    }

    func hideNavigationCountImmediately() {
        navigationCountDismissTask?.cancel()
        navigationCountDismissTask = nil
        isNavigationCountVisible = false
    }
}
