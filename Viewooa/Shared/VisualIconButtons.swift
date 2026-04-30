import SwiftUI

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
        style: VisualSelectableIconStyle,
        shape: ShapeType,
        action: @escaping () -> Void
    ) {
        self.init(
            accessibilityLabel: accessibilityLabel,
            systemImage: systemImage,
            isSelected: isSelected,
            size: style.size,
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
            shape: shape,
            foregroundColor: style.foregroundColor,
            backgroundColor: style.backgroundColor,
            hoverEmphasis: style.hoverEmphasis,
            action: action
        )
    }

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
