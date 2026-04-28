import SwiftUI

struct ImageBrowserViewModeControl: View {
    @Binding var displayMode: ImageBrowserDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImageBrowserDisplayMode.allCases) { mode in
                Button {
                    displayMode = mode
                } label: {
                    Image(systemName: mode.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 32, height: 26)
                        .foregroundStyle(displayMode == mode ? .white : .white.opacity(0.58))
                        .background(
                            displayMode == mode ? .white.opacity(0.18) : .clear,
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.title)
            }
        }
        .padding(2)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
