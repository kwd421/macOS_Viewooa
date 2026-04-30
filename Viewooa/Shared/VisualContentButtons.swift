import SwiftUI

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
        style: VisualSelectableContentStyle,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.init(
            accessibilityLabel: accessibilityLabel,
            isSelected: isSelected,
            shape: shape,
            backgroundColor: style.backgroundColor,
            borderColor: style.borderColor,
            borderLineWidth: style.borderLineWidth,
            action: action,
            label: label
        )
    }

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
    let backgroundColor: VisualHoverColorStyle
    let hoverEmphasis: VisualHoverEmphasisStyle
    let action: () -> Void
    let label: (Bool) -> Label

    init(
        accessibilityLabel: String,
        shape: ShapeType,
        style: VisualHoverContentStyle,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.init(
            accessibilityLabel: accessibilityLabel,
            shape: shape,
            backgroundColor: style.backgroundColor,
            hoverEmphasis: style.hoverEmphasis,
            action: action,
            label: label
        )
    }

    init(
        accessibilityLabel: String,
        shape: ShapeType,
        backgroundColor: VisualHoverColorStyle = VisualHoverColorStyle(normal: .clear, hover: .clear),
        hoverEmphasis: VisualHoverEmphasisStyle = .none,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.shape = shape
        self.backgroundColor = backgroundColor
        self.hoverEmphasis = hoverEmphasis
        self.action = action
        self.label = label
    }

    var body: some View {
        VisualHoverState(shape: shape) { isHovering in
            Button(action: action) {
                label(isHovering)
                    .background(backgroundColor.color(isHovering: isHovering), in: shape)
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
