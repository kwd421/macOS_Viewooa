import SwiftUI

struct ImageBrowserViewModeControl: View {
    @Binding var displayMode: ImageBrowserDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImageBrowserDisplayMode.allCases) { mode in
                VisualHoverState { isHovering in
                    Button {
                        displayMode = mode
                    } label: {
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 32, height: 26)
                            .foregroundStyle(Self.foregroundColor(isSelected: displayMode == mode))
                            .background(
                                Self.backgroundColor(isSelected: displayMode == mode, isHovering: isHovering),
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                            .visualHitArea()
                    }
                    .frame(width: 32, height: 26)
                    .visualHitArea()
                    .buttonStyle(.plain)
                    .accessibilityLabel(mode.title)
                }
                .frame(width: 32, height: 26)
            }
        }
        .padding(2)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private static func foregroundColor(isSelected: Bool) -> Color {
        isSelected ? .white : .white.opacity(0.58)
    }

    private static func backgroundColor(isSelected: Bool, isHovering: Bool) -> Color {
        if isSelected {
            return .white.opacity(isHovering ? 0.28 : 0.18)
        }

        return isHovering ? .white.opacity(0.12) : .clear
    }
}
