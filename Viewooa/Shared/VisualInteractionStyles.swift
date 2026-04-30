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

struct VisualSelectableIconStyle {
    let size: CGSize
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let foregroundColor: (Bool, Bool) -> Color
    let backgroundColor: (Bool, Bool) -> Color
    let hoverEmphasis: VisualHoverEmphasisStyle

    init(
        size: CGSize,
        fontSize: CGFloat = 13,
        fontWeight: Font.Weight = .semibold,
        foregroundColor: @escaping (Bool, Bool) -> Color,
        backgroundColor: @escaping (Bool, Bool) -> Color,
        hoverEmphasis: VisualHoverEmphasisStyle = .none
    ) {
        self.size = size
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.hoverEmphasis = hoverEmphasis
    }
}

struct VisualSelectableContentStyle {
    let backgroundColor: VisualInteractionColorStyle
    let borderColor: VisualInteractionColorStyle?
    let borderLineWidth: CGFloat

    init(
        backgroundColor: VisualInteractionColorStyle,
        borderColor: VisualInteractionColorStyle? = nil,
        borderLineWidth: CGFloat = 1
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderLineWidth = borderLineWidth
    }
}

struct VisualHoverContentStyle {
    let backgroundColor: VisualHoverColorStyle
    let hoverEmphasis: VisualHoverEmphasisStyle

    init(
        backgroundColor: VisualHoverColorStyle = VisualHoverColorStyle(normal: .clear, hover: .clear),
        hoverEmphasis: VisualHoverEmphasisStyle = .none
    ) {
        self.backgroundColor = backgroundColor
        self.hoverEmphasis = hoverEmphasis
    }
}

struct VisualToolbarSurfaceStyle<BackgroundStyle: ShapeStyle> {
    let backgroundStyle: BackgroundStyle
    let borderColor: Color
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    init(
        backgroundStyle: BackgroundStyle,
        borderColor: Color,
        shadowColor: Color,
        shadowRadius: CGFloat,
        shadowYOffset: CGFloat,
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat
    ) {
        self.backgroundStyle = backgroundStyle
        self.borderColor = borderColor
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowYOffset = shadowYOffset
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }
}
