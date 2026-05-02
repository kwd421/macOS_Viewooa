import SwiftUI

struct VisualCapsuleIconTextLabel: View {
    let systemImage: String
    let title: String
    var titleWidth: CGFloat?
    let backgroundColor: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))

            Text(title)
                .lineLimit(1)
                .frame(width: titleWidth, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(backgroundColor, in: Capsule())
        .visualHitArea(Capsule())
    }
}
