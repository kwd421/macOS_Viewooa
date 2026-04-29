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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule().strokeBorder(.white.opacity(0.14))
        }
        .shadow(color: .black.opacity(0.34), radius: 20, y: 10)
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

            menuSelectionToggle("Two Pages: L-R", isSelected: store.pageLayout == .spread && store.spreadDirection == .leftToRight) {
                store.setSpreadDirection(.leftToRight)
                store.setPageLayout(.spread)
            }

            menuSelectionToggle("Two Pages: R-L", isSelected: store.pageLayout == .spread && store.spreadDirection == .rightToLeft) {
                store.setSpreadDirection(.rightToLeft)
                store.setPageLayout(.spread)
            }

            menuSelectionToggle("Cover Mode", isSelected: store.isCoverModeEnabled) {
                store.toggleCoverMode()
            }
            .disabled(store.pageLayout != .spread)

            Divider()

            menuSelectionToggle("Vertical Strip", isSelected: store.pageLayout == .verticalStrip) {
                store.setPageLayout(.verticalStrip)
            }
        } label: {
            toolbarMenuLabel(systemImage: "rectangle.split.2x1", title: pageLayoutTitle)
        }
        .fixedSize()
        .visualHitArea()
        .accessibilityLabel("Page Layout")
    }

    private var pageLayoutTitle: String {
        switch store.pageLayout {
        case .single:
            return ViewerPageLayout.single.shortTitle
        case .spread:
            return "\(ViewerPageLayout.spread.shortTitle) \(store.spreadDirection.shortTitle)"
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
            toolbarMenuLabel(
                systemImage: "arrow.up.left.and.down.right.magnifyingglass",
                title: currentFitMode?.shortTitle ?? "Custom"
            )
        }
        .fixedSize()
        .visualHitArea()
        .accessibilityLabel("Fit Mode")
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
        .visualHitArea()
        .accessibilityLabel("Slideshow")
    }

    private func toolbarMenuLabel(systemImage: String, title: String) -> some View {
        ViewerControlCapsuleLabel(systemImage: systemImage, title: title)
    }

    private var slideshowIntervalEditor: some View {
        VisualHoverState { isHovering in
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
            .background(.white.opacity(ViewerControlVisualStyle.capsuleBackgroundOpacity(isHovering: isHovering)), in: Capsule())
            .overlay {
                Capsule().strokeBorder(.white.opacity(ViewerControlVisualStyle.capsuleBorderOpacity(isHovering: isHovering)))
            }
            .overlay {
                SlideshowIntervalScrollStepper(onStep: adjustSlideshowInterval)
            }
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
        if case let .fit(fitMode) = store.zoomMode {
            return fitMode
        }

        return nil
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
            controlButton("Open", systemImage: "folder", action: onOpen)

            ViewerControlSeparator()

            controlButton("Zoom Out", systemImage: "minus.magnifyingglass", action: onZoomOut)
            actualSizeButton
            controlButton("Zoom In", systemImage: "plus.magnifyingglass", action: store.zoomIn)
            controlButton("Rotate Right", systemImage: "rotate.right", action: store.rotateClockwise)

            ViewerControlSeparator()

            repeatingControlButton("Previous", systemImage: "chevron.left", action: store.showPreviousImageFromNavigationShortcut)
            repeatingControlButton("Next", systemImage: "chevron.right", action: store.showNextImageFromNavigationShortcut)

            controlButton(
                isPinned ? "Unpin Controls" : "Pin Controls",
                systemImage: isPinned ? "pin.fill" : "pin",
                action: { isPinned.toggle() }
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule().strokeBorder(.white.opacity(0.14))
        }
        .shadow(color: .black.opacity(0.34), radius: 20, y: 10)
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
}

private struct ViewerControlSeparator: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.22))
            .frame(width: 1, height: 24)
    }
}
