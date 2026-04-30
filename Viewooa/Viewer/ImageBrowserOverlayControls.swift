import SwiftUI

struct ImageBrowserViewModeControl: View {
    @Binding var displayMode: ImageBrowserDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImageBrowserDisplayMode.allCases) { mode in
                let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)

                VisualHoverState(shape: shape) { isHovering in
                    Button {
                        displayMode = mode
                    } label: {
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 32, height: 26)
                            .foregroundStyle(Self.foregroundColor(isSelected: displayMode == mode))
                            .background(
                                Self.backgroundColor.color(isSelected: displayMode == mode, isHovering: isHovering),
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                            .visualHitArea(shape)
                    }
                    .frame(width: 32, height: 26)
                    .visualHitArea(shape)
                    .buttonStyle(.plain)
                    .accessibilityLabel(mode.title)
                }
                .frame(width: 32, height: 26)
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
