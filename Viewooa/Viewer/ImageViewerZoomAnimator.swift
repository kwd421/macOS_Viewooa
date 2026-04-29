import AppKit

@MainActor
final class ImageViewerZoomAnimator {
    typealias AnchoredZoomTarget = (documentPoint: NSPoint, origin: NSPoint)

    private let scrollView: NavigationAwareScrollView
    private var transitionID = 0
    private var pendingTransitionCompletion: (() -> Void)?
    private(set) var isApplyingProgrammaticMagnification = false

    init(scrollView: NavigationAwareScrollView) {
        self.scrollView = scrollView
    }

    func performProgrammaticMagnification(_ body: () -> Void) {
        isApplyingProgrammaticMagnification = true
        body()
        finishTransition()
    }

    func runAfterCurrentTransition(_ action: @escaping () -> Void) {
        guard isApplyingProgrammaticMagnification else {
            action()
            return
        }

        pendingTransitionCompletion = action
    }

    func applyProgrammaticMagnification(
        _ magnification: CGFloat,
        centeredAt documentPoint: NSPoint,
        finalOrigin: NSPoint? = nil,
        canAnimateInWindow: Bool,
        originForMagnification: (@MainActor (CGFloat) -> NSPoint)? = nil,
        updatePresentation: @MainActor @escaping (CGFloat) -> Void
    ) {
        transitionID += 1
        isApplyingProgrammaticMagnification = true
        updatePresentation(magnification)
        finishProgrammaticMagnification(magnification, centeredAt: documentPoint, finalOrigin: finalOrigin)
        finishTransition()
    }

    private func finishTransition() {
        isApplyingProgrammaticMagnification = false
        let completion = pendingTransitionCompletion
        pendingTransitionCompletion = nil
        completion?()
    }

    private func finishProgrammaticMagnification(
        _ magnification: CGFloat,
        centeredAt documentPoint: NSPoint,
        finalOrigin: NSPoint?
    ) {
        if abs(scrollView.magnification - magnification) > 0.0001 {
            scrollView.setMagnification(magnification, centeredAt: documentPoint)
        }
        if let finalOrigin {
            scrollView.contentView.scroll(to: clampedOrigin(finalOrigin, magnification: magnification))
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
    }

    private func clampedOrigin(_ origin: NSPoint, magnification: CGFloat) -> NSPoint {
        guard let documentView = scrollView.documentView,
              magnification > 0 else {
            return origin
        }

        let viewportSize = scrollView.bounds.size.width > 0 && scrollView.bounds.size.height > 0
            ? scrollView.bounds.size
            : scrollView.contentSize
        let visibleWidth = viewportSize.width / magnification
        let visibleHeight = viewportSize.height / magnification
        let maximumX = max(0, documentView.bounds.width - visibleWidth)
        let maximumY = max(0, documentView.bounds.height - visibleHeight)

        return NSPoint(
            x: min(max(origin.x, 0), maximumX),
            y: min(max(origin.y, 0), maximumY)
        )
    }

}
