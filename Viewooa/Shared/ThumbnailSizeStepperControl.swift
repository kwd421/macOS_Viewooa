import SwiftUI

struct ThumbnailSizeStepperControl: View {
    @Binding var thumbnailSize: CGFloat
    let isVibrant: Bool
    var availableWidth: CGFloat? = nil
    var onWillChange: (() -> Void)? = nil

    private let range: ClosedRange<CGFloat> = 72...220
    private let step: CGFloat = 18
    private let gridSpacing: CGFloat = 18
    private let minimumMeaningfulStep: CGFloat = 18
    var body: some View {
        HStack(spacing: 0) {
            stepButton(systemImage: "minus", delta: -step, isDisabled: !canStep(delta: -step))

            Rectangle()
                .fill(separatorColor)
                .frame(width: 1, height: 15)

            stepButton(systemImage: "plus", delta: step, isDisabled: !canStep(delta: step))
        }
        .frame(height: isVibrant ? 30 : 34)
        .background {
            RoundedRectangle(cornerRadius: isVibrant ? 15 : 17, style: .continuous)
                .fill(isVibrant ? Color.white.opacity(0.10) : Color.openBrowserControlFill)
        }
        .visualHitArea()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Thumbnail Size")
    }

    private func stepButton(systemImage: String, delta: CGFloat, isDisabled: Bool) -> some View {
        VisualHoverState { isHovering in
            Button {
                onWillChange?()
                withAnimation(.smooth(duration: 0.18, extraBounce: 0)) {
                    thumbnailSize = nextThumbnailSize(delta: delta)
                }
            } label: {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: isVibrant ? 32 : 38, height: isVibrant ? 30 : 34)
                    .foregroundStyle(Self.buttonColor(isDisabled: isDisabled, isVibrant: isVibrant))
                    .background(
                        Self.stepButtonBackground(isDisabled: isDisabled, isHovering: isHovering, isVibrant: isVibrant),
                        in: RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous)
                    )
                    .visualHitArea()
            }
            .frame(width: isVibrant ? 32 : 38, height: isVibrant ? 30 : 34)
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .accessibilityLabel(delta < 0 ? "Smaller Thumbnails" : "Larger Thumbnails")
        }
        .frame(width: isVibrant ? 32 : 38, height: isVibrant ? 30 : 34)
    }

    private var separatorColor: Color {
        isVibrant ? Color.white.opacity(0.18) : Color.openBrowserSeparator.opacity(0.65)
    }

    private static func buttonColor(isDisabled: Bool, isVibrant: Bool) -> Color {
        if isDisabled {
            return isVibrant ? Color.white.opacity(0.24) : Color.secondary.opacity(0.28)
        }
        return isVibrant ? Color.white.opacity(0.78) : Color.secondary
    }

    private static func stepButtonBackground(isDisabled: Bool, isHovering: Bool, isVibrant: Bool) -> Color {
        guard !isDisabled, isHovering else { return .clear }
        return isVibrant ? Color.white.opacity(0.12) : Color.primary.opacity(0.07)
    }

    private func nextThumbnailSize(delta: CGFloat) -> CGFloat {
        guard let availableWidth, availableWidth > range.lowerBound else {
            return clamped(thumbnailSize + delta)
        }

        let currentColumns = columnCount(for: thumbnailSize, availableWidth: availableWidth)
        let targetColumns = delta > 0 ? max(1, currentColumns - 1) : currentColumns + 1
        let targetSize = (availableWidth - gridSpacing * CGFloat(max(targetColumns - 1, 0))) / CGFloat(targetColumns)
        let clampedTargetSize = clamped(targetSize)

        guard abs(clampedTargetSize - thumbnailSize) >= minimumMeaningfulStep else {
            return thumbnailSize
        }

        return clampedTargetSize
    }

    private func canStep(delta: CGFloat) -> Bool {
        abs(nextThumbnailSize(delta: delta) - thumbnailSize) >= minimumMeaningfulStep
    }

    private func columnCount(for size: CGFloat, availableWidth: CGFloat) -> Int {
        max(1, Int(floor((availableWidth + gridSpacing) / (size + gridSpacing))))
    }

    private func clamped(_ size: CGFloat) -> CGFloat {
        min(max(size, range.lowerBound), range.upperBound)
    }
}
