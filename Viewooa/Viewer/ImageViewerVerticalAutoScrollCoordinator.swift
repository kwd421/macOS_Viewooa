import AppKit

@MainActor
final class ImageViewerVerticalAutoScrollCoordinator {
    private var task: Task<Void, Never>?
    private var screenSpeed: CGFloat = 0
    private var isEnabled = false
    private var lastStepDate: Date?

    deinit {
        task?.cancel()
    }

    func stop() {
        cancelTask()
        screenSpeed = 0
        isEnabled = false
    }

    func setScreenSpeed(
        _ requestedScreenSpeed: CGFloat,
        isEnabled: Bool,
        onStep: @escaping (_ elapsed: TimeInterval, _ screenSpeed: CGFloat) -> Bool,
        onReachedEnd: @escaping () -> Void
    ) {
        let clampedSpeed = max(requestedScreenSpeed, 0)
        guard abs(screenSpeed - clampedSpeed) > 0.01 || self.isEnabled != isEnabled else {
            return
        }

        screenSpeed = clampedSpeed
        self.isEnabled = isEnabled
        restartTask(onStep: onStep, onReachedEnd: onReachedEnd)
    }

    private func restartTask(
        onStep: @escaping (_ elapsed: TimeInterval, _ screenSpeed: CGFloat) -> Bool,
        onReachedEnd: @escaping () -> Void
    ) {
        cancelTask()
        guard screenSpeed > 0, isEnabled else { return }

        task = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                let now = Date()
                let elapsed = self.lastStepDate.map { now.timeIntervalSince($0) } ?? (1.0 / 60.0)
                self.lastStepDate = now

                guard onStep(elapsed, self.screenSpeed) else {
                    self.stop()
                    onReachedEnd()
                    return
                }

                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func cancelTask() {
        task?.cancel()
        task = nil
        lastStepDate = nil
    }
}
