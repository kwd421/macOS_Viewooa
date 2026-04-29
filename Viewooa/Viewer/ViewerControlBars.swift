import SwiftUI

struct ViewerTopControlBar<Store: PhotoViewerControlling>: View {
    @ObservedObject var store: Store
    @Binding var isPinned: Bool
    @Binding var isHoveringRevealArea: Bool
    @Binding var slideshowIntervalDraft: String

    var body: some View {
        HStack(spacing: 12) {
            toolbarInfoButton

            ViewerControlSeparator()

            toolbarPageLayoutMenu
            toolbarFitMenu
            toolbarSlideshowControl

            ViewerControlSeparator()

            toolbarPinButton
        }
        .font(.system(size: 13, weight: .semibold))
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule().strokeBorder(.white.opacity(0.14))
        }
        .shadow(color: .black.opacity(0.34), radius: 20, y: 10)
    }

    private var toolbarInfoButton: some View {
        Button {
            store.toggleMetadataVisibility()
        } label: {
            Label("Info", systemImage: store.isMetadataVisible ? "info.circle.fill" : "info.circle")
        }
        .keyboardShortcut(.tab, modifiers: [])
        .accessibilityLabel("Info")
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
            Label("View: \(pageLayoutTitle)", systemImage: "rectangle.split.2x1")
        }
        .fixedSize()
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
            Label("Fit: \(currentFitMode?.shortTitle ?? "Custom")", systemImage: "arrow.up.left.and.down.right.magnifyingglass")
        }
        .fixedSize()
        .accessibilityLabel("Fit Mode")
    }

    private var toolbarSlideshowControl: some View {
        HStack(spacing: 8) {
            Button {
                store.toggleSlideshow()
            } label: {
                Label(
                    store.isSlideshowPlaying ? "Pause" : "Slideshow",
                    systemImage: store.isSlideshowPlaying ? "pause.circle.fill" : "play.circle"
                )
            }

            slideshowIntervalEditor

            if store.pageLayout == .verticalStrip {
                VerticalSlideshowPreview(intervalSeconds: store.slideshowIntervalSeconds)
            }
        }
        .accessibilityLabel("Slideshow")
    }

    private var slideshowIntervalEditor: some View {
        HStack(spacing: 4) {
            SlideshowIntervalField(
                text: $slideshowIntervalDraft,
                onCommit: commitSlideshowIntervalDraft,
                onStep: adjustSlideshowInterval
            )
            .frame(width: 32, height: 18)

            Text("s")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .offset(y: 0.5)
        }
        .padding(.leading, 8)
        .padding(.trailing, 7)
        .frame(height: 26)
        .background(.white.opacity(0.10), in: Capsule())
        .overlay {
            Capsule().strokeBorder(.white.opacity(0.10))
        }
        .accessibilityLabel("Slideshow interval \(slideshowIntervalText)")
    }

    private var toolbarPinButton: some View {
        Button {
            isPinned.toggle()
            if !isPinned {
                isHoveringRevealArea = true
            }
        } label: {
            Image(systemName: isPinned ? "pin.fill" : "pin")
        }
        .accessibilityLabel(isPinned ? "Unpin Toolbar" : "Pin Toolbar")
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
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.10), in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .accessibilityLabel(accessibilityLabel)
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
        Button(action: store.toggleActualSize) {
            ActualSizeIcon()
                .frame(width: 30, height: 30)
                .background(isActualSize ? .white.opacity(0.20) : .white.opacity(0.10), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .accessibilityLabel("Actual Size")
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
