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

struct VisualHoverEmphasisStyle {
    let stroke: Color
    let shadow: Color
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat

    static let none = VisualHoverEmphasisStyle(stroke: .clear, shadow: .clear, shadowRadius: 0, shadowYOffset: 0)

    func strokeColor(isHovering: Bool) -> Color {
        isHovering ? stroke : .clear
    }

    func shadowColor(isHovering: Bool) -> Color {
        isHovering ? shadow : .clear
    }
}

struct VisualIconActionStyle {
    let size: CGSize
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let foregroundColor: (Bool) -> Color
    let backgroundColor: (Bool) -> Color
    let hoverEmphasis: VisualHoverEmphasisStyle
    let overlay: ((Bool) -> AnyView)?

    init(
        size: CGSize,
        fontSize: CGFloat = 15,
        fontWeight: Font.Weight = .semibold,
        foregroundColor: @escaping (Bool) -> Color,
        backgroundColor: @escaping (Bool) -> Color,
        hoverEmphasis: VisualHoverEmphasisStyle = .none,
        overlay: ((Bool) -> AnyView)? = nil
    ) {
        self.size = size
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.hoverEmphasis = hoverEmphasis
        self.overlay = overlay
    }

    init(
        size: CGFloat,
        fontSize: CGFloat = 15,
        fontWeight: Font.Weight = .semibold,
        foregroundColor: @escaping (Bool) -> Color,
        backgroundColor: @escaping (Bool) -> Color,
        hoverEmphasis: VisualHoverEmphasisStyle = .none,
        overlay: ((Bool) -> AnyView)? = nil
    ) {
        self.init(
            size: CGSize(width: size, height: size),
            fontSize: fontSize,
            fontWeight: fontWeight,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            hoverEmphasis: hoverEmphasis,
            overlay: overlay
        )
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
    let hoverEmphasis: VisualHoverEmphasisStyle
    let overlay: ((Bool) -> AnyView)?
    let action: () -> Void

    init(
        accessibilityLabel: String,
        systemImage: String,
        style: VisualIconActionStyle,
        shape: ShapeType,
        action: @escaping () -> Void
    ) {
        self.init(
            accessibilityLabel: accessibilityLabel,
            systemImage: systemImage,
            size: style.size,
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
            shape: shape,
            foregroundColor: style.foregroundColor,
            backgroundColor: style.backgroundColor,
            hoverEmphasis: style.hoverEmphasis,
            overlay: style.overlay,
            action: action
        )
    }

    init(
        accessibilityLabel: String,
        systemImage: String,
        size: CGSize,
        fontSize: CGFloat = 15,
        fontWeight: Font.Weight = .semibold,
        shape: ShapeType,
        foregroundColor: @escaping (Bool) -> Color,
        backgroundColor: @escaping (Bool) -> Color,
        hoverEmphasis: VisualHoverEmphasisStyle = .none,
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
        self.hoverEmphasis = hoverEmphasis
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
        hoverEmphasis: VisualHoverEmphasisStyle = .none,
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
            hoverEmphasis: hoverEmphasis,
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
                    .overlay {
                        shape.stroke(hoverEmphasis.strokeColor(isHovering: isHovering), lineWidth: 1)
                    }
                    .shadow(
                        color: hoverEmphasis.shadowColor(isHovering: isHovering),
                        radius: hoverEmphasis.shadowRadius,
                        y: hoverEmphasis.shadowYOffset
                    )
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

struct VisualToolbarSurface<ShapeType: InsettableShape, BackgroundStyle: ShapeStyle, Content: View>: View {
    let shape: ShapeType
    let backgroundStyle: BackgroundStyle
    let borderColor: Color
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let content: () -> Content

    init(
        shape: ShapeType,
        backgroundStyle: BackgroundStyle,
        borderColor: Color,
        shadowColor: Color,
        shadowRadius: CGFloat,
        shadowYOffset: CGFloat,
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.shape = shape
        self.backgroundStyle = backgroundStyle
        self.borderColor = borderColor
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowYOffset = shadowYOffset
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.content = content
    }

    var body: some View {
        content()
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundStyle, in: shape)
            .overlay {
                shape.strokeBorder(borderColor)
            }
            .visualHitArea(shape)
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowYOffset)
    }
}

struct VisualSelectableIconButton<ShapeType: Shape>: View {
    let accessibilityLabel: String
    let systemImage: String
    let isSelected: Bool
    let size: CGSize
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let shape: ShapeType
    let foregroundColor: (Bool, Bool) -> Color
    let backgroundColor: (Bool, Bool) -> Color
    let hoverEmphasis: VisualHoverEmphasisStyle
    let action: () -> Void

    init(
        accessibilityLabel: String,
        systemImage: String,
        isSelected: Bool,
        size: CGSize,
        fontSize: CGFloat = 13,
        fontWeight: Font.Weight = .semibold,
        shape: ShapeType,
        foregroundColor: @escaping (Bool, Bool) -> Color,
        backgroundColor: @escaping (Bool, Bool) -> Color,
        hoverEmphasis: VisualHoverEmphasisStyle = .none,
        action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.size = size
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.shape = shape
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.hoverEmphasis = hoverEmphasis
        self.action = action
    }

    var body: some View {
        VisualHoverState(shape: shape) { isHovering in
            Button(action: action) {
                Image(systemName: systemImage)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .frame(width: size.width, height: size.height)
                    .foregroundStyle(foregroundColor(isSelected, isHovering))
                    .background(backgroundColor(isSelected, isHovering), in: shape)
                    .overlay {
                        shape.stroke(hoverEmphasis.strokeColor(isHovering: isHovering), lineWidth: 1)
                    }
                    .shadow(
                        color: hoverEmphasis.shadowColor(isHovering: isHovering),
                        radius: hoverEmphasis.shadowRadius,
                        y: hoverEmphasis.shadowYOffset
                    )
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

struct VisualSelectableContentButton<ShapeType: InsettableShape, Label: View>: View {
    let accessibilityLabel: String
    let isSelected: Bool
    let shape: ShapeType
    let backgroundColor: VisualInteractionColorStyle
    let borderColor: VisualInteractionColorStyle?
    let borderLineWidth: CGFloat
    let action: () -> Void
    let label: (Bool) -> Label

    init(
        accessibilityLabel: String,
        isSelected: Bool,
        shape: ShapeType,
        backgroundColor: VisualInteractionColorStyle,
        borderColor: VisualInteractionColorStyle? = nil,
        borderLineWidth: CGFloat = 1,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.isSelected = isSelected
        self.shape = shape
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderLineWidth = borderLineWidth
        self.action = action
        self.label = label
    }

    var body: some View {
        VisualHoverState(shape: shape) { isHovering in
            Button(action: action) {
                label(isHovering)
                    .background(backgroundColor.color(isSelected: isSelected, isHovering: isHovering), in: shape)
                    .overlay {
                        if let borderColor {
                            shape.strokeBorder(
                                borderColor.color(isSelected: isSelected, isHovering: isHovering),
                                lineWidth: borderLineWidth
                            )
                        }
                    }
                    .visualHitArea(shape)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
            .visualHitArea(shape)
        }
        .visualHitArea(shape)
    }
}

struct VisualHoverContentButton<ShapeType: Shape, Label: View>: View {
    let accessibilityLabel: String
    let shape: ShapeType
    let hoverEmphasis: VisualHoverEmphasisStyle
    let action: () -> Void
    let label: (Bool) -> Label

    init(
        accessibilityLabel: String,
        shape: ShapeType,
        hoverEmphasis: VisualHoverEmphasisStyle = .none,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.shape = shape
        self.hoverEmphasis = hoverEmphasis
        self.action = action
        self.label = label
    }

    var body: some View {
        VisualHoverState(shape: shape) { isHovering in
            Button(action: action) {
                label(isHovering)
                    .overlay {
                        shape.stroke(hoverEmphasis.strokeColor(isHovering: isHovering), lineWidth: 1)
                    }
                    .shadow(
                        color: hoverEmphasis.shadowColor(isHovering: isHovering),
                        radius: hoverEmphasis.shadowRadius,
                        y: hoverEmphasis.shadowYOffset
                    )
                    .visualHitArea(shape)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
            .visualHitArea(shape)
        }
        .visualHitArea(shape)
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
