import SwiftUI

enum VisualInteractionPalette {
    static let subtleToolbarHover = VisualHoverColorStyle(
        normal: .clear,
        hover: Color.primary.opacity(0.08)
    )

    static let subtleControlHover = VisualHoverColorStyle(
        normal: .clear,
        hover: Color.primary.opacity(0.07)
    )

    static let vibrantToolbarHover = VisualHoverColorStyle(
        normal: .clear,
        hover: Color.white.opacity(0.12)
    )

    static let openBrowserThumbnailBackground = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.primary.opacity(0.055),
        selected: Color.openBrowserSelection.opacity(0.07),
        selectedHover: Color.openBrowserSelection.opacity(0.12)
    )

    static let openBrowserThumbnailBorder = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.primary.opacity(0.10),
        selected: Color.openBrowserSelection.opacity(0.46),
        selectedHover: Color.openBrowserSelection.opacity(0.62)
    )

    static let openBrowserListBackground = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.primary.opacity(0.055),
        selected: Color.openBrowserSelection.opacity(0.16),
        selectedHover: Color.openBrowserSelection.opacity(0.22)
    )

    static let openBrowserListBorder = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.primary.opacity(0.08),
        selected: Color.openBrowserSelection.opacity(0.24),
        selectedHover: Color.openBrowserSelection.opacity(0.34)
    )

    static let darkOverlayThumbnailBackground = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.white.opacity(0.10),
        selected: Color.white.opacity(0.15),
        selectedHover: Color.white.opacity(0.26)
    )

    static let darkOverlayListBackground = VisualInteractionColorStyle(
        normal: Color.white.opacity(0.055),
        hover: Color.white.opacity(0.12),
        selected: Color.white.opacity(0.16),
        selectedHover: Color.white.opacity(0.26)
    )

    static let darkOverlayListBorder = VisualInteractionColorStyle(
        normal: Color.white.opacity(0.08),
        hover: Color.white.opacity(0.18),
        selected: Color.white.opacity(0.48),
        selectedHover: Color.white.opacity(0.62)
    )

    static let darkSegmentBackground = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.white.opacity(0.12),
        selected: Color.white.opacity(0.18),
        selectedHover: Color.white.opacity(0.28)
    )

    static let vibrantSegmentBackground = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.white.opacity(0.10),
        selected: Color.white.opacity(0.16),
        selectedHover: Color.white.opacity(0.22)
    )

    static let openBrowserSegmentBackground = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.primary.opacity(0.07),
        selected: Color(nsColor: .selectedControlColor).opacity(0.22),
        selectedHover: Color(nsColor: .selectedControlColor).opacity(0.30)
    )

    static let openBrowserSidebarRowBackground = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.primary.opacity(0.06),
        selected: Color.white.opacity(0.09),
        selectedHover: Color.white.opacity(0.13)
    )

    static func thumbnailStepperIconColor(isVibrant: Bool) -> VisualInteractionColorStyle {
        VisualInteractionColorStyle(
            normal: isVibrant ? Color.white.opacity(0.78) : .secondary,
            hover: isVibrant ? Color.white.opacity(0.78) : .secondary,
            selected: isVibrant ? Color.white.opacity(0.24) : Color.secondary.opacity(0.28),
            selectedHover: isVibrant ? Color.white.opacity(0.24) : Color.secondary.opacity(0.28)
        )
    }

    static func thumbnailStepperButtonBackground(isVibrant: Bool) -> VisualHoverColorStyle {
        isVibrant ? vibrantToolbarHover : subtleControlHover
    }
}
