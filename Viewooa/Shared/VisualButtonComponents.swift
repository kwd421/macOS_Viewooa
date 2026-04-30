import SwiftUI

struct VisualInteractionColorStyle {
    let normal: Color
    let hover: Color
    let selected: Color
    let selectedHover: Color

    func color(isSelected: Bool, isHovering: Bool) -> Color {
        switch (isSelected, isHovering) {
        case (true, true):
            return selectedHover
        case (true, false):
            return selected
        case (false, true):
            return hover
        case (false, false):
            return normal
        }
    }
}

struct VisualHoverColorStyle {
    let normal: Color
    let hover: Color

    func color(isHovering: Bool) -> Color {
        isHovering ? hover : normal
    }
}

struct VisualPressColorStyle {
    let normal: Color
    let hover: Color
    let pressed: Color

    func color(isHovering: Bool, isPressed: Bool = false) -> Color {
        if isPressed {
            return pressed
        }

        return isHovering ? hover : normal
    }
}

extension View {
    func visualHitArea<S: Shape>(_ shape: S) -> some View {
        contentShape(shape)
    }

    func visualHoverTracking(
        isHovering: Binding<Bool>,
        shape: AnyShape = AnyShape(Rectangle()),
        animation: Animation = .smooth(duration: 0.12, extraBounce: 0)
    ) -> some View {
        modifier(VisualHoverTrackingModifier(isHovering: isHovering, shape: shape, animation: animation))
    }

    func visualHoverTracking<S: Shape>(
        isHovering: Binding<Bool>,
        shape: S,
        animation: Animation = .smooth(duration: 0.12, extraBounce: 0)
    ) -> some View {
        visualHoverTracking(isHovering: isHovering, shape: AnyShape(shape), animation: animation)
    }
}

private struct VisualHoverTrackingModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isHovering: Bool
    let shape: AnyShape
    let animation: Animation

    func body(content: Content) -> some View {
        content
            .contentShape(shape)
            .animation(reduceMotion ? nil : animation, value: isHovering)
            .onHover { newValue in
                isHovering = newValue
            }
    }
}

struct VisualHoverState<Content: View>: View {
    private let shape: AnyShape
    private let animation: Animation
    private let content: (Bool) -> Content
    @State private var isHovering = false

    init(
        shape: AnyShape,
        animation: Animation = .smooth(duration: 0.12, extraBounce: 0),
        @ViewBuilder content: @escaping (Bool) -> Content
    ) {
        self.shape = shape
        self.animation = animation
        self.content = content
    }

    init<S: Shape>(
        shape: S,
        animation: Animation = .smooth(duration: 0.12, extraBounce: 0),
        @ViewBuilder content: @escaping (Bool) -> Content
    ) {
        self.shape = AnyShape(shape)
        self.animation = animation
        self.content = content
    }

    var body: some View {
        content(isHovering)
            .visualHoverTracking(isHovering: $isHovering, shape: shape, animation: animation)
    }
}

struct VisualHoveredSelection<ID: Equatable, Content: View>: View {
    let id: ID
    @Binding var hoveredID: ID?
    private let shape: AnyShape
    private let animation: Animation
    private let content: (Bool) -> Content

    init(
        id: ID,
        hoveredID: Binding<ID?>,
        shape: AnyShape,
        animation: Animation = .smooth(duration: 0.12, extraBounce: 0),
        @ViewBuilder content: @escaping (Bool) -> Content
    ) {
        self.id = id
        self._hoveredID = hoveredID
        self.shape = shape
        self.animation = animation
        self.content = content
    }

    init<S: Shape>(
        id: ID,
        hoveredID: Binding<ID?>,
        shape: S,
        animation: Animation = .smooth(duration: 0.12, extraBounce: 0),
        @ViewBuilder content: @escaping (Bool) -> Content
    ) {
        self.id = id
        self._hoveredID = hoveredID
        self.shape = AnyShape(shape)
        self.animation = animation
        self.content = content
    }

    var body: some View {
        content(hoveredID == id)
            .visualHoverTracking(
                isHovering: Binding(
                    get: { hoveredID == id },
                    set: { isHovering in
                        if isHovering {
                            hoveredID = id
                        } else if hoveredID == id {
                            hoveredID = nil
                        }
                    }
                ),
                shape: shape,
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
            .visualHitArea(Circle())
    }
}

struct VisualIconActionButton<ShapeType: Shape>: View {
    let accessibilityLabel: String
    let systemImage: String
    let size: CGSize
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let shape: ShapeType
    let foregroundColor: (Bool) -> Color
    let backgroundColor: (Bool) -> Color
    let overlay: ((Bool) -> AnyView)?
    let action: () -> Void

    init(
        accessibilityLabel: String,
        systemImage: String,
        size: CGSize,
        fontSize: CGFloat = 15,
        fontWeight: Font.Weight = .semibold,
        shape: ShapeType,
        foregroundColor: @escaping (Bool) -> Color,
        backgroundColor: @escaping (Bool) -> Color,
        overlay: ((Bool) -> AnyView)? = nil,
        action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.systemImage = systemImage
        self.size = size
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.shape = shape
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.overlay = overlay
        self.action = action
    }

    init(
        accessibilityLabel: String,
        systemImage: String,
        size: CGFloat,
        fontSize: CGFloat = 15,
        fontWeight: Font.Weight = .semibold,
        shape: ShapeType,
        foregroundColor: @escaping (Bool) -> Color,
        backgroundColor: @escaping (Bool) -> Color,
        overlay: ((Bool) -> AnyView)? = nil,
        action: @escaping () -> Void
    ) {
        self.init(
            accessibilityLabel: accessibilityLabel,
            systemImage: systemImage,
            size: CGSize(width: size, height: size),
            fontSize: fontSize,
            fontWeight: fontWeight,
            shape: shape,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            overlay: overlay,
            action: action
        )
    }

    var body: some View {
        VisualHoverState(shape: shape) { isHovering in
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundStyle(foregroundColor(isHovering))
                    .frame(width: size.width, height: size.height)
                    .background(backgroundColor(isHovering), in: shape)
                    .overlay {
                        overlay?(isHovering)
                    }
                    .visualHitArea(shape)
            }
            .frame(width: size.width, height: size.height)
            .visualHitArea(shape)
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
        }
        .frame(width: size.width, height: size.height)
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
        .visualHitArea(Capsule())
    }
}
