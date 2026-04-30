import SwiftUI

struct ImageBrowserViewModeControl: View {
    @Binding var displayMode: ImageBrowserDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImageBrowserDisplayMode.allCases) { mode in
                let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)

                VisualSelectableIconButton(
                    accessibilityLabel: mode.title,
                    systemImage: mode.systemImage,
                    isSelected: displayMode == mode,
                    size: CGSize(width: 32, height: 26),
                    shape: shape,
                    foregroundColor: { isSelected, _ in
                        Self.foregroundColor(isSelected: isSelected)
                    },
                    backgroundColor: { isSelected, isHovering in
                        Self.backgroundColor.color(isSelected: isSelected, isHovering: isHovering)
                    }
                ) {
                        displayMode = mode
                }
            }
        }
        .padding(2)
        .background(VisualInteractionPalette.imageBrowserControlFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .visualHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private static func foregroundColor(isSelected: Bool) -> Color {
        isSelected ? .white : VisualInteractionPalette.imageBrowserSecondaryText
    }

    private static let backgroundColor = VisualInteractionPalette.darkSegmentBackground
}
