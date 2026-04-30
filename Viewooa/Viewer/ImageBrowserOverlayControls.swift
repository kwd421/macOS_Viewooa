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
                    style: Self.modeButtonStyle,
                    shape: shape,
                ) {
                        displayMode = mode
                }
            }
        }
        .padding(2)
        .background(VisualInteractionPalette.imageBrowserControlFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .visualHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private static var modeButtonStyle: VisualSelectableIconStyle {
        VisualSelectableIconStyle(
            size: CGSize(width: 32, height: 26),
            foregroundColor: { isSelected, _ in
                isSelected ? .white : VisualInteractionPalette.imageBrowserSecondaryText
            },
            backgroundColor: { isSelected, isHovering in
                VisualInteractionPalette.darkSegmentBackground.color(isSelected: isSelected, isHovering: isHovering)
            }
        )
    }
}
