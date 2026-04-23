import AppKit
import SwiftUI

struct ViewerWindowShell: View {
    @ObservedObject var viewerState: ViewerState
    @State private var isControlBarPinned = true
    @State private var isHoveringControlRevealArea = false
    @State private var isTopControlBarPinned = true
    @State private var isHoveringTopControlRevealArea = false
    @State private var transientNoticeDismissTask: Task<Void, Never>?
    @State private var slideshowIntervalDraft = "3"

    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()
            ImageViewerContainerView(viewerState: viewerState)

            if hasImage {
                topControlRevealArea
                navigationCountOverlay
                metadataOverlay
                bottomControlRevealArea
            }

            if let overlayKind {
                overlayCard(for: overlayKind)
            }

            transientNoticeOverlay
        }
        .animation(.easeOut(duration: 0.16), value: topControlsVisible)
        .animation(.easeOut(duration: 0.16), value: bottomControlsVisible)
        .animation(.easeOut(duration: 0.16), value: viewerState.isMetadataVisible)
        .animation(.smooth(duration: 0.58, extraBounce: 0), value: viewerState.isNavigationCountVisible)
        .animation(.easeOut(duration: 0.16), value: viewerState.transientNotice)
        .onChange(of: viewerState.transientNotice?.id) { _, noticeID in
            scheduleTransientNoticeDismissal(for: noticeID)
        }
        .onChange(of: viewerState.slideshowIntervalSeconds) { _, seconds in
            slideshowIntervalDraft = formattedSlideshowValue(seconds)
        }
        .onDisappear {
            transientNoticeDismissTask?.cancel()
        }
    }

    private var toolbarInfoButton: some View {
        Button {
            viewerState.toggleMetadataVisibility()
        } label: {
            Label("Info", systemImage: viewerState.isMetadataVisible ? "info.circle.fill" : "info.circle")
        }
        .keyboardShortcut(.tab, modifiers: [])
        .accessibilityLabel("Info")
    }

    private var toolbarPageLayoutMenu: some View {
        Menu {
            Button {
                viewerState.setPageLayout(.single)
            } label: {
                menuCheckmarkLabel("Single Page", isSelected: viewerState.pageLayout == .single)
            }

            Divider()

            Button {
                viewerState.setSpreadDirection(.leftToRight)
                viewerState.setPageLayout(.spread)
            } label: {
                menuCheckmarkLabel("Two Pages: L-R", isSelected: viewerState.pageLayout == .spread && viewerState.spreadDirection == .leftToRight)
            }

            Button {
                viewerState.setSpreadDirection(.rightToLeft)
                viewerState.setPageLayout(.spread)
            } label: {
                menuCheckmarkLabel("Two Pages: R-L", isSelected: viewerState.pageLayout == .spread && viewerState.spreadDirection == .rightToLeft)
            }

            Toggle("Cover Mode", isOn: Binding(
                get: { viewerState.isCoverModeEnabled },
                set: { _ in viewerState.toggleCoverMode() }
            ))
            .disabled(viewerState.pageLayout != .spread)

            Divider()

            Button {
                viewerState.setPageLayout(.verticalStrip)
            } label: {
                menuCheckmarkLabel("Vertical Strip", isSelected: viewerState.pageLayout == .verticalStrip)
            }
        } label: {
            Label("View: \(pageLayoutTitle)", systemImage: "rectangle.split.2x1")
        }
        .fixedSize()
        .accessibilityLabel("Page Layout")
    }

    private var pageLayoutTitle: String {
        switch viewerState.pageLayout {
        case .single:
            return ViewerPageLayout.single.shortTitle
        case .spread:
            return "\(ViewerPageLayout.spread.shortTitle) \(viewerState.spreadDirection.shortTitle)"
        case .verticalStrip:
            return ViewerPageLayout.verticalStrip.shortTitle
        }
    }

    private var toolbarFitMenu: some View {
        Menu {
            ForEach(FitMode.allCases) { fitMode in
                Button {
                    viewerState.fitToWindow(fitMode)
                } label: {
                    menuCheckmarkLabel(fitMode.title, isSelected: currentFitMode == fitMode)
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
                viewerState.toggleSlideshow()
            } label: {
                Label(
                    viewerState.isSlideshowPlaying ? "Pause" : "Slideshow",
                    systemImage: viewerState.isSlideshowPlaying ? "pause.circle.fill" : "play.circle"
                )
            }

            slideshowIntervalEditor

            if viewerState.pageLayout == .verticalStrip {
                VerticalSlideshowPreview(intervalSeconds: viewerState.slideshowIntervalSeconds)
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
            isTopControlBarPinned.toggle()
            if !isTopControlBarPinned {
                isHoveringTopControlRevealArea = true
            }
        } label: {
            Image(systemName: isTopControlBarPinned ? "pin.fill" : "pin")
        }
        .accessibilityLabel(isTopControlBarPinned ? "Unpin Toolbar" : "Pin Toolbar")
    }

    private var currentFitMode: FitMode? {
        if case let .fit(fitMode) = viewerState.zoomMode {
            return fitMode
        }

        return nil
    }

    private func menuCheckmarkLabel(_ title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }

    @ViewBuilder
    private var metadataOverlay: some View {
        if viewerState.isMetadataVisible {
            VStack {
                HStack(alignment: .top) {
                    ImageMetadataPanel(rows: viewerState.imageMetadataRows)
                    Spacer()
                }
                .padding(.leading, 18)
                .padding(.top, viewerState.isNavigationCountVisible ? 62 : 18)

                Spacer()
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var bottomControlRevealArea: some View {
        VStack {
            Spacer()

            ZStack {
                Color.clear
                    .frame(height: 112)
                    .contentShape(Rectangle())
                    .onHover { isHoveringControlRevealArea = $0 }

                if bottomControlsVisible {
                    bottomControlBar
                        .padding(.bottom, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .onHover { isHoveringControlRevealArea = $0 }
                }
            }
        }
    }

    private var topControlRevealArea: some View {
        VStack {
            ZStack(alignment: .top) {
                Color.clear
                    .frame(height: 78)
                    .contentShape(Rectangle())
                    .onHover { isHoveringTopControlRevealArea = $0 }

                topControlBar
                    .padding(.top, 8)
                    .opacity(topControlsVisible ? 1 : 0)
                    .offset(y: topControlsVisible ? 0 : -4)
                    .blur(radius: topControlsVisible ? 0 : 0.7)
                    .allowsHitTesting(topControlsVisible)
                    .onHover { isHoveringTopControlRevealArea = $0 }
            }

            Spacer()
        }
    }

    private var topControlBar: some View {
        HStack(spacing: 12) {
            toolbarInfoButton

            Divider()
                .frame(height: 24)
                .overlay(.white.opacity(0.22))

            toolbarPageLayoutMenu
            toolbarFitMenu
            toolbarSlideshowControl

            Divider()
                .frame(height: 24)
                .overlay(.white.opacity(0.22))

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

    private var bottomControlBar: some View {
        HStack(spacing: 10) {
            controlButton("Open", systemImage: "folder", action: viewerState.presentOpenSelectionPanel)

            Divider()
                .frame(height: 24)
                .overlay(.white.opacity(0.22))

            controlButton("Zoom Out", systemImage: "minus.magnifyingglass", action: viewerState.zoomOut)
            actualSizeButton
            controlButton("Zoom In", systemImage: "plus.magnifyingglass", action: viewerState.zoomIn)
            controlButton("Rotate Right", systemImage: "rotate.right", action: viewerState.rotateClockwise)

            Divider()
                .frame(height: 24)
                .overlay(.white.opacity(0.22))

            repeatingControlButton("Previous", systemImage: "chevron.left", action: viewerState.showPreviousImage)
            repeatingControlButton("Next", systemImage: "chevron.right", action: viewerState.showNextImage)

            controlButton(
                isControlBarPinned ? "Unpin Controls" : "Pin Controls",
                systemImage: isControlBarPinned ? "pin.fill" : "pin",
                action: { isControlBarPinned.toggle() }
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
                    viewerState.beginNavigationHoldIndicator()
                } else {
                    viewerState.endNavigationHoldIndicator()
                }
            }
        )
    }

    private var actualSizeButton: some View {
        Button(action: viewerState.toggleActualSize) {
            ActualSizeIcon(isActive: isActualSize)
                .frame(width: 30, height: 30)
                .background(isActualSize ? .white.opacity(0.20) : .white.opacity(0.10), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .accessibilityLabel("Actual Size")
    }

    private var isActualSize: Bool {
        if case .actualSize = viewerState.zoomMode {
            return true
        }

        return false
    }

    private func controlButton(_ accessibilityLabel: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.10), in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .accessibilityLabel(accessibilityLabel)
    }

    private var bottomControlsVisible: Bool {
        isControlBarPinned || isHoveringControlRevealArea
    }

    private var navigationCountOverlay: some View {
        VStack {
            HStack {
                ZStack {
                    Text(navigationCountSampleText)
                        .hidden()

                    Text(viewerState.navigationCountText ?? navigationCountSampleText)
                }
                .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .frame(height: 34)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(.white.opacity(0.14))
                }
                .shadow(color: .black.opacity(0.28), radius: 14, y: 7)
                .opacity(viewerState.isNavigationCountVisible ? 1 : 0)
                .scaleEffect(viewerState.isNavigationCountVisible ? 1 : 0.985, anchor: .topLeading)
                .offset(y: viewerState.isNavigationCountVisible ? 0 : -5)
                .blur(radius: viewerState.isNavigationCountVisible ? 0 : 1.1)

                Spacer()
            }
            .padding(.leading, 18)
            .padding(.top, 18)

            Spacer()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(!viewerState.isNavigationCountVisible)
    }

    private var navigationCountSampleText: String {
        let totalCount = max(viewerState.index?.imageURLs.count ?? 1, 1)
        let digitCount = max(String(totalCount).count, 1)
        let digitBlock = String(repeating: "8", count: digitCount)
        return "\(digitBlock) / \(digitBlock)"
    }

    private var topControlsVisible: Bool {
        isTopControlBarPinned || isHoveringTopControlRevealArea
    }

    private var slideshowIntervalText: String {
        "\(formattedSlideshowValue(viewerState.slideshowIntervalSeconds))s"
    }

    private func commitSlideshowIntervalDraft() {
        let normalizedText = slideshowIntervalDraft
            .replacingOccurrences(of: "s", with: "")
            .replacingOccurrences(of: "S", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let seconds = Double(normalizedText) {
            viewerState.setSlideshowInterval(seconds)
        }

        slideshowIntervalDraft = formattedSlideshowValue(viewerState.slideshowIntervalSeconds)
    }

    private func adjustSlideshowInterval(by delta: Double) {
        commitSlideshowIntervalDraft()
        viewerState.setSlideshowInterval(viewerState.slideshowIntervalSeconds + delta)
        slideshowIntervalDraft = formattedSlideshowValue(viewerState.slideshowIntervalSeconds)
    }

    private func formattedSlideshowValue(_ seconds: Double) -> String {
        if seconds.rounded() == seconds {
            return "\(Int(seconds))"
        }

        return String(format: "%.1f", seconds)
    }

    @ViewBuilder
    private var transientNoticeOverlay: some View {
        if let notice = viewerState.transientNotice {
            VStack {
                Text(notice.message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(.white.opacity(0.14))
                    }
                    .shadow(color: .black.opacity(0.28), radius: 14, y: 7)
                    .padding(.top, 18)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                Spacer()
            }
            .allowsHitTesting(false)
        }
    }

    private func scheduleTransientNoticeDismissal(for noticeID: ViewerTransientNotice.ID?) {
        transientNoticeDismissTask?.cancel()

        guard let noticeID else { return }
        transientNoticeDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.45))
            guard !Task.isCancelled else { return }
            viewerState.clearTransientNotice(id: noticeID)
        }
    }

    @ViewBuilder
    private func overlayCard(for kind: OverlayKind) -> some View {
        VStack(spacing: 12) {
            Image(systemName: kind.symbolName)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.secondary)
            Text(kind.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(kind.message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Open...", action: viewerState.presentOpenSelectionPanel)

                if case .error = kind {
                    Button("Dismiss", action: viewerState.clearError)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        }
        .frame(maxWidth: 360)
        .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
    }

    private var hasImage: Bool {
        viewerState.currentImageURL != nil
    }

    private var overlayKind: OverlayKind? {
        if let errorMessage = viewerState.lastErrorMessage {
            return .error(message: errorMessage)
        }

        guard !hasImage else { return nil }
        return .empty
    }
}

private struct SlideshowIntervalField: NSViewRepresentable {
    @Binding var text: String
    let onCommit: () -> Void
    let onStep: (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WheelTextFieldContainer {
        let view = WheelTextFieldContainer()
        view.textField.delegate = context.coordinator
        view.onStep = onStep
        configure(view.textField)
        view.textField.stringValue = text
        return view
    }

    func updateNSView(_ nsView: WheelTextFieldContainer, context: Context) {
        context.coordinator.parent = self
        nsView.onStep = onStep
        configure(nsView.textField)

        let isEditing = nsView.window?.firstResponder === nsView.textField.currentEditor()
        if !isEditing, nsView.textField.stringValue != text {
            nsView.textField.stringValue = text
        }
    }

    private func configure(_ textField: NSTextField) {
        if !(textField.cell is CleanIntervalTextFieldCell) {
            textField.cell = CleanIntervalTextFieldCell(textCell: textField.stringValue)
        }

        textField.isBordered = false
        textField.drawsBackground = false
        textField.isBezeled = false
        textField.focusRingType = .none
        textField.alignment = .center
        textField.textColor = .white
        textField.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        textField.cell?.sendsActionOnEndEditing = true
        textField.maximumNumberOfLines = 1
        textField.lineBreakMode = .byClipping
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: SlideshowIntervalField

        init(_ parent: SlideshowIntervalField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            parent.onCommit()
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
            parent.text = textView.string
            parent.onCommit()
            control.window?.makeFirstResponder(nil)
            return true
        }
    }
}

private final class CleanIntervalTextFieldCell: NSTextFieldCell {
    override init(textCell string: String) {
        super.init(textCell: string)
        configure()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isScrollable = true
        usesSingleLineMode = true
        wraps = false
        lineBreakMode = .byClipping
    }

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        verticallyCenteredRect(forBounds: rect)
    }

    override func titleRect(forBounds rect: NSRect) -> NSRect {
        verticallyCenteredRect(forBounds: rect)
    }

    private func verticallyCenteredRect(forBounds rect: NSRect) -> NSRect {
        guard let font else { return rect }

        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        let yOffset = floor((rect.height - lineHeight) / 2)
        return NSRect(x: rect.minX, y: rect.minY + yOffset - 0.5, width: rect.width, height: lineHeight)
    }
}

private final class WheelTextFieldContainer: NSView {
    let textField = NSTextField()
    var onStep: ((Double) -> Void)?
    private var preciseScrollRemainder: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(textField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        textField.frame = bounds
    }

    override func scrollWheel(with event: NSEvent) {
        let delta = event.hasPreciseScrollingDeltas ? -event.scrollingDeltaY : event.scrollingDeltaY
        guard abs(delta) > 0 else { return }

        if event.hasPreciseScrollingDeltas {
            preciseScrollRemainder += delta
            guard abs(preciseScrollRemainder) >= 8 else { return }
            onStep?(preciseScrollRemainder > 0 ? 0.5 : -0.5)
            preciseScrollRemainder = 0
            return
        }

        onStep?(delta > 0 ? 0.5 : -0.5)
    }
}

private struct VerticalSlideshowPreview: View {
    let intervalSeconds: Double

    private let previewSize = CGSize(width: 42, height: 30)
    private let pageSize = CGSize(width: 24, height: 18)
    private let pageGap: CGFloat = 5

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = animationPhase(at: timeline.date)

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.08))

                ForEach(-2..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(.white.opacity(index.isMultiple(of: 2) ? 0.84 : 0.62))
                        .overlay(alignment: .top) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(.black.opacity(0.12))
                                .frame(width: pageSize.width - 8, height: 2.5)
                                .padding(.top, 4)
                        }
                        .frame(width: pageSize.width, height: pageSize.height)
                        .offset(y: CGFloat(index) * (pageSize.height + pageGap) + phase)
                }

                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.20)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 8)
                }
            }
            .frame(width: previewSize.width, height: previewSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(0.14))
            }
            .accessibilityLabel("Vertical slideshow motion preview")
        }
    }

    private func animationPhase(at date: Date) -> CGFloat {
        let clampedSeconds = max(intervalSeconds, ViewerState.minimumSlideshowIntervalSeconds)
        let cycle = pageSize.height + pageGap
        let previewPointsPerSecond = CGFloat(640.0 / clampedSeconds) / 18
        let progress = date.timeIntervalSinceReferenceDate * previewPointsPerSecond
        return CGFloat(progress.truncatingRemainder(dividingBy: Double(cycle))) - cycle
    }
}

private struct ImageMetadataPanel: View {
    let rows: [ImageMetadataRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image Info")
                .font(.headline)

            ForEach(rows) { row in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(row.label)
                        .foregroundStyle(.secondary)
                        .frame(width: 76, alignment: .leading)

                    Text(row.value)
                        .lineLimit(row.label == "Folder" ? 2 : 1)
                        .truncationMode(.middle)
                }
                .font(.caption)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(width: 360, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.14))
        }
        .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
    }
}

private struct RepeatingControlButton: View {
    let accessibilityLabel: String
    let systemImage: String
    let action: () -> Void
    let onHoldChange: (Bool) -> Void

    @State private var isPressed = false
    @State private var didStartRepeating = false
    @State private var repeatTask: Task<Void, Never>?

    private static let initialDelay: Duration = .milliseconds(500)

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 30, height: 30)
            .background(.white.opacity(isPressed ? 0.18 : 0.10), in: Circle())
            .foregroundStyle(.white)
            .contentShape(Circle())
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        beginPressIfNeeded()
                    }
                    .onEnded { _ in
                        endPress()
                    }
            )
            .onDisappear {
                cancelRepeat()
            }
    }

    private func beginPressIfNeeded() {
        guard !isPressed else { return }

        isPressed = true
        didStartRepeating = false
        repeatTask?.cancel()
        repeatTask = Task { @MainActor in
            try? await Task.sleep(for: Self.initialDelay)
            guard !Task.isCancelled else { return }

            didStartRepeating = true
            onHoldChange(true)
            while !Task.isCancelled {
                action()
                try? await Task.sleep(for: .seconds(Self.keyRepeatIntervalSeconds))
            }
        }
    }

    private func endPress() {
        let shouldPerformSingleClick = isPressed && !didStartRepeating
        cancelRepeat()

        if shouldPerformSingleClick {
            action()
        }
    }

    private func cancelRepeat() {
        let shouldEndHold = didStartRepeating
        repeatTask?.cancel()
        repeatTask = nil
        isPressed = false
        didStartRepeating = false

        if shouldEndHold {
            onHoldChange(false)
        }
    }

    private static var keyRepeatIntervalSeconds: Double {
        let ticks = UserDefaults.standard.double(forKey: "KeyRepeat")
        let fallbackTicks = 3.0
        return max((ticks > 0 ? ticks : fallbackTicks) / 60.0, 1.0 / 60.0)
    }
}

private enum OverlayKind {
    case empty
    case error(message: String)

    var symbolName: String {
        switch self {
        case .empty:
            "photo"
        case .error:
            "exclamationmark.triangle"
        }
    }

    var title: String {
        switch self {
        case .empty:
            "Open an Image to Begin"
        case .error:
            "Unable to Open Selection"
        }
    }

    var message: String {
        switch self {
        case .empty:
            "Open an image file or folder to start browsing."
        case let .error(message):
            message
        }
    }
}

private struct ActualSizeIcon: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .frame(width: 9.5, height: 9.5)
                .offset(x: -2.5, y: -2.5)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
        }
        .opacity(isActive ? 1.0 : 0.92)
        .frame(width: 30, height: 30)
    }
}
