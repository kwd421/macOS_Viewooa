import SwiftUI
import AppKit

enum VisualInteractionPalette {
    private static let platformSelection = Color(nsColor: .selectedContentBackgroundColor)
    private static let platformContentBackground = Color(nsColor: .underPageBackgroundColor)
    private static let platformSeparator = Color(nsColor: .separatorColor).opacity(0.45)
    private static let platformControlFill = Color(nsColor: .controlBackgroundColor).opacity(0.64)

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
        selected: platformSelection.opacity(0.07),
        selectedHover: platformSelection.opacity(0.12)
    )

    static let openBrowserThumbnailBorder = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.primary.opacity(0.10),
        selected: platformSelection.opacity(0.46),
        selectedHover: platformSelection.opacity(0.62)
    )

    static let openBrowserListBackground = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.primary.opacity(0.055),
        selected: platformSelection.opacity(0.16),
        selectedHover: platformSelection.opacity(0.22)
    )

    static let openBrowserListBorder = VisualInteractionColorStyle(
        normal: .clear,
        hover: Color.primary.opacity(0.08),
        selected: platformSelection.opacity(0.24),
        selectedHover: platformSelection.opacity(0.34)
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

    static let viewerIconBackground = VisualPressColorStyle(
        normal: Color.white.opacity(0.10),
        hover: Color.white.opacity(0.28),
        pressed: Color.white.opacity(0.32)
    )

    static let viewerIconForeground = VisualInteractionColorStyle(
        normal: Color.white.opacity(0.82),
        hover: Color.white.opacity(0.82),
        selected: .white,
        selectedHover: .white
    )

    static let viewerCapsuleBackground = VisualHoverColorStyle(
        normal: Color.white.opacity(0.10),
        hover: Color.white.opacity(0.26)
    )

    static let viewerCapsuleBorder = VisualHoverColorStyle(
        normal: Color.white.opacity(0.10),
        hover: Color.white.opacity(0.28)
    )

    static let viewerSurfaceBorder = Color.white.opacity(0.14)
    static let viewerSeparator = Color.white.opacity(0.22)
    static let viewerToolbarShadow = Color.black.opacity(0.34)
    static let viewerCardShadow = Color.black.opacity(0.28)

    static let openBrowserToolbarBorder = platformSeparator.opacity(0.18)
    static let openBrowserToolbarDivider = platformSeparator.opacity(0.42)
    static let openBrowserContentDivider = platformSeparator.opacity(0.55)
    static let openBrowserStrongDivider = platformSeparator.opacity(0.65)
    static let openBrowserToolbarShadow = Color.black.opacity(0.06)
    static let openBrowserTitleShadow = platformContentBackground.opacity(0.75)
    static let openBrowserVibrantControlFill = Color.white.opacity(0.10)
    static let openBrowserVibrantDivider = Color.white.opacity(0.18)
    static let openBrowserVibrantSearchFill = Color.white.opacity(0.08)
    static let openBrowserVibrantIcon = Color.white.opacity(0.82)
    static let openBrowserVibrantSecondaryIcon = Color.white.opacity(0.62)
    static let openBrowserVibrantSearchIcon = Color.white.opacity(0.76)

    static let openBrowserPlainControlHover = VisualHoverColorStyle(
        normal: platformControlFill,
        hover: platformControlFill.opacity(1.25)
    )

    static let imageBrowserOverlayScrim = Color.black.opacity(0.34)
    static let imageBrowserDivider = Color.white.opacity(0.16)
    static let imageBrowserControlFill = Color.white.opacity(0.10)
    static let imageBrowserPreviewFill = Color.white.opacity(0.08)
    static let imageBrowserPreviewPlaceholder = Color.white.opacity(0.36)
    static let imageBrowserPreviewBorder = Color.white.opacity(0.14)
    static let imageBrowserSecondaryText = Color.white.opacity(0.58)
    static let imageBrowserBodyText = Color.white.opacity(0.74)
    static let imageBrowserMutedText = Color.white.opacity(0.54)
    static let imageBrowserIndexText = Color.white.opacity(0.52)
    static let imageBrowserPreviewShadow = Color.black.opacity(0.24)
    static let imageBrowserSelectedPreviewShadow = Color.black.opacity(0.42)

    static let imageBrowserCloseButtonBackground = VisualHoverColorStyle(
        normal: Color.white.opacity(0.12),
        hover: Color.white.opacity(0.28)
    )

    static let viewerOverlayCardBorder = Color.white.opacity(0.08)
    static let verticalPreviewBackground = Color.white.opacity(0.08)
    static let verticalPreviewPrimaryPage = Color.white.opacity(0.84)
    static let verticalPreviewSecondaryPage = Color.white.opacity(0.62)
    static let verticalPreviewPageHeader = Color.black.opacity(0.12)
    static let verticalPreviewBottomFade = Color.white.opacity(0.20)
}
