import SwiftUI

struct ViewerTopControlBar<Store: PhotoViewerControlling>: View {
    @ObservedObject var store: Store
    @Binding var isPinned: Bool
    @Binding var isHoveringRevealArea: Bool
    @Binding var slideshowIntervalDraft: String
    @FocusState private var isSlideshowIntervalFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            toolbarInfoButton

            ViewerControlSeparator()

            toolbarPageLayoutMenu
            toolbarFitMenu
            toolbarSlideshowControl

            ViewerControlSeparator()

            toolbarPinButton
        }
        .font(.system(size: 12, weight: .semibold))
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.42), radius: 1.2, y: 0.6)
        .viewerToolbarSurface(horizontalPadding: 12, verticalPadding: 8)
    }

    private var toolbarInfoButton: some View {
        ViewerControlIconButton(
            accessibilityLabel: "Info",
            systemImage: store.isMetadataVisible ? "info.circle.fill" : "info.circle",
            isActive: store.isMetadataVisible,
            action: store.toggleMetadataVisibility
        )
        .keyboardShortcut(.tab, modifiers: [])
    }

    private var toolbarPageLayoutMenu: some View {
        Menu {
            menuSelectionToggle("Single Page", isSelected: store.pageLayout == .single) {
                store.setPageLayout(.single)
            }

            Divider()

            menuSelectionToggle(SpreadDirection.leftToRight.bookTitle, isSelected: store.pageLayout == .spread && store.spreadDirection == .leftToRight) {
                store.setSpreadDirection(.leftToRight)
                store.setPageLayout(.spread)
            }

            menuSelectionToggle(SpreadDirection.rightToLeft.bookTitle, isSelected: store.pageLayout == .spread && store.spreadDirection == .rightToLeft) {
                store.setSpreadDirection(.rightToLeft)
                store.setPageLayout(.spread)
            }

            menuSelectionToggle("Cover Mode", isSelected: store.isCoverModeEnabled) {
                store.toggleCoverMode()
            }
            .disabled(store.pageLayout != .spread)

            Divider()

            menuSelectionToggle(ViewerPageLayout.verticalStrip.title, isSelected: store.pageLayout == .verticalStrip) {
                store.setPageLayout(.verticalStrip)
            }
        } label: {
            toolbarMenuLabel(systemImage: "rectangle.split.2x1", title: pageLayoutTitle)
        }
        .fixedSize()
        .visualHitArea(Capsule())
        .accessibilityLabel("Page Layout")
    }

    private var pageLayoutTitle: String {
        switch store.pageLayout {
        case .single:
            return ViewerPageLayout.single.shortTitle
        case .spread:
            return store.spreadDirection.bookTitle
        case .verticalStrip:
            return ViewerPageLayout.verticalStrip.shortTitle
        }
    }

    private var toolbarFitMenu: some View {
        Menu {
            ForEach(FitMode.allCases) { fitMode in
                menuSelectionToggle(fitMode.title, isSelected: currentFitMode == fitMode) {
                    store.fitToWindow(fitMode)
                }
            }
        } label: {
            ViewerFitModeIconLabel(fitMode: store.selectedFitMode)
        }
        .fixedSize()
        .visualHitArea(Capsule())
        .accessibilityLabel("Fit Mode: \(store.selectedFitMode.title)")
    }

    private var toolbarSlideshowControl: some View {
        HStack(spacing: 8) {
            ViewerControlIconButton(
                accessibilityLabel: store.isSlideshowPlaying ? "Pause Slideshow" : "Start Slideshow",
                systemImage: store.isSlideshowPlaying ? "pause.circle.fill" : "play.circle",
                isActive: store.isSlideshowPlaying,
                action: store.toggleSlideshow
            )

            slideshowIntervalEditor

            if store.pageLayout == .verticalStrip {
                VerticalSlideshowPreview(intervalSeconds: store.slideshowIntervalSeconds)
            }
        }
        .visualHitArea(Capsule())
        .accessibilityLabel("Slideshow")
    }

    private func toolbarMenuLabel(systemImage: String, title: String, titleWidth: CGFloat? = nil) -> some View {
        ViewerControlCapsuleLabel(systemImage: systemImage, title: title, titleWidth: titleWidth)
    }

    private var slideshowIntervalEditor: some View {
        VisualHoverState(shape: Capsule()) { isHovering in
            HStack(spacing: 4) {
                TextField("", text: $slideshowIntervalDraft)
                    .textFieldStyle(.plain)
                    .focused($isSlideshowIntervalFocused)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(width: 34, height: 22)
                    .onSubmit(commitSlideshowIntervalDraft)
                    .onChange(of: isSlideshowIntervalFocused) { _, isFocused in
                        if !isFocused {
                            commitSlideshowIntervalDraft()
                        }
                    }

                Text("s")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
            }
            .padding(.leading, 9)
            .padding(.trailing, 9)
            .frame(height: 28)
            .background(ViewerControlVisualStyle.capsuleBackground.color(isHovering: isHovering), in: Capsule())
            .overlay {
                Capsule().strokeBorder(ViewerControlVisualStyle.capsuleBorder.color(isHovering: isHovering))
            }
            .overlay {
                SlideshowIntervalScrollStepper(onStep: adjustSlideshowInterval)
            }
            .visualHitArea(Capsule())
            .onTapGesture {
                isSlideshowIntervalFocused = true
            }
        }
        .accessibilityLabel("Slideshow interval \(slideshowIntervalText)")
    }

    private var toolbarPinButton: some View {
        ViewerControlIconButton(
            accessibilityLabel: isPinned ? "Unpin Toolbar" : "Pin Toolbar",
            systemImage: isPinned ? "pin.fill" : "pin",
            isActive: isPinned
        ) {
            toggleToolbarPin()
        }
    }

    private func toggleToolbarPin() {
        isPinned.toggle()
            if !isPinned {
                isHoveringRevealArea = true
            }
    }

    private var currentFitMode: FitMode? {
        store.selectedFitMode
    }

    private var slideshowIntervalText: String {
        "\(ViewerSlideshowIntervalFormatter.string(for: store.slideshowIntervalSeconds))s"
    }

    private func menuSelectionToggle(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Toggle(title, isOn: Binding(
            get: { isSelected },
            set: { newValue in
                guard newValue || isSelected else { return }
                action()
            }
        ))
    }

    private func commitSlideshowIntervalDraft() {
        let normalizedText = slideshowIntervalDraft
            .replacingOccurrences(of: "s", with: "")
            .replacingOccurrences(of: "S", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let seconds = Double(normalizedText) {
            store.setSlideshowInterval(seconds)
        }

        slideshowIntervalDraft = ViewerSlideshowIntervalFormatter.string(for: store.slideshowIntervalSeconds)
    }

    private func adjustSlideshowInterval(by delta: Double) {
        commitSlideshowIntervalDraft()
        store.setSlideshowInterval(store.slideshowIntervalSeconds + delta)
        slideshowIntervalDraft = ViewerSlideshowIntervalFormatter.string(for: store.slideshowIntervalSeconds)
    }
}

struct ViewerBottomControlBar<Store: PhotoViewerControlling>: View {
    @ObservedObject var store: Store
    @Binding var isPinned: Bool
    let onOpen: () -> Void
    let onZoomOut: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            openSection
            sectionSeparator(after: .open)

            zoomSection
            navigationSection

            sectionSeparator(before: .pin)
            pinSection
        }
        .viewerToolbarSurface(horizontalPadding: 14, verticalPadding: 10)
    }

    private var openSection: some View {
        controlButton("Open", systemImage: "folder", action: onOpen)
    }

    private var zoomSection: some View {
        Group {
            controlButton("Zoom Out", systemImage: "minus.magnifyingglass", action: onZoomOut)
            actualSizeButton
            controlButton("Zoom In", systemImage: "plus.magnifyingglass", action: store.zoomIn)
            controlButton("Rotate Right", systemImage: "rotate.right", action: store.rotateClockwise)
        }
    }

    private var navigationSection: some View {
        Group {
            repeatingControlButton("Previous", systemImage: "chevron.left", action: store.showPreviousImageFromNavigationShortcut)
            repeatingControlButton("Next", systemImage: "chevron.right", action: store.showNextImageFromNavigationShortcut)
        }
    }

    private var pinSection: some View {
        ViewerControlIconButton(
            accessibilityLabel: isPinned ? "Unpin Controls" : "Pin Controls",
            systemImage: isPinned ? "pin.fill" : "pin",
            isActive: isPinned,
            emphasis: .prominent,
            action: { isPinned.toggle() }
        )
    }

    private func controlButton(_ accessibilityLabel: String, systemImage: String, action: @escaping () -> Void) -> some View {
        ViewerControlIconButton(accessibilityLabel: accessibilityLabel, systemImage: systemImage, action: action)
    }

    private func repeatingControlButton(_ accessibilityLabel: String, systemImage: String, action: @escaping () -> Void) -> some View {
        RepeatingControlButton(
            accessibilityLabel: accessibilityLabel,
            systemImage: systemImage,
            action: action,
            onHoldChange: { isHolding in
                if isHolding {
                    store.beginNavigationHoldIndicator()
                } else {
                    store.endNavigationHoldIndicator()
                }
            }
        )
    }

    private var actualSizeButton: some View {
        ViewerControlIconButton(
            accessibilityLabel: "Actual Size",
            systemImage: "1.magnifyingglass",
            isActive: isActualSize,
            action: store.toggleActualSize
        )
    }

    private var isActualSize: Bool {
        if case .actualSize = store.zoomMode {
            return true
        }

        return false
    }

    @ViewBuilder
    private func sectionSeparator(before section: ViewerBottomToolbarSection) -> some View {
        if section.showsLeadingSeparator {
            ViewerControlSeparator()
        }
    }

    @ViewBuilder
    private func sectionSeparator(after section: ViewerBottomToolbarSection) -> some View {
        if section.showsTrailingSeparator {
            ViewerControlSeparator()
        }
    }
}

enum ViewerBottomToolbarSection {
    case open
    case zoom
    case navigation
    case pin

    var showsLeadingSeparator: Bool {
        self == .pin
    }

    var showsTrailingSeparator: Bool {
        self == .open
    }
}

private struct ViewerControlSeparator: View {
    var body: some View {
        Rectangle()
            .fill(VisualInteractionPalette.viewerSeparator)
            .frame(width: 1, height: 24)
    }
}

private extension View {
    func viewerToolbarSurface(horizontalPadding: CGFloat, verticalPadding: CGFloat) -> some View {
        VisualToolbarSurface(
            shape: Capsule(),
            style: ViewerToolbarSurfaceStyle.toolbar(
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding
            )
        ) {
            self
        }
    }
}

private enum ViewerToolbarSurfaceStyle {
    static func toolbar(horizontalPadding: CGFloat, verticalPadding: CGFloat) -> VisualToolbarSurfaceStyle<Material> {
        VisualToolbarSurfaceStyle(
            backgroundStyle: .ultraThinMaterial,
            tintColor: VisualInteractionPalette.viewerSurfaceTint,
            borderColor: VisualInteractionPalette.viewerSurfaceBorder,
            shadowColor: VisualInteractionPalette.viewerToolbarShadow,
            shadowRadius: 20,
            shadowYOffset: 10,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding
        )
    }
}
