import SwiftUI

enum ImageBrowserThumbnailSizing {
    static let minimumSize: CGFloat = 72
    static let defaultSize: CGFloat = 132
    static let maximumSize: CGFloat = 220
    static let step: CGFloat = 18
    static let gridSpacing: CGFloat = 18
    static let minimumMeaningfulStep: CGFloat = 18

    static var range: ClosedRange<CGFloat> {
        minimumSize...maximumSize
    }

    static func clamped(_ size: CGFloat) -> CGFloat {
        min(max(size, minimumSize), maximumSize)
    }
}

struct ThumbnailSizeStepperControl: View {
    @Binding var thumbnailSize: CGFloat
    let isVibrant: Bool
    var availableWidth: CGFloat? = nil
    var onWillChange: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            stepButton(systemImage: "minus", delta: -ImageBrowserThumbnailSizing.step, isDisabled: !canStep(delta: -ImageBrowserThumbnailSizing.step))

            Rectangle()
                .fill(separatorColor)
                .frame(width: 1, height: 15)

            stepButton(systemImage: "plus", delta: ImageBrowserThumbnailSizing.step, isDisabled: !canStep(delta: ImageBrowserThumbnailSizing.step))
        }
        .frame(height: isVibrant ? 30 : 34)
        .background {
            RoundedRectangle(cornerRadius: isVibrant ? 15 : 17, style: .continuous)
                .fill(isVibrant ? VisualInteractionPalette.openBrowserVibrantControlFill : Color.openBrowserControlFill)
        }
        .visualHitArea(RoundedRectangle(cornerRadius: isVibrant ? 15 : 17, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Thumbnail Size")
    }

    private func stepButton(systemImage: String, delta: CGFloat, isDisabled: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous)
        let size = CGSize(width: isVibrant ? 32 : 38, height: isVibrant ? 30 : 34)

        return VisualHoverContentButton(
            accessibilityLabel: delta < 0 ? "Smaller Thumbnails" : "Larger Thumbnails",
            shape: shape,
            hoverEmphasis: isVibrant ? VisualInteractionPalette.vibrantHoverEmphasis : VisualInteractionPalette.plainHoverEmphasis
        ) {
            guard !isDisabled else { return }
            onWillChange?()
            withAnimation(.smooth(duration: 0.18, extraBounce: 0)) {
                thumbnailSize = nextThumbnailSize(delta: delta)
            }
        } label: { isHovering in
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: size.width, height: size.height)
                .foregroundStyle(
                    VisualInteractionPalette.thumbnailStepperIconColor(isVibrant: isVibrant)
                        .color(isSelected: isDisabled, isHovering: false)
                )
                .background(
                    isDisabled
                        ? .clear
                        : VisualInteractionPalette.thumbnailStepperButtonBackground(isVibrant: isVibrant)
                            .color(isHovering: isHovering),
                    in: shape
                )
        }
        .frame(width: size.width, height: size.height)
        .disabled(isDisabled)
    }

    private var separatorColor: Color {
        isVibrant ? VisualInteractionPalette.openBrowserVibrantDivider : VisualInteractionPalette.openBrowserStrongDivider
    }

    private func nextThumbnailSize(delta: CGFloat) -> CGFloat {
        guard let availableWidth, availableWidth > ImageBrowserThumbnailSizing.minimumSize else {
            return ImageBrowserThumbnailSizing.clamped(thumbnailSize + delta)
        }

        let currentColumns = columnCount(for: thumbnailSize, availableWidth: availableWidth)
        let targetColumns = delta > 0 ? max(1, currentColumns - 1) : currentColumns + 1
        let targetSize = (availableWidth - ImageBrowserThumbnailSizing.gridSpacing * CGFloat(max(targetColumns - 1, 0))) / CGFloat(targetColumns)
        let clampedTargetSize = ImageBrowserThumbnailSizing.clamped(targetSize)

        guard abs(clampedTargetSize - thumbnailSize) >= ImageBrowserThumbnailSizing.minimumMeaningfulStep else {
            return thumbnailSize
        }

        return ImageBrowserThumbnailSizing.clamped(clampedTargetSize)
    }

    private func canStep(delta: CGFloat) -> Bool {
        abs(nextThumbnailSize(delta: delta) - thumbnailSize) >= ImageBrowserThumbnailSizing.minimumMeaningfulStep
    }

    private func columnCount(for size: CGFloat, availableWidth: CGFloat) -> Int {
        max(1, Int(floor((availableWidth + ImageBrowserThumbnailSizing.gridSpacing) / (size + ImageBrowserThumbnailSizing.gridSpacing))))
    }
}
