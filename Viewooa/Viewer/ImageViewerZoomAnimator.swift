import AppKit
import QuartzCore

@MainActor
final class ImageViewerZoomAnimator {
    typealias AnchoredZoomTarget = (documentPoint: NSPoint, origin: NSPoint)

    private let scrollView: NavigationAwareScrollView
    private var transitionID = 0
    private var animationTask: Task<Void, Never>?
    private(set) var isApplyingProgrammaticMagnification = false

    init(scrollView: NavigationAwareScrollView) {
        self.scrollView = scrollView
    }

    deinit {
        animationTask?.cancel()
    }

    func performProgrammaticMagnification(_ body: () -> Void) {
        isApplyingProgrammaticMagnification = true
        body()
        isApplyingProgrammaticMagnification = false
    }

    func applyProgrammaticMagnification(
        _ magnification: CGFloat,
        centeredAt documentPoint: NSPoint,
        finalOrigin: NSPoint? = nil,
        canAnimateInWindow: Bool,
        updatePresentation: @MainActor @escaping (CGFloat) -> Void
    ) {
        transitionID += 1
        let currentTransitionID = transitionID
        animationTask?.cancel()

        let startMagnification = scrollView.magnification
        let startOrigin = scrollView.contentView.bounds.origin
        let shouldAnimate = shouldAnimateZoomTransition(
            to: magnification,
            finalOrigin: finalOrigin,
            canAnimateInWindow: canAnimateInWindow
        )

        isApplyingProgrammaticMagnification = true
        guard shouldAnimate else {
            updatePresentation(magnification)
            finishProgrammaticMagnification(magnification, centeredAt: documentPoint, finalOrigin: finalOrigin)
            isApplyingProgrammaticMagnification = false
            return
        }

        animationTask = Task { @MainActor [weak self] in
            guard let self else { return }

            let startTime = CACurrentMediaTime()
            while !Task.isCancelled {
                let elapsed = CACurrentMediaTime() - startTime
                let rawProgress = min(max(elapsed / Self.zoomAnimationDuration, 0), 1)
                let progress = Self.zoomAnimationProgress(CGFloat(rawProgress))
                let currentMagnification = Self.interpolated(
                    from: startMagnification,
                    to: magnification,
                    progress: progress
                )
                let currentOrigin = finalOrigin.map {
                    Self.interpolated(from: startOrigin, to: $0, progress: progress)
                }

                updatePresentation(currentMagnification)
                self.finishProgrammaticMagnification(
                    currentMagnification,
                    centeredAt: documentPoint,
                    finalOrigin: currentOrigin
                )

                if rawProgress >= 1 {
                    break
                }

                try? await Task.sleep(nanoseconds: Self.zoomAnimationFrameIntervalNanoseconds)
            }

            guard !Task.isCancelled,
                  self.transitionID == currentTransitionID else {
                return
            }

            updatePresentation(magnification)
            self.finishProgrammaticMagnification(magnification, centeredAt: documentPoint, finalOrigin: finalOrigin)
            self.isApplyingProgrammaticMagnification = false
        }
    }

    func applyAnchoredProgrammaticMagnification(
        _ magnification: CGFloat,
        contentOffset: NSPoint,
        anchorUnitPoint: NSPoint,
        canAnimateInWindow: Bool,
        updatePresentation: @MainActor @escaping (CGFloat) -> Void,
        targetForMagnification: @MainActor @escaping (CGFloat) -> AnchoredZoomTarget
    ) {
        let clampedScale = min(max(magnification, scrollView.minMagnification), scrollView.maxMagnification)
        transitionID += 1
        let currentTransitionID = transitionID
        animationTask?.cancel()

        let startMagnification = scrollView.magnification
        let shouldAnimate = shouldAnimateZoomTransition(
            to: clampedScale,
            finalOrigin: nil,
            canAnimateInWindow: canAnimateInWindow
        )

        isApplyingProgrammaticMagnification = true
        guard shouldAnimate else {
            updatePresentation(clampedScale)
            let target = targetForMagnification(clampedScale)
            finishProgrammaticMagnification(
                clampedScale,
                centeredAt: target.documentPoint,
                finalOrigin: target.origin
            )
            isApplyingProgrammaticMagnification = false
            return
        }

        animationTask = Task { @MainActor [weak self] in
            guard let self else { return }

            let startTime = CACurrentMediaTime()
            while !Task.isCancelled {
                let elapsed = CACurrentMediaTime() - startTime
                let rawProgress = min(max(elapsed / Self.zoomAnimationDuration, 0), 1)
                let progress = Self.zoomAnimationProgress(CGFloat(rawProgress))
                let currentMagnification = Self.interpolated(
                    from: startMagnification,
                    to: clampedScale,
                    progress: progress
                )

                updatePresentation(currentMagnification)
                let target = targetForMagnification(currentMagnification)
                self.finishProgrammaticMagnification(
                    currentMagnification,
                    centeredAt: target.documentPoint,
                    finalOrigin: target.origin
                )

                if rawProgress >= 1 {
                    break
                }

                try? await Task.sleep(nanoseconds: Self.zoomAnimationFrameIntervalNanoseconds)
            }

            guard !Task.isCancelled,
                  self.transitionID == currentTransitionID else {
                return
            }

            updatePresentation(clampedScale)
            let target = targetForMagnification(clampedScale)
            self.finishProgrammaticMagnification(
                clampedScale,
                centeredAt: target.documentPoint,
                finalOrigin: target.origin
            )
            self.isApplyingProgrammaticMagnification = false
        }
    }

    private func finishProgrammaticMagnification(
        _ magnification: CGFloat,
        centeredAt documentPoint: NSPoint,
        finalOrigin: NSPoint?
    ) {
        if abs(scrollView.magnification - magnification) > 0.0001 {
            if finalOrigin != nil {
                scrollView.magnification = magnification
            } else {
                scrollView.setMagnification(magnification, centeredAt: documentPoint)
            }
        }
        if let finalOrigin {
            scrollView.contentView.scroll(to: finalOrigin)
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
    }

    private func shouldAnimateZoomTransition(
        to magnification: CGFloat,
        finalOrigin: NSPoint?,
        canAnimateInWindow: Bool
    ) -> Bool {
        guard canAnimateInWindow,
              !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            return false
        }

        if abs(scrollView.magnification - magnification) > 0.0001 {
            return true
        }

        guard let finalOrigin else { return false }
        let currentOrigin = scrollView.contentView.bounds.origin
        return abs(currentOrigin.x - finalOrigin.x) > 0.0001
            || abs(currentOrigin.y - finalOrigin.y) > 0.0001
    }

    private static let zoomAnimationDuration: TimeInterval = 0.24
    private static let zoomAnimationFrameIntervalNanoseconds: UInt64 = 16_000_000

    private static func zoomAnimationProgress(_ progress: CGFloat) -> CGFloat {
        let clampedProgress = min(max(progress, 0), 1)
        return 1 - pow(1 - clampedProgress, 3)
    }

    private static func interpolated(from start: CGFloat, to end: CGFloat, progress: CGFloat) -> CGFloat {
        start + ((end - start) * progress)
    }

    private static func interpolated(from start: NSPoint, to end: NSPoint, progress: CGFloat) -> NSPoint {
        NSPoint(
            x: interpolated(from: start.x, to: end.x, progress: progress),
            y: interpolated(from: start.y, to: end.y, progress: progress)
        )
    }
}
