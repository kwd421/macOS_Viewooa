import SwiftUI

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
        style: VisualToolbarSurfaceStyle<BackgroundStyle>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            shape: shape,
            backgroundStyle: style.backgroundStyle,
            borderColor: style.borderColor,
            shadowColor: style.shadowColor,
            shadowRadius: style.shadowRadius,
            shadowYOffset: style.shadowYOffset,
            horizontalPadding: style.horizontalPadding,
            verticalPadding: style.verticalPadding,
            content: content
        )
    }

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
