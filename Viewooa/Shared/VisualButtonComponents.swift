import SwiftUI

extension View {
    func visualHitArea() -> some View {
        contentShape(Rectangle())
    }

    func visualHoverTracking(
        isHovering: Binding<Bool>,
        animation: Animation = .smooth(duration: 0.12, extraBounce: 0)
    ) -> some View {
        contentShape(Rectangle())
            .animation(animation, value: isHovering.wrappedValue)
            .onHover { newValue in
                isHovering.wrappedValue = newValue
            }
    }
}

struct VisualHoverState<Content: View>: View {
    private let animation: Animation
    private let content: (Bool) -> Content
    @State private var isHovering = false

    init(
        animation: Animation = .smooth(duration: 0.12, extraBounce: 0),
        @ViewBuilder content: @escaping (Bool) -> Content
    ) {
        self.animation = animation
        self.content = content
    }

    var body: some View {
        content(isHovering)
            .visualHoverTracking(isHovering: $isHovering, animation: animation)
    }
}

struct VisualHoveredSelection<ID: Equatable, Content: View>: View {
    let id: ID
    @Binding var hoveredID: ID?
    private let animation: Animation
    private let content: (Bool) -> Content

    init(
        id: ID,
        hoveredID: Binding<ID?>,
        animation: Animation = .smooth(duration: 0.12, extraBounce: 0),
        @ViewBuilder content: @escaping (Bool) -> Content
    ) {
        self.id = id
        self._hoveredID = hoveredID
        self.animation = animation
        self.content = content
    }

    var body: some View {
        content(hoveredID == id)
            .visualHoverTracking(
                isHovering: Binding(
                    get: { hoveredID == id },
                    set: { hoveredID = $0 ? id : nil }
                ),
                animation: animation
            )
    }
}

struct VisualIconButtonLabel: View {
    let systemImage: String
    let size: CGFloat
    let fontSize: CGFloat
    let foregroundColor: Color
    let backgroundColor: Color

    init(
        systemImage: String,
        size: CGFloat,
        fontSize: CGFloat = 15,
        foregroundColor: Color = .primary,
        backgroundColor: Color = .clear
    ) {
        self.systemImage = systemImage
        self.size = size
        self.fontSize = fontSize
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .frame(width: size, height: size)
            .background(backgroundColor, in: Circle())
            .visualHitArea()
    }
}

struct VisualCapsuleIconTextLabel: View {
    let systemImage: String
    let title: String
    let backgroundColor: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))

            Text(title)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(backgroundColor, in: Capsule())
        .visualHitArea()
    }
}
