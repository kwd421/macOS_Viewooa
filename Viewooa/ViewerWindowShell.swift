import AppKit
import ImageIO
import QuickLookThumbnailing
import SwiftUI
import UniformTypeIdentifiers

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

            if hasImage, !viewerState.isImageBrowserVisible, !viewerState.isOpenBrowserVisible {
                topControlRevealArea
                navigationCountOverlay
                metadataOverlay
                bottomControlRevealArea
            }

            if viewerState.isImageBrowserVisible {
                ImageBrowserOverlay(
                    imageURLs: viewerState.browserImageURLs,
                    currentIndex: viewerState.currentBrowserIndex,
                    displayMode: Binding(
                        get: { viewerState.imageBrowserDisplayMode },
                        set: { viewerState.setImageBrowserDisplayMode($0) }
                    ),
                    thumbnailSize: Binding(
                        get: { viewerState.imageBrowserThumbnailSize },
                        set: { viewerState.setImageBrowserThumbnailSize($0) }
                    ),
                    onSelect: viewerState.selectImageFromBrowser,
                    onDismiss: viewerState.hideImageBrowser
                )
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
                .zIndex(10)
            }

            if viewerState.isOpenBrowserVisible {
                OpenBrowserOverlay(
                    initialDirectory: initialOpenBrowserDirectory,
                    displayMode: Binding(
                        get: { viewerState.imageBrowserDisplayMode },
                        set: { viewerState.setImageBrowserDisplayMode($0) }
                    ),
                    thumbnailSize: Binding(
                        get: { viewerState.imageBrowserThumbnailSize },
                        set: { viewerState.setImageBrowserThumbnailSize($0) }
                    ),
                    onOpen: viewerState.openSelectionFromBrowser,
                    onDismiss: viewerState.hideOpenBrowser
                )
                .ignoresSafeArea()
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
                .zIndex(11)
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
        .animation(.smooth(duration: 0.24, extraBounce: 0), value: viewerState.isImageBrowserVisible)
        .animation(.smooth(duration: 0.24, extraBounce: 0), value: viewerState.isOpenBrowserVisible)
        .onChange(of: viewerState.transientNotice?.id) { _, noticeID in
            scheduleTransientNoticeDismissal(for: noticeID)
        }
        .onChange(of: viewerState.slideshowIntervalSeconds) { _, seconds in
            slideshowIntervalDraft = formattedSlideshowValue(seconds)
        }
        .onDisappear {
            transientNoticeDismissTask?.cancel()
        }
        .background(WindowChromeConfigurator())
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
            menuSelectionToggle("Single Page", isSelected: viewerState.pageLayout == .single) {
                viewerState.setPageLayout(.single)
            }

            Divider()

            menuSelectionToggle("Two Pages: L-R", isSelected: viewerState.pageLayout == .spread && viewerState.spreadDirection == .leftToRight) {
                viewerState.setSpreadDirection(.leftToRight)
                viewerState.setPageLayout(.spread)
            }

            menuSelectionToggle("Two Pages: R-L", isSelected: viewerState.pageLayout == .spread && viewerState.spreadDirection == .rightToLeft) {
                viewerState.setSpreadDirection(.rightToLeft)
                viewerState.setPageLayout(.spread)
            }

            menuSelectionToggle("Cover Mode", isSelected: viewerState.isCoverModeEnabled) {
                viewerState.toggleCoverMode()
            }
            .disabled(viewerState.pageLayout != .spread)

            Divider()

            menuSelectionToggle("Vertical Strip", isSelected: viewerState.pageLayout == .verticalStrip) {
                viewerState.setPageLayout(.verticalStrip)
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
                menuSelectionToggle(fitMode.title, isSelected: currentFitMode == fitMode) {
                    viewerState.fitToWindow(fitMode)
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

    private func menuSelectionToggle(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Toggle(title, isOn: Binding(
            get: { isSelected },
            set: { newValue in
                guard newValue || isSelected else { return }
                action()
            }
        ))
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
        return HStack(spacing: 10) {
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

            repeatingControlButton("Previous", systemImage: "chevron.left", action: viewerState.showPreviousImageFromNavigationShortcut)
            repeatingControlButton("Next", systemImage: "chevron.right", action: viewerState.showNextImageFromNavigationShortcut)

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

    private var initialOpenBrowserDirectory: URL {
        guard let directory = viewerState.currentImageURL?.deletingLastPathComponent() else {
            return FileManager.default.homeDirectoryForCurrentUser
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return FileManager.default.homeDirectoryForCurrentUser
        }

        return directory
    }

    private var overlayKind: OverlayKind? {
        if let errorMessage = viewerState.lastErrorMessage {
            return .error(message: errorMessage)
        }

        guard !viewerState.isOpenBrowserVisible else { return nil }
        guard !hasImage else { return nil }
        return .empty
    }
}

private struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(window: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        alignTrafficLights(in: window)
    }

    private func alignTrafficLights(in window: NSWindow) {
        guard let closeButton = window.standardWindowButton(.closeButton),
              let minimizeButton = window.standardWindowButton(.miniaturizeButton),
              let zoomButton = window.standardWindowButton(.zoomButton),
              let buttonContainer = closeButton.superview else {
            return
        }

        let topPadding: CGFloat = 16
        let leftPadding: CGFloat = 16
        let spacing = minimizeButton.frame.minX - closeButton.frame.minX
        let y = buttonContainer.bounds.height - topPadding - closeButton.frame.height

        closeButton.setFrameOrigin(NSPoint(x: leftPadding, y: y))
        minimizeButton.setFrameOrigin(NSPoint(x: leftPadding + spacing, y: y))
        zoomButton.setFrameOrigin(NSPoint(x: leftPadding + spacing * 2, y: y))
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

private struct ImageBrowserOverlay: View {
    let imageURLs: [URL]
    let currentIndex: Int?
    @Binding var displayMode: ImageBrowserDisplayMode
    @Binding var thumbnailSize: CGFloat
    let onSelect: (Int) -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isContentRevealed = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.34))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Divider()
                    .overlay(.white.opacity(0.16))
                    .padding(.horizontal, 28)
                    .opacity(isContentRevealed || reduceMotion ? 1 : 0)

                ScrollViewReader { proxy in
                    ScrollView {
                        content
                            .padding(.horizontal, 30)
                            .padding(.top, 24)
                            .padding(.bottom, 34)
                    }
                    .scrollIndicators(.hidden)
                    .onAppear {
                        scrollToCurrentImage(with: proxy)
                    }
                    .onChange(of: displayMode) { _, _ in
                        revealContent()
                        scrollToCurrentImage(with: proxy)
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .onAppear(perform: revealContent)
        .overlay {
            ImageBrowserEscapeCatcher(onEscape: onDismiss)
                .frame(width: 0, height: 0)
        }
        .onExitCommand(perform: onDismiss)
        .accessibilityLabel("Image Browser")
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close Image Browser")

            VStack(alignment: .leading, spacing: 2) {
                Text("Images")
                    .font(.system(size: 16, weight: .semibold))
                Text(browserPositionText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            ThumbnailSizeStepperControl(thumbnailSize: $thumbnailSize, isVibrant: true)

            ImageBrowserViewModeControl(displayMode: $displayMode)
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .opacity(isContentRevealed || reduceMotion ? 1 : 0)
        .offset(y: isContentRevealed || reduceMotion ? 0 : -10)
        .animation(.smooth(duration: 0.32, extraBounce: 0), value: isContentRevealed)
    }

    @ViewBuilder
    private var content: some View {
        switch displayMode {
        case .thumbnails:
            thumbnailGrid
        case .list:
            listView
        }
    }

    private var thumbnailGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: thumbnailSize, maximum: thumbnailSize), spacing: 18)],
            alignment: .center,
            spacing: 22
        ) {
            ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                ImageBrowserThumbnailCell(
                    url: url,
                    index: index,
                    thumbnailSize: thumbnailSize,
                    isSelected: index == currentIndex,
                    isRevealed: isContentRevealed,
                    reduceMotion: reduceMotion,
                    onSelect: onSelect
                )
                .id(index)
            }
        }
    }

    private var listView: some View {
        LazyVStack(spacing: 6) {
            ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                ImageBrowserListRow(
                    url: url,
                    index: index,
                    isSelected: index == currentIndex,
                    isRevealed: isContentRevealed,
                    reduceMotion: reduceMotion,
                    onSelect: onSelect
                )
                .id(index)
            }
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
    }

    private var browserPositionText: String {
        guard let currentIndex else {
            return "\(imageURLs.count) images"
        }

        return "\(currentIndex + 1) of \(imageURLs.count)"
    }

    private func scrollToCurrentImage(with proxy: ScrollViewProxy) {
        guard let currentIndex else { return }
        DispatchQueue.main.async {
            withAnimation(.smooth(duration: 0.36, extraBounce: 0)) {
                proxy.scrollTo(currentIndex, anchor: .center)
            }
        }
    }

    private func revealContent() {
        guard !reduceMotion else {
            isContentRevealed = true
            return
        }

        isContentRevealed = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.035) {
            isContentRevealed = true
        }
    }
}

private struct ImageBrowserViewModeControl: View {
    @Binding var displayMode: ImageBrowserDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImageBrowserDisplayMode.allCases) { mode in
                Button {
                    displayMode = mode
                } label: {
                    Image(systemName: mode.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 32, height: 26)
                        .foregroundStyle(displayMode == mode ? .white : .white.opacity(0.58))
                        .background(
                            displayMode == mode ? .white.opacity(0.18) : .clear,
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.title)
            }
        }
        .padding(2)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ThumbnailSizeStepperControl: View {
    @Binding var thumbnailSize: CGFloat
    let isVibrant: Bool
    var availableWidth: CGFloat? = nil
    var onWillChange: (() -> Void)? = nil

    private let range: ClosedRange<CGFloat> = 72...220
    private let step: CGFloat = 18
    private let gridSpacing: CGFloat = 18
    private let minimumMeaningfulStep: CGFloat = 18

    var body: some View {
        HStack(spacing: 0) {
            stepButton(systemImage: "minus", delta: -step, isDisabled: !canStep(delta: -step))

            Rectangle()
                .fill(separatorColor)
                .frame(width: 1, height: 15)

            stepButton(systemImage: "plus", delta: step, isDisabled: !canStep(delta: step))
        }
        .frame(height: isVibrant ? 30 : 34)
        .background {
            RoundedRectangle(cornerRadius: isVibrant ? 15 : 17, style: .continuous)
                .fill(isVibrant ? Color.white.opacity(0.10) : Color.openBrowserControlFill)
        }
        .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 17, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Thumbnail Size")
    }

    private func stepButton(systemImage: String, delta: CGFloat, isDisabled: Bool) -> some View {
        Button {
            onWillChange?()
            withAnimation(.smooth(duration: 0.18, extraBounce: 0)) {
                thumbnailSize = nextThumbnailSize(delta: delta)
            }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: isVibrant ? 32 : 38, height: isVibrant ? 30 : 34)
                .foregroundStyle(buttonColor(isDisabled: isDisabled))
                .contentShape(Rectangle())
        }
        .frame(width: isVibrant ? 32 : 38, height: isVibrant ? 30 : 34)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(delta < 0 ? "Smaller Thumbnails" : "Larger Thumbnails")
    }

    private var separatorColor: Color {
        isVibrant ? Color.white.opacity(0.18) : Color.openBrowserSeparator.opacity(0.65)
    }

    private func buttonColor(isDisabled: Bool) -> Color {
        if isDisabled {
            return isVibrant ? Color.white.opacity(0.24) : Color.secondary.opacity(0.28)
        }
        return isVibrant ? Color.white.opacity(0.78) : Color.secondary
    }

    private func nextThumbnailSize(delta: CGFloat) -> CGFloat {
        guard let availableWidth, availableWidth > range.lowerBound else {
            return clamped(thumbnailSize + delta)
        }

        let currentColumns = columnCount(for: thumbnailSize, availableWidth: availableWidth)
        let targetColumns = delta > 0 ? max(1, currentColumns - 1) : currentColumns + 1
        let targetSize = (availableWidth - gridSpacing * CGFloat(max(targetColumns - 1, 0))) / CGFloat(targetColumns)
        let clampedTargetSize = clamped(targetSize)

        guard abs(clampedTargetSize - thumbnailSize) >= minimumMeaningfulStep else {
            return thumbnailSize
        }

        return clampedTargetSize
    }

    private func canStep(delta: CGFloat) -> Bool {
        abs(nextThumbnailSize(delta: delta) - thumbnailSize) >= minimumMeaningfulStep
    }

    private func columnCount(for size: CGFloat, availableWidth: CGFloat) -> Int {
        max(1, Int(floor((availableWidth + gridSpacing) / (size + gridSpacing))))
    }

    private func clamped(_ size: CGFloat) -> CGFloat {
        min(max(size, range.lowerBound), range.upperBound)
    }
}

private enum OpenBrowserScrollCoordinateSpace {
    static let name = "OpenBrowserScrollCoordinateSpace"
}

private struct OpenBrowserVisibleEntryFramePreferenceKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct OpenBrowserResizeAnchor: Equatable {
    let id: String
    let minY: CGFloat
}

private struct OpenBrowserScrollViewResolver: NSViewRepresentable {
    let onResolve: (NSScrollView) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        resolve(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        resolve(from: nsView)
    }

    private func resolve(from view: NSView) {
        DispatchQueue.main.async {
            if let scrollView = view.enclosingScrollView {
                onResolve(scrollView)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                    if let scrollView = view.enclosingScrollView {
                        onResolve(scrollView)
                    }
                }
            }
        }
    }
}

private extension View {
    func openBrowserVisibleEntryFrame(id: String) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: OpenBrowserVisibleEntryFramePreferenceKey.self,
                    value: [id: proxy.frame(in: .named(OpenBrowserScrollCoordinateSpace.name))]
                )
            }
        }
    }
}

private struct OpenBrowserOverlay: View {
    let initialDirectory: URL
    @Binding var displayMode: ImageBrowserDisplayMode
    @Binding var thumbnailSize: CGFloat
    let onOpen: (URL) -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentDirectory: URL
    @State private var entries: [OpenBrowserEntry] = []
    @State private var searchText = ""
    @State private var sortOption = OpenBrowserSortOption.name
    @State private var sortAscending = true
    @State private var selectedEntryIDs: Set<String> = []
    @State private var focusedEntryID: String?
    @State private var anchorEntryID: String?
    @State private var favoriteFileIDs: Set<String> = []
    @State private var customFavoriteFolders: [OpenBrowserSidebarItem] = []
    @State private var hiddenFavoriteSidebarIDs: Set<String> = []
    @State private var favoriteSidebarOrder: [String] = []
    @State private var draggingSidebarItemID: String?
    @State private var accessErrorMessage: String?
    @State private var isSidebarVisible = true
    @State private var sidebarWidth: CGFloat = Self.defaultSidebarWidth
    @State private var sidebarDragStartWidth: CGFloat?
    @State private var isContentRevealed = false
    @State private var backHistory: [URL] = []
    @State private var forwardHistory: [URL] = []
    @State private var isSearchExpanded = false
    @State private var searchExpansionExtra: CGFloat = 0
    @State private var thumbnailScrollAnchorID: String?
    @State private var visibleEntryFrames: [String: CGRect] = [:]
    @State private var scrollViewportSize: CGSize = .zero
    @State private var openBrowserScrollView: NSScrollView?
    @State private var pendingThumbnailResizeAnchor: OpenBrowserResizeAnchor?
    @State private var isPathEditing = false
    @State private var editablePath = ""
    @FocusState private var isPathEditorFocused: Bool
    @FocusState private var isSearchFieldFocused: Bool

    init(
        initialDirectory: URL,
        displayMode: Binding<ImageBrowserDisplayMode>,
        thumbnailSize: Binding<CGFloat>,
        onOpen: @escaping (URL) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.initialDirectory = initialDirectory
        self._displayMode = displayMode
        self._thumbnailSize = thumbnailSize
        self.onOpen = onOpen
        self.onDismiss = onDismiss
        let savedDirectory = Self.savedDirectoryURL() ?? initialDirectory
        self._currentDirectory = State(initialValue: Self.validDirectory(savedDirectory) ?? initialDirectory)
        self._isSidebarVisible = State(initialValue: UserDefaults.standard.object(forKey: Self.sidebarVisibilityDefaultsKey) as? Bool ?? true)
        let savedSidebarWidth = UserDefaults.standard.double(forKey: Self.sidebarWidthDefaultsKey)
        let initialSidebarWidth = abs(savedSidebarWidth - Self.previousDefaultSidebarWidth) < 0.5 ? Self.defaultSidebarWidth : (savedSidebarWidth > 0 ? CGFloat(savedSidebarWidth) : Self.defaultSidebarWidth)
        self._sidebarWidth = State(initialValue: Self.clampedSidebarWidth(initialSidebarWidth))
        self._sortOption = State(initialValue: OpenBrowserSortOption(rawValue: UserDefaults.standard.string(forKey: Self.sortOptionDefaultsKey) ?? "") ?? .name)
        self._sortAscending = State(initialValue: UserDefaults.standard.object(forKey: Self.sortAscendingDefaultsKey) as? Bool ?? true)
        self._favoriteFileIDs = State(initialValue: Set(UserDefaults.standard.stringArray(forKey: Self.favoriteFilesDefaultsKey) ?? []))
        self._customFavoriteFolders = State(initialValue: Self.loadCustomFavoriteFolders())
        self._hiddenFavoriteSidebarIDs = State(initialValue: Set(UserDefaults.standard.stringArray(forKey: Self.hiddenFavoriteSidebarDefaultsKey) ?? []))
        self._favoriteSidebarOrder = State(initialValue: UserDefaults.standard.stringArray(forKey: Self.favoriteSidebarOrderDefaultsKey) ?? [])
    }

    var body: some View {
        AnyView(browserContent.foregroundStyle(.primary))
            .ignoresSafeArea(.container, edges: .top)
            .onAppear(perform: handleAppear)
            .onChange(of: currentDirectory) { _, _ in handleDirectoryChange() }
            .onChange(of: searchText) { _, value in handleSearchChange(value) }
            .onChange(of: sortOption) { _, value in handleSortOptionChange(value) }
            .onChange(of: sortAscending) { _, value in handleSortAscendingChange(value) }
            .onChange(of: isSidebarVisible) { _, value in handleSidebarVisibilityChange(value) }
            .onChange(of: sidebarWidth) { _, value in handleSidebarWidthChange(value) }
            .onChange(of: thumbnailSize) { _, value in handleThumbnailSizeChange(value) }
            .onChange(of: displayMode) { _, value in handleDisplayModeChange(value) }
            .onChange(of: isSearchExpanded) { _, value in handleSearchExpansionChange(value) }
            .onChange(of: isSearchFieldFocused) { _, value in handleSearchFocusChange(value) }
            .overlay {
                OpenBrowserKeyboardCatcher(
                    onEscape: handleEscape,
                    onSelectAll: selectAllVisibleEntries,
                    onOpen: openFocusedOrFirstSelectedEntry,
                    onParent: navigateToParent
                )
                    .frame(width: 0, height: 0)
            }
            .onExitCommand(perform: handleEscape)
            .accessibilityLabel("Open Browser")
    }

    private var browserContent: some View {
        GeometryReader { proxy in
            let footerHeight = Self.footerHeight
            let sidebarTotalWidth = isSidebarVisible ? sidebarWidth + Self.sidebarHandleWidth : 0

            ZStack {
                Rectangle()
                    .fill(Color.openBrowserWindowBackground)
                    .ignoresSafeArea()

                HStack(spacing: 0) {
                    if isSidebarVisible {
                        sidebar
                            .frame(width: sidebarWidth)
                            .transition(.move(edge: .leading).combined(with: .opacity))

                        sidebarResizeHandle
                    }

                    contentPane(
                        availableWidth: proxy.size.width,
                        sidebarTotalWidth: sidebarTotalWidth
                    )
                }
                .padding(.bottom, footerHeight)

                titlebarChrome(
                    availableWidth: proxy.size.width,
                    sidebarTotalWidth: sidebarTotalWidth
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .zIndex(3)

                footerBar
                    .frame(height: footerHeight)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .zIndex(3)
            }
        }
    }

    private func contentPane(availableWidth: CGFloat, sidebarTotalWidth: CGFloat) -> some View {
        GeometryReader { viewportProxy in
            ScrollViewReader { proxy in
                ScrollView {
                    content
                        .background {
                            OpenBrowserScrollViewResolver { scrollView in
                                openBrowserScrollView = scrollView
                            }
                            .frame(width: 0, height: 0)
                        }
                        .padding(.horizontal, Self.contentHorizontalPadding(for: availableWidth - sidebarTotalWidth, isSidebarVisible: false))
                        .padding(.top, Self.contentTopInset)
                        .padding(.bottom, 24)
                }
                .coordinateSpace(name: OpenBrowserScrollCoordinateSpace.name)
                .scrollIndicators(.hidden)
                .onAppear {
                    scrollViewportSize = viewportProxy.size
                }
                .onChange(of: viewportProxy.size) { _, size in
                    scrollViewportSize = size
                }
                .onPreferenceChange(OpenBrowserVisibleEntryFramePreferenceKey.self) { frames in
                    visibleEntryFrames = frames
                    adjustScrollForPendingThumbnailResize(with: frames)
                }
                .onChange(of: thumbnailSize) { _, _ in
                    scrollToThumbnailAnchor(with: proxy)
                }
            }
        }
        .background(Color.openBrowserContentBackground)
    }

    private func titlebarChrome(availableWidth: CGFloat, sidebarTotalWidth: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if isSidebarVisible {
                sidebarHeaderGroup
                    .frame(width: sidebarTotalWidth, alignment: .trailing)

                historyToolbarGroup
            } else {
                leadingToolbarGroup
            }

            contentTitleGroup
                .layoutPriority(1)

            Spacer(minLength: 10)

            trailingToolbarGroup(availableWidth: availableWidth - sidebarTotalWidth)
        }
        .padding(.leading, isSidebarVisible ? 0 : Self.collapsedSidebarLeadingInset)
        .padding(.trailing, 13)
        .padding(.top, Self.titlebarChromeTopInset)
        .opacity(isContentRevealed || reduceMotion ? 1 : 0)
        .offset(y: isContentRevealed || reduceMotion ? 0 : -10)
        .animation(.smooth(duration: 0.32, extraBounce: 0), value: isContentRevealed)
    }

    private var sidebarHeaderGroup: some View {
        HStack(spacing: 0) {
            iconToolbarButton(
                "Hide Sidebar",
                systemImage: "sidebar.left",
                isActive: true
            ) {
                withAnimation(.smooth(duration: 0.22, extraBounce: 0)) {
                    isSidebarVisible = false
                }
            }
        }
        .padding(1)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(Color.openBrowserSeparator.opacity(0.18))
        }
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .padding(.trailing, 9)
    }

    private var leadingToolbarGroup: some View {
        HStack(spacing: 3) {
            iconToolbarButton(
                isSidebarVisible ? "Hide Sidebar" : "Show Sidebar",
                systemImage: "sidebar.left",
                isActive: isSidebarVisible
            ) {
                withAnimation(.smooth(duration: 0.22, extraBounce: 0)) {
                    isSidebarVisible.toggle()
                }
            }

            Divider()
                .frame(height: 22)
                .overlay(Color.openBrowserSeparator.opacity(0.42))

            historyButtons
        }
        .padding(1)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(Color.openBrowserSeparator.opacity(0.18))
        }
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private var historyToolbarGroup: some View {
        HStack(spacing: 2) {
            historyButtons
        }
        .padding(1)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(Color.openBrowserSeparator.opacity(0.18))
        }
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private var historyButtons: some View {
        HStack(spacing: 0) {
            iconToolbarButton("Back", systemImage: "chevron.left") {
                navigateBack()
            }
            .disabled(backHistory.isEmpty)
            .opacity(backHistory.isEmpty ? 0.35 : 1)

            iconToolbarButton("Forward", systemImage: "chevron.right") {
                navigateForward()
            }
            .disabled(forwardHistory.isEmpty)
            .opacity(forwardHistory.isEmpty ? 0.35 : 1)
        }
    }

    private var contentTitleGroup: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(currentFolderTitle)
                .font(.system(size: 18, weight: .semibold))
                .lineLimit(1)

            Text(statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.top, 3)
        .shadow(color: Color.openBrowserContentBackground.opacity(0.75), radius: 6)
    }

    private func trailingToolbarGroup(availableWidth: CGFloat) -> some View {
        let searchWidth = min(max(availableWidth * 0.34, 220), 340)

        return HStack(spacing: 8) {
            if isSearchExpanded {
                toolbarCapsule {
                    searchField(width: searchWidth + searchExpansionExtra, isVibrant: true) {
                        closeSearch()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .scale(scale: 0.92, anchor: .trailing).combined(with: .opacity)
                ))
            } else {
                toolbarCapsule {
                    ThumbnailSizeStepperControl(
                        thumbnailSize: $thumbnailSize,
                        isVibrant: true,
                        availableWidth: availableWidth - Self.openBrowserGridHorizontalPadding * 2,
                        onWillChange: prepareThumbnailResizeAnchor
                    )
                }

                toolbarCapsule {
                    HStack(spacing: 2) {
                        OpenBrowserViewModeControl(displayMode: $displayMode, isVibrant: true)

                        sortMenu(isVibrant: true)

                        browserActionMenu(isVibrant: true)
                    }
                }

                searchIconButton()
                    .transition(.scale(scale: 0.88, anchor: .trailing).combined(with: .opacity))
            }
        }
        .animation(Self.searchOpenAnimation, value: isSearchExpanded)
        .animation(Self.searchSettleAnimation, value: searchExpansionExtra)
    }

    private func toolbarCapsule<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 0) {
            content()
        }
        .padding(1)
        .frame(height: Self.titlebarControlHeight)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule().strokeBorder(Color.openBrowserSeparator.opacity(0.18))
        }
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private func iconToolbarButton(
        _ accessibilityLabel: String,
        systemImage: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12.5, weight: .semibold))
                .frame(width: Self.titlebarButtonSize, height: Self.titlebarButtonSize)
                .foregroundStyle(isActive ? Color.openBrowserSelection : .secondary)
                .contentShape(RoundedRectangle(cornerRadius: Self.titlebarButtonSize / 2, style: .continuous))
        }
        .frame(width: Self.titlebarButtonSize, height: Self.titlebarButtonSize)
        .contentShape(RoundedRectangle(cornerRadius: Self.titlebarButtonSize / 2, style: .continuous))
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var sidebarResizeHandle: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: Self.sidebarHandleWidth)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.openBrowserSeparator.opacity(0.55))
                    .frame(width: 1)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let startWidth = sidebarDragStartWidth ?? sidebarWidth
                        sidebarDragStartWidth = startWidth
                        sidebarWidth = Self.clampedSidebarWidth(startWidth + value.translation.width)
                    }
                    .onEnded { _ in
                        sidebarDragStartWidth = nil
                    }
            )
            .accessibilityLabel("Resize Sidebar")
    }

    private func searchIconButton() -> some View {
        Button {
            openSearch()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white.opacity(searchText.isEmpty ? 0.82 : 1))
                .frame(width: Self.titlebarControlHeight, height: Self.titlebarControlHeight)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(Color.openBrowserSeparator.opacity(0.18))
                }
                .contentShape(Circle())
        }
        .frame(width: Self.titlebarControlHeight, height: Self.titlebarControlHeight)
        .contentShape(Circle())
        .buttonStyle(.plain)
        .accessibilityLabel("Search")
    }

    private func searchField(width: CGFloat, isVibrant: Bool = false, onClose: (() -> Void)? = nil) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isVibrant ? Color.white.opacity(0.76) : .secondary)

            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .frame(width: width)
                .focused($isSearchFieldFocused)

            if !searchText.isEmpty || onClose != nil {
                Button {
                    searchText = ""
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear Search")
            }
        }
        .padding(.horizontal, 9)
        .frame(height: isVibrant ? 32 : 28)
        .background(
            isVibrant ? Color.white.opacity(0.08) : Color.openBrowserControlFill,
            in: RoundedRectangle(cornerRadius: isVibrant ? 16 : 7, style: .continuous)
        )
    }

    private func sortMenu(isVibrant: Bool = false) -> some View {
        Menu {
            ForEach(OpenBrowserSortOption.allCases) { option in
                Button {
                    sortOption = option
                } label: {
                    Label(option.title, systemImage: sortOption == option ? "checkmark" : "")
                }
            }

            Divider()

            Button {
                sortAscending.toggle()
            } label: {
                Label(sortAscending ? "Ascending" : "Descending", systemImage: sortAscending ? "arrow.up" : "arrow.down")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isVibrant ? Color.white.opacity(0.82) : .secondary)
                .frame(width: isVibrant ? 31 : 28, height: isVibrant ? 30 : 28)
                .background(
                    isVibrant ? Color.clear : Color.openBrowserControlFill,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous))
        }
        .frame(width: isVibrant ? 31 : 28, height: isVibrant ? 30 : 28)
        .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous))
        .menuStyle(.borderlessButton)
        .accessibilityLabel("Sort")
    }

    private func browserActionMenu(isVibrant: Bool = false) -> some View {
        Menu {
            Button("Share...") {
                shareEntries(selectedEntries.filter { !$0.isDirectory })
            }
            .disabled(selectedEntries.filter { !$0.isDirectory }.isEmpty)

            Button("Favorite") {
                selectedEntries.filter { !$0.isDirectory }.forEach(toggleFavorite)
            }
            .disabled(selectedEntries.filter { !$0.isDirectory }.isEmpty)

            Divider()

            Button("Add Current Folder to Sidebar") {
                addCurrentFolderToFavorites()
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isVibrant ? Color.white.opacity(0.82) : .secondary)
                .frame(width: isVibrant ? 31 : 28, height: isVibrant ? 30 : 28)
                .background(
                    isVibrant ? Color.clear : Color.openBrowserControlFill,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous))
        }
        .frame(width: isVibrant ? 31 : 28, height: isVibrant ? 30 : 28)
        .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 7, style: .continuous))
        .menuStyle(.borderlessButton)
        .accessibilityLabel("Actions")
    }

    private func handleAppear() {
        restoreBrowserPreferences()
        loadEntries()
        revealContent()
    }

    private func restoreBrowserPreferences() {
        if let savedDisplayModeRawValue = UserDefaults.standard.string(forKey: Self.displayModeDefaultsKey),
           let savedDisplayMode = ImageBrowserDisplayMode(rawValue: savedDisplayModeRawValue) {
            displayMode = savedDisplayMode
        }

        let savedThumbnailSize = UserDefaults.standard.double(forKey: Self.thumbnailSizeDefaultsKey)
        if savedThumbnailSize > 0 {
            thumbnailSize = min(max(CGFloat(savedThumbnailSize), 72), 220)
        }
    }

    private func handleDirectoryChange() {
        searchText = ""
        loadEntries()
        selectedEntryIDs.removeAll()
        focusedEntryID = nil
        anchorEntryID = nil
        persistRecentDirectory()
        revealContent()
    }

    private func handleSearchChange(_ value: String) {
        trimSelectionToVisibleEntries()
    }

    private func handleSearchExpansionChange(_ value: Bool) {
        guard value else {
            isSearchFieldFocused = false
            return
        }

        DispatchQueue.main.async {
            isSearchFieldFocused = true
        }
    }

    private func handleSearchFocusChange(_ value: Bool) {
        guard !value, searchText.isEmpty, isSearchExpanded else { return }
        closeSearch()
    }

    private func openSearch() {
        guard !isSearchExpanded else { return }

        searchExpansionExtra = Self.searchExpansionOvershoot
        withAnimation(Self.searchOpenAnimation) {
            isSearchExpanded = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.searchOvershootDuration) {
            guard isSearchExpanded else { return }
            withAnimation(Self.searchSettleAnimation) {
                searchExpansionExtra = 0
            }
        }
    }

    private func closeSearch() {
        withAnimation(Self.searchCloseAnimation) {
            searchExpansionExtra = 0
            isSearchExpanded = false
        }
    }

    private func handleEscape() {
        if isSearchExpanded || !searchText.isEmpty {
            searchText = ""
            closeSearch()
            return
        }

        if isPathEditing {
            isPathEditing = false
            editablePath = currentDirectory.path
            return
        }

        onDismiss()
    }

    private func handleSortOptionChange(_ value: OpenBrowserSortOption) {
        UserDefaults.standard.set(value.rawValue, forKey: Self.sortOptionDefaultsKey)
        loadEntries()
    }

    private func handleSortAscendingChange(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Self.sortAscendingDefaultsKey)
        loadEntries()
    }

    private func handleSidebarVisibilityChange(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Self.sidebarVisibilityDefaultsKey)
    }

    private func handleSidebarWidthChange(_ value: CGFloat) {
        UserDefaults.standard.set(Double(Self.clampedSidebarWidth(value)), forKey: Self.sidebarWidthDefaultsKey)
    }

    private func handleThumbnailSizeChange(_ value: CGFloat) {
        UserDefaults.standard.set(Double(value), forKey: Self.thumbnailSizeDefaultsKey)
    }

    private func handleDisplayModeChange(_ value: ImageBrowserDisplayMode) {
        UserDefaults.standard.set(value.rawValue, forKey: Self.displayModeDefaultsKey)
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                favoriteSidebarSection
                sidebarSection("Locations", items: locationSidebarItems)

                Button {
                    addCurrentFolderToFavorites()
                } label: {
                    Label("Add Current Folder", systemImage: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .frame(height: 26)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.top, Self.sidebarContentTopInset)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
        .background(Color.openBrowserSidebarBackground)
    }

    private var favoriteSidebarSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FAVORITES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)

            ForEach(favoriteSidebarItems) { item in
                sidebarRow(item, allowsRemoval: true)
                    .onDrag {
                        draggingSidebarItemID = item.id
                        return NSItemProvider(object: item.id as NSString)
                    }
                    .onDrop(
                        of: [UTType.plainText],
                        delegate: OpenBrowserSidebarDropDelegate(
                            targetItem: item,
                            items: favoriteSidebarItems,
                            draggingItemID: $draggingSidebarItemID,
                            onMove: moveFavoriteSidebarItem
                        )
                    )
            }
        }
    }

    private func sidebarSection(_ title: String, items: [OpenBrowserSidebarItem], allowsRemoval: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)

            ForEach(items) { item in
                sidebarRow(item, allowsRemoval: allowsRemoval)
            }
        }
    }

    private func sidebarRow(_ item: OpenBrowserSidebarItem, allowsRemoval: Bool) -> some View {
        let isSelected = item.url.standardizedFileURL == currentDirectory.standardizedFileURL

        return HStack(spacing: 9) {
            Image(systemName: item.systemImage)
                .font(.system(size: 13, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 18, alignment: .center)
                .foregroundStyle(isSelected ? Color.openBrowserSelection : .secondary)

            Text(item.title)
                .font(.system(size: 12, weight: .regular))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .frame(height: 24)
        .foregroundStyle(isSelected ? Color.openBrowserSelection : .primary)
        .background(
            isSelected ? Color.white.opacity(0.09) : .clear,
            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .onTapGesture {
            navigate(to: item.url)
        }
        .contextMenu {
            if allowsRemoval {
                Button("Remove from Sidebar") {
                    removeSidebarFavorite(item)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var content: some View {
        if let accessErrorMessage {
            accessErrorView(accessErrorMessage)
        } else if visibleEntries.isEmpty {
            ContentUnavailableView(
                searchText.isEmpty ? "No Openable Items" : "No Results",
                systemImage: "folder",
                description: Text(searchText.isEmpty ? "This folder has no supported images, PDFs, or folders." : "Try another search term.")
            )
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 360)
        } else {
            switch displayMode {
            case .thumbnails:
                thumbnailGrid
            case .list:
                listView
            }
        }
    }

    private func accessErrorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.folder")
                .font(.system(size: 38, weight: .regular))
                .symbolRenderingMode(.hierarchical)

            Text("Folder Access Needed")
                .font(.system(size: 22, weight: .semibold))

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            HStack(spacing: 10) {
                Button("Retry") {
                    loadEntries()
                }

                Button("Open Privacy Settings") {
                    openPrivacySettings()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
        .foregroundStyle(.primary)
    }

    private var thumbnailGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: thumbnailSize, maximum: thumbnailSize), spacing: 18)],
            alignment: .center,
            spacing: 22
        ) {
            ForEach(Array(visibleEntries.enumerated()), id: \.element.id) { index, entry in
                ZStack(alignment: .top) {
                    OpenBrowserThumbnailCell(
                        entry: entry,
                        index: index,
                        thumbnailSize: thumbnailSize,
                        isSelected: selectedEntryIDs.contains(entry.id),
                        isFavorite: favoriteFileIDs.contains(entry.id),
                        isRevealed: isContentRevealed,
                        reduceMotion: reduceMotion,
                        onClick: selectEntry,
                        onDoubleClick: openOrNavigate,
                        onShare: { requestedEntries in shareContextEntries(requestedEntries, sourceEntry: entry) },
                        onToggleFavorite: toggleFavorite,
                        onAddFolderFavorite: addFolderToFavorites
                    )

                    Color.clear
                        .frame(width: 1, height: 1)
                        .offset(y: -Self.thumbnailScrollAnchorTopOffset)
                        .id(Self.thumbnailScrollAnchorID(for: entry.id))
                }
                .id(entry.id)
                .openBrowserVisibleEntryFrame(id: entry.id)
            }
        }
    }

    private var listView: some View {
        LazyVStack(spacing: 6) {
            ForEach(Array(visibleEntries.enumerated()), id: \.element.id) { index, entry in
                ZStack(alignment: .top) {
                    OpenBrowserListRow(
                        entry: entry,
                        index: index,
                        isSelected: selectedEntryIDs.contains(entry.id),
                        isFavorite: favoriteFileIDs.contains(entry.id),
                        isRevealed: isContentRevealed,
                        reduceMotion: reduceMotion,
                        onClick: selectEntry,
                        onDoubleClick: openOrNavigate,
                        onShare: { requestedEntries in shareContextEntries(requestedEntries, sourceEntry: entry) },
                        onToggleFavorite: toggleFavorite,
                        onAddFolderFavorite: addFolderToFavorites
                    )

                    Color.clear
                        .frame(width: 1, height: 1)
                        .offset(y: -Self.thumbnailScrollAnchorTopOffset)
                        .id(Self.thumbnailScrollAnchorID(for: entry.id))
                }
                .id(entry.id)
                .openBrowserVisibleEntryFrame(id: entry.id)
            }
        }
        .frame(maxWidth: 820)
        .frame(maxWidth: .infinity)
    }

    private var standardFavoriteSidebarItems: [OpenBrowserSidebarItem] {
        [
            sidebarItem("Home", "house", FileManager.default.homeDirectoryForCurrentUser),
            directorySidebarItem("Desktop", "desktopcomputer", .desktopDirectory),
            directorySidebarItem("Downloads", "arrow.down.circle", .downloadsDirectory),
            directorySidebarItem("Pictures", "photo.on.rectangle", .picturesDirectory),
            directorySidebarItem("Documents", "doc.text", .documentDirectory),
            directorySidebarItem("Movies", "film", .moviesDirectory)
        ].compactMap { $0 }
    }

    private var favoriteSidebarItems: [OpenBrowserSidebarItem] {
        var itemsByID: [String: OpenBrowserSidebarItem] = [:]
        let allItems = (standardFavoriteSidebarItems + customFavoriteFolders).filter { !hiddenFavoriteSidebarIDs.contains($0.id) }
        for item in allItems {
            itemsByID[item.id] = itemsByID[item.id] ?? item
        }
        let orderedItems = favoriteSidebarOrder.compactMap { itemsByID[$0] }
        let orderedIDs = Set(orderedItems.map(\.id))
        let remainingItems = allItems.filter { !orderedIDs.contains($0.id) }
        return orderedItems + remainingItems
    }

    private var visibleEntries: [OpenBrowserEntry] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return entries }

        return entries.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    private var footerBar: some View {
        HStack(spacing: 12) {
            pathBar
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button("Cancel") {
                onDismiss()
            }
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel("Cancel")
            .accessibilityIdentifier("OpenBrowserCancelButton")

            Button(openButtonTitle) {
                openFocusedOrFirstSelectedEntryOrCurrentFolder()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(openButtonTitle)
            .accessibilityIdentifier("OpenBrowserOpenButton")
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(Color.openBrowserContentBackground)
        .overlay(alignment: .top) {
            Divider().overlay(.white.opacity(0.10))
        }
    }

    @ViewBuilder
    private var pathBar: some View {
        if isPathEditing {
            TextField("Path", text: $editablePath)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, weight: .regular))
                .focused($isPathEditorFocused)
                .onSubmit(commitEditedPath)
                .onExitCommand {
                    isPathEditing = false
                }
        } else {
            HStack(spacing: 4) {
                ForEach(pathComponents) { component in
                    Button {
                        navigate(to: component.url)
                    } label: {
                        Text(component.title)
                            .font(.system(size: 12, weight: .regular))
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(component.title)

                    if component.id != pathComponents.last?.id {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }

                Button {
                    beginPathEditing()
                } label: {
                    Rectangle()
                        .fill(Color.primary.opacity(0.001))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit Path")
                .frame(minWidth: 24)
                .frame(maxWidth: .infinity)
                .contextMenu {
                    Button("Copy Path") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(currentDirectory.path, forType: .string)
                    }

                    Button("Edit Path") {
                        beginPathEditing()
                    }
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.openBrowserControlFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .contentShape(Rectangle())
            .contextMenu {
                Button("Copy Path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(currentDirectory.path, forType: .string)
                }

                Button("Edit Path") {
                    beginPathEditing()
                }
            }
        }
    }

    private var statusText: String {
        if selectedEntryIDs.isEmpty {
            return "\(visibleEntries.count) \(visibleEntries.count == 1 ? "item" : "items")"
        }

        return "\(selectedEntryIDs.count) of \(visibleEntries.count) selected"
    }

    private var currentFolderTitle: String {
        currentDirectory.lastPathComponent.isEmpty ? currentDirectory.path : currentDirectory.lastPathComponent
    }

    private var selectedEntries: [OpenBrowserEntry] {
        visibleEntries.filter { selectedEntryIDs.contains($0.id) }
    }

    private var openButtonTitle: String {
        "Open"
    }

    private var pathComponents: [OpenBrowserPathComponent] {
        let components = currentDirectory.standardizedFileURL.pathComponents
        guard !components.isEmpty else { return [] }

        var path = ""
        return components.map { component in
            if component == "/" {
                path = "/"
                return OpenBrowserPathComponent(title: "Macintosh HD", url: URL(fileURLWithPath: "/"))
            }

            path = (path as NSString).appendingPathComponent(component)
            return OpenBrowserPathComponent(title: component, url: URL(fileURLWithPath: path))
        }
    }

    private var locationSidebarItems: [OpenBrowserSidebarItem] {
        var items = [sidebarItem("Macintosh HD", "internaldrive", URL(fileURLWithPath: "/"))]
        let volumes = (try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: "/Volumes"),
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        items.append(contentsOf: volumes.compactMap { url in
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { return nil }
            return sidebarItem(url.lastPathComponent, "externaldrive", url)
        })

        return items
    }

    private func sidebarItem(_ title: String, _ systemImage: String, _ url: URL) -> OpenBrowserSidebarItem {
        OpenBrowserSidebarItem(title: title, systemImage: systemImage, url: url)
    }

    private func directorySidebarItem(_ title: String, _ systemImage: String, _ directory: FileManager.SearchPathDirectory) -> OpenBrowserSidebarItem? {
        guard let url = FileManager.default.urls(for: directory, in: .userDomainMask).first else { return nil }
        return sidebarItem(title, systemImage, url)
    }

    private func openOrNavigate(_ entry: OpenBrowserEntry) {
        if entry.isDirectory {
            navigate(to: entry.url)
        } else {
            onOpen(entry.url)
        }
    }

    private func selectEntry(_ entry: OpenBrowserEntry) {
        let modifiers = NSEvent.modifierFlags
        let visibleIDs = visibleEntries.map(\.id)

        if modifiers.contains(.shift), let anchorEntryID, let anchorIndex = visibleIDs.firstIndex(of: anchorEntryID), let targetIndex = visibleIDs.firstIndex(of: entry.id) {
            let range = min(anchorIndex, targetIndex)...max(anchorIndex, targetIndex)
            selectedEntryIDs = Set(visibleIDs[range])
        } else if modifiers.contains(.command) {
            if selectedEntryIDs.contains(entry.id) {
                selectedEntryIDs.remove(entry.id)
            } else {
                selectedEntryIDs.insert(entry.id)
            }
            anchorEntryID = entry.id
        } else {
            selectedEntryIDs = [entry.id]
            anchorEntryID = entry.id
        }

        focusedEntryID = entry.id
    }

    private func selectAllVisibleEntries() {
        selectedEntryIDs = Set(visibleEntries.map(\.id))
        focusedEntryID = visibleEntries.last?.id
        anchorEntryID = visibleEntries.first?.id
    }

    private func openFocusedOrFirstSelectedEntry() {
        guard let entry = visibleEntries.first(where: { $0.id == focusedEntryID }) ?? selectedEntries.first else { return }
        openOrNavigate(entry)
    }

    private func openFocusedOrFirstSelectedEntryOrCurrentFolder() {
        if let entry = visibleEntries.first(where: { $0.id == focusedEntryID }) ?? selectedEntries.first {
            openOrNavigate(entry)
        } else {
            onOpen(currentDirectory)
        }
    }

    private func navigateToParent() {
        let parent = currentDirectory.deletingLastPathComponent()
        guard parent.path != currentDirectory.path else { return }
        navigate(to: parent)
    }

    private func navigate(to url: URL, recordsHistory: Bool = true) {
        let standardizedURL = url.standardizedFileURL
        guard standardizedURL != currentDirectory.standardizedFileURL else { return }

        if recordsHistory {
            backHistory.append(currentDirectory)
            forwardHistory.removeAll()
        }

        currentDirectory = standardizedURL
    }

    private func navigateBack() {
        guard let previousURL = backHistory.popLast() else { return }
        forwardHistory.append(currentDirectory)
        navigate(to: previousURL, recordsHistory: false)
    }

    private func navigateForward() {
        guard let nextURL = forwardHistory.popLast() else { return }
        backHistory.append(currentDirectory)
        navigate(to: nextURL, recordsHistory: false)
    }

    private func beginPathEditing() {
        editablePath = currentDirectory.path
        isPathEditing = true
        DispatchQueue.main.async {
            isPathEditorFocused = true
        }
    }

    private func commitEditedPath() {
        let expandedPath: String
        if editablePath.hasPrefix("~") {
            expandedPath = (editablePath as NSString).expandingTildeInPath
        } else {
            expandedPath = editablePath
        }

        let url = URL(fileURLWithPath: expandedPath)
        guard Self.validDirectory(url) != nil else {
            accessErrorMessage = "The path \(expandedPath) is not a readable folder."
            isPathEditing = false
            return
        }

        navigate(to: url)
        isPathEditing = false
    }

    private func loadEntries() {
        do {
            entries = try Self.loadEntries(in: currentDirectory, sortOption: sortOption, ascending: sortAscending)
            accessErrorMessage = nil
        } catch {
            entries = []
            accessErrorMessage = "Viewooa needs permission to read \(currentDirectory.lastPathComponent.isEmpty ? currentDirectory.path : currentDirectory.lastPathComponent). Allow access in the macOS prompt, or enable access in System Settings."
        }
        trimSelectionToVisibleEntries()
    }

    private func trimSelectionToVisibleEntries() {
        let visibleIDs = Set(visibleEntries.map(\.id))
        selectedEntryIDs = selectedEntryIDs.intersection(visibleIDs)
        if let focusedEntryID, !visibleIDs.contains(focusedEntryID) {
            self.focusedEntryID = selectedEntryIDs.first
        }
        if let anchorEntryID, !visibleIDs.contains(anchorEntryID) {
            self.anchorEntryID = selectedEntryIDs.first
        }
    }

    private func thumbnailAnchorID() -> String? {
        if let firstVisibleID = firstFullyVisibleEntryID() {
            return firstVisibleID
        }

        if let focusedEntryID, visibleEntries.contains(where: { $0.id == focusedEntryID }) {
            return focusedEntryID
        }

        if let selectedID = selectedEntryIDs.first(where: { selectedID in
            visibleEntries.contains(where: { $0.id == selectedID })
        }) {
            return selectedID
        }

        return nil
    }

    private func prepareThumbnailResizeAnchor() {
        let anchorID = thumbnailAnchorID()
        thumbnailScrollAnchorID = anchorID
        if let anchorID, let frame = visibleEntryFrames[anchorID] {
            pendingThumbnailResizeAnchor = OpenBrowserResizeAnchor(id: anchorID, minY: frame.minY)
        } else {
            pendingThumbnailResizeAnchor = nil
        }
    }

    private func scrollToThumbnailAnchor(with proxy: ScrollViewProxy) {
        guard let thumbnailScrollAnchorID else { return }
        guard pendingThumbnailResizeAnchor == nil || openBrowserScrollView == nil else { return }
        DispatchQueue.main.async {
            withAnimation(.smooth(duration: 0.24, extraBounce: 0)) {
                proxy.scrollTo(Self.thumbnailScrollAnchorID(for: thumbnailScrollAnchorID), anchor: .top)
            }
        }
    }

    private func adjustScrollForPendingThumbnailResize(with frames: [String: CGRect]) {
        guard let pendingThumbnailResizeAnchor,
              let newFrame = frames[pendingThumbnailResizeAnchor.id],
              let openBrowserScrollView else { return }

        let deltaY = newFrame.minY - pendingThumbnailResizeAnchor.minY
        self.pendingThumbnailResizeAnchor = nil
        thumbnailScrollAnchorID = nil

        guard abs(deltaY) > 0.5 else { return }
        DispatchQueue.main.async {
            var origin = openBrowserScrollView.contentView.bounds.origin
            origin.y += deltaY
            origin.y = max(0, origin.y)
            openBrowserScrollView.contentView.scroll(to: origin)
            openBrowserScrollView.reflectScrolledClipView(openBrowserScrollView.contentView)
        }
    }

    private func firstFullyVisibleEntryID() -> String? {
        guard scrollViewportSize.height > 0 else { return nil }

        let visibleIDs = Set(visibleEntries.map(\.id))
        let topEdge = Self.contentTopInset - 6
        let bottomEdge = scrollViewportSize.height - 8

        return visibleEntryFrames
            .filter { id, frame in
                visibleIDs.contains(id)
                    && frame.minY >= topEdge
                    && frame.maxY <= bottomEdge
                    && frame.maxX > 0
                    && frame.minX < scrollViewportSize.width
            }
            .sorted { lhs, rhs in
                if abs(lhs.value.minY - rhs.value.minY) > 1 {
                    return lhs.value.minY < rhs.value.minY
                }
                return lhs.value.minX < rhs.value.minX
            }
            .first?.key
    }

    private func revealContent() {
        guard !reduceMotion else {
            isContentRevealed = true
            return
        }

        isContentRevealed = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.035) {
            isContentRevealed = true
        }
    }

    private static func loadEntries(in directory: URL, sortOption: OpenBrowserSortOption, ascending: Bool) throws -> [OpenBrowserEntry] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey, .localizedNameKey, .contentModificationDateKey, .fileSizeKey, .typeIdentifierKey],
            options: [.skipsHiddenFiles]
        )

        let entries: [OpenBrowserEntry] = urls.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .localizedNameKey, .contentModificationDateKey, .fileSizeKey, .typeIdentifierKey])
            let isDirectory = values?.isDirectory == true
            guard isDirectory || SupportedImageTypes.isOpenableFile(url) else { return nil }
            return OpenBrowserEntry(
                url: url,
                name: values?.localizedName ?? url.lastPathComponent,
                isDirectory: isDirectory,
                modificationDate: values?.contentModificationDate,
                fileSize: values?.fileSize ?? 0,
                typeIdentifier: values?.typeIdentifier
            )
        }

        return entries.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory && !rhs.isDirectory
            }

            let comparison: ComparisonResult
            switch sortOption {
            case .name:
                comparison = lhs.name.localizedStandardCompare(rhs.name)
            case .kind:
                comparison = lhs.kindTitle.localizedStandardCompare(rhs.kindTitle)
            case .dateModified:
                comparison = (lhs.modificationDate ?? .distantPast).compare(rhs.modificationDate ?? .distantPast)
            case .size:
                comparison = lhs.fileSize == rhs.fileSize ? .orderedSame : (lhs.fileSize < rhs.fileSize ? .orderedAscending : .orderedDescending)
            }

            if comparison == .orderedSame {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

            return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func toggleFavorite(_ entry: OpenBrowserEntry) {
        guard !entry.isDirectory else {
            addFolderToFavorites(entry)
            return
        }

        if favoriteFileIDs.contains(entry.id) {
            favoriteFileIDs.remove(entry.id)
        } else {
            favoriteFileIDs.insert(entry.id)
        }
        UserDefaults.standard.set(Array(favoriteFileIDs), forKey: Self.favoriteFilesDefaultsKey)
    }

    private func addFolderToFavorites(_ entry: OpenBrowserEntry) {
        guard entry.isDirectory else { return }
        addFavoriteFolder(url: entry.url)
    }

    private func addCurrentFolderToFavorites() {
        addFavoriteFolder(url: currentDirectory)
    }

    private func addFavoriteFolder(url: URL) {
        let item = sidebarItem(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent, "folder", url)
        hiddenFavoriteSidebarIDs.remove(item.id)
        persistHiddenFavoriteSidebarItems()
        guard !(standardFavoriteSidebarItems + customFavoriteFolders).contains(where: { $0.id == item.id }) else { return }
        customFavoriteFolders.append(item)
        favoriteSidebarOrder.append(item.id)
        persistCustomFavoriteFolders()
        persistFavoriteSidebarOrder()
    }

    private func removeSidebarFavorite(_ item: OpenBrowserSidebarItem) {
        if customFavoriteFolders.contains(where: { $0.id == item.id }) {
            removeFavoriteFolder(item)
        } else {
            hiddenFavoriteSidebarIDs.insert(item.id)
            favoriteSidebarOrder.removeAll { $0 == item.id }
            persistHiddenFavoriteSidebarItems()
            persistFavoriteSidebarOrder()
        }
    }

    private func removeFavoriteFolder(_ item: OpenBrowserSidebarItem) {
        customFavoriteFolders.removeAll { $0.id == item.id }
        favoriteSidebarOrder.removeAll { $0 == item.id }
        persistCustomFavoriteFolders()
        persistFavoriteSidebarOrder()
    }

    private func moveFavoriteSidebarItem(draggedID: String, before targetID: String) {
        guard draggedID != targetID else { return }
        var ids = favoriteSidebarItems.map(\.id)
        guard let fromIndex = ids.firstIndex(of: draggedID), let toIndex = ids.firstIndex(of: targetID) else { return }
        let dragged = ids.remove(at: fromIndex)
        ids.insert(dragged, at: toIndex > fromIndex ? toIndex - 1 : toIndex)
        favoriteSidebarOrder = ids
        persistFavoriteSidebarOrder()
    }

    private func shareEntries(_ entries: [OpenBrowserEntry]) {
        let urls = entries.map(\.url)
        guard !urls.isEmpty, let contentView = NSApp.keyWindow?.contentView else { return }
        NSSharingServicePicker(items: urls).show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
    }

    private func shareContextEntries(_ requestedEntries: [OpenBrowserEntry], sourceEntry: OpenBrowserEntry) {
        if selectedEntryIDs.contains(sourceEntry.id), !selectedEntries.isEmpty {
            shareEntries(selectedEntries.filter { !$0.isDirectory })
        } else {
            shareEntries(requestedEntries.filter { !$0.isDirectory })
        }
    }

    private func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders") else { return }
        NSWorkspace.shared.open(url)
    }

    private func persistRecentDirectory() {
        UserDefaults.standard.set(currentDirectory.path, forKey: Self.recentDirectoryDefaultsKey)
    }

    private func persistCustomFavoriteFolders() {
        UserDefaults.standard.set(customFavoriteFolders.map(\.url.path), forKey: Self.customFavoriteFoldersDefaultsKey)
    }

    private func persistHiddenFavoriteSidebarItems() {
        UserDefaults.standard.set(Array(hiddenFavoriteSidebarIDs), forKey: Self.hiddenFavoriteSidebarDefaultsKey)
    }

    private func persistFavoriteSidebarOrder() {
        UserDefaults.standard.set(favoriteSidebarOrder, forKey: Self.favoriteSidebarOrderDefaultsKey)
    }

    private static func loadCustomFavoriteFolders() -> [OpenBrowserSidebarItem] {
        let paths = UserDefaults.standard.stringArray(forKey: Self.customFavoriteFoldersDefaultsKey) ?? []
        return paths.compactMap { path in
            let url = URL(fileURLWithPath: path)
            guard validDirectory(url) != nil else { return nil }
            return OpenBrowserSidebarItem(title: url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent, systemImage: "folder", url: url)
        }
    }

    private static func savedDirectoryURL() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: recentDirectoryDefaultsKey), !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path)
    }

    private static func validDirectory(_ url: URL) -> URL? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else { return nil }
        return url
    }

    private static func clampedSidebarWidth(_ width: CGFloat) -> CGFloat {
        min(max(width, minimumSidebarWidth), maximumSidebarWidth)
    }

    private static func contentHorizontalPadding(for windowWidth: CGFloat, isSidebarVisible: Bool) -> CGFloat {
        let effectiveWidth = isSidebarVisible ? windowWidth - defaultSidebarWidth : windowWidth
        if effectiveWidth < 620 {
            return 16
        }
        if effectiveWidth < 860 {
            return 22
        }
        return 30
    }

    private static func thumbnailScrollAnchorID(for id: String) -> String {
        "OpenBrowserScrollAnchor::\(id)"
    }

    private static let recentDirectoryDefaultsKey = "OpenBrowserRecentDirectory"
    private static let sidebarVisibilityDefaultsKey = "OpenBrowserSidebarVisible"
    private static let sidebarWidthDefaultsKey = "OpenBrowserSidebarWidth"
    private static let sortOptionDefaultsKey = "OpenBrowserSortOption"
    private static let sortAscendingDefaultsKey = "OpenBrowserSortAscending"
    private static let favoriteFilesDefaultsKey = "OpenBrowserFavoriteFiles"
    private static let customFavoriteFoldersDefaultsKey = "OpenBrowserCustomFavoriteFolders"
    private static let hiddenFavoriteSidebarDefaultsKey = "OpenBrowserHiddenFavoriteSidebarItems"
    private static let favoriteSidebarOrderDefaultsKey = "OpenBrowserFavoriteSidebarOrder"
    private static let displayModeDefaultsKey = "OpenBrowserDisplayMode"
    private static let thumbnailSizeDefaultsKey = "OpenBrowserThumbnailSize"
    private static let minimumSidebarWidth: CGFloat = 118
    private static let defaultSidebarWidth: CGFloat = 156
    private static let previousDefaultSidebarWidth = 186.0
    private static let maximumSidebarWidth: CGFloat = 320
    private static let contentTopInset: CGFloat = 86
    private static let sidebarContentTopInset: CGFloat = 86
    private static let collapsedSidebarLeadingInset: CGFloat = 116
    private static let footerHeight: CGFloat = 42
    private static let sidebarHandleWidth: CGFloat = 12
    private static let titlebarChromeTopInset: CGFloat = 6
    private static let titlebarControlHeight: CGFloat = 34
    private static let titlebarButtonSize: CGFloat = 32
    private static let openBrowserGridHorizontalPadding: CGFloat = 30
    private static let thumbnailScrollAnchorTopOffset: CGFloat = contentTopInset - 6
    private static let searchExpansionOvershoot: CGFloat = 24
    private static let searchOvershootDuration: TimeInterval = 0.16
    private static let searchOpenAnimation = Animation.timingCurve(0.16, 1.0, 0.30, 1.0, duration: 0.24)
    private static let searchSettleAnimation = Animation.timingCurve(0.18, 0.92, 0.22, 1.0, duration: 0.22)
    private static let searchCloseAnimation = Animation.timingCurve(0.18, 0.88, 0.20, 1.0, duration: 0.24)
}

private struct OpenBrowserPathComponent: Identifiable {
    let title: String
    let url: URL

    var id: String { url.path }
}

private struct OpenBrowserEntry: Identifiable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let modificationDate: Date?
    let fileSize: Int
    let typeIdentifier: String?

    var id: String { url.path }

    var kindTitle: String {
        if isDirectory {
            return "Folder"
        }

        if SupportedImageTypes.isPDF(url) {
            return "PDF"
        }

        return url.pathExtension.uppercased()
    }
}

private enum OpenBrowserSortOption: String, CaseIterable, Identifiable {
    case name
    case kind
    case dateModified
    case size

    var id: Self { self }

    var title: String {
        switch self {
        case .name:
            "Name"
        case .kind:
            "Kind"
        case .dateModified:
            "Date Modified"
        case .size:
            "Size"
        }
    }
}

private struct OpenBrowserSidebarItem: Identifiable {
    let title: String
    let systemImage: String
    let url: URL

    var id: String { url.path }
}

private struct OpenBrowserSidebarDropDelegate: DropDelegate {
    let targetItem: OpenBrowserSidebarItem
    let items: [OpenBrowserSidebarItem]
    @Binding var draggingItemID: String?
    let onMove: (String, String) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggingItemID, draggingItemID != targetItem.id else { return }
        guard items.contains(where: { $0.id == draggingItemID }) else { return }
        onMove(draggingItemID, targetItem.id)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItemID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

private struct OpenBrowserViewModeControl: View {
    @Binding var displayMode: ImageBrowserDisplayMode
    var isVibrant = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImageBrowserDisplayMode.allCases) { mode in
                Button {
                    displayMode = mode
                } label: {
                    Image(systemName: mode.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: isVibrant ? 31 : 32, height: isVibrant ? 30 : 26)
                        .foregroundStyle(viewModeForeground(for: mode))
                        .background(
                            viewModeBackground(for: mode),
                            in: RoundedRectangle(cornerRadius: isVibrant ? 15 : 6, style: .continuous)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 6, style: .continuous))
                }
                .frame(width: isVibrant ? 31 : 32, height: isVibrant ? 30 : 26)
                .contentShape(RoundedRectangle(cornerRadius: isVibrant ? 15 : 6, style: .continuous))
                .buttonStyle(.plain)
                .accessibilityLabel(mode.title)
            }
        }
        .padding(isVibrant ? 0 : 2)
        .background(
            isVibrant ? Color.clear : Color.openBrowserControlFill,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func viewModeForeground(for mode: ImageBrowserDisplayMode) -> Color {
        if isVibrant {
            return displayMode == mode ? .white : Color.white.opacity(0.62)
        }

        return displayMode == mode ? .primary : .secondary
    }

    private func viewModeBackground(for mode: ImageBrowserDisplayMode) -> Color {
        if isVibrant {
            return displayMode == mode ? Color.white.opacity(0.16) : .clear
        }

        return displayMode == mode ? Color(nsColor: .selectedControlColor).opacity(0.22) : .clear
    }
}

private struct OpenBrowserThumbnailCell: View {
    let entry: OpenBrowserEntry
    let index: Int
    let thumbnailSize: CGFloat
    let isSelected: Bool
    let isFavorite: Bool
    let isRevealed: Bool
    let reduceMotion: Bool
    let onClick: (OpenBrowserEntry) -> Void
    let onDoubleClick: (OpenBrowserEntry) -> Void
    let onShare: ([OpenBrowserEntry]) -> Void
    let onToggleFavorite: (OpenBrowserEntry) -> Void
    let onAddFolderFavorite: (OpenBrowserEntry) -> Void

    var body: some View {
        Button {
            onClick(entry)
        } label: {
            VStack(spacing: 9) {
                thumbnailPreview

                Text(entry.name)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .frame(width: thumbnailSize, height: 28, alignment: .top)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(width: thumbnailSize + 16, height: thumbnailSize * 0.72 + 57, alignment: .top)
            .background(isSelected ? Color.openBrowserSelection.opacity(0.07) : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Color.openBrowserSelection.opacity(0.46) : .clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.name)
        .simultaneousGesture(TapGesture(count: 2).onEnded {
            onDoubleClick(entry)
        })
        .contextMenu {
            Button(entry.isDirectory ? "Open Folder" : "Open") {
                onDoubleClick(entry)
            }

            Button("Share...") {
                onShare([entry])
            }
            .disabled(entry.isDirectory)

            if entry.isDirectory {
                Button("Add to Sidebar") {
                    onAddFolderFavorite(entry)
                }
            } else {
                Button(isFavorite ? "Remove Favorite" : "Favorite") {
                    onToggleFavorite(entry)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if isFavorite && !entry.isDirectory {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red)
                    .padding(6)
            }
        }
        .opacity(isRevealed || reduceMotion ? 1 : 0)
        .scaleEffect(isRevealed || reduceMotion ? 1 : 0.965)
        .offset(y: isRevealed || reduceMotion ? 0 : 18)
        .animation(revealAnimation, value: isRevealed)
    }

    private var revealAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .smooth(duration: 0.46, extraBounce: 0.08)
            .delay(min(Double(index % 24) * 0.018, 0.26))
    }

    @ViewBuilder
    private var thumbnailPreview: some View {
        if entry.isDirectory {
            OpenBrowserItemPreview(entry: entry, targetPixelSize: max(thumbnailSize * 1.6, 160))
                .frame(width: thumbnailSize, height: thumbnailSize * 0.58)
                .shadow(color: .black.opacity(0.16), radius: 9, y: 5)
        } else {
            OpenBrowserItemPreview(entry: entry, targetPixelSize: max(thumbnailSize * 1.6, 160))
                .frame(width: thumbnailSize, height: thumbnailSize * 0.72)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(.separator.opacity(0.55))
                }
                .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
        }
    }
}

private struct OpenBrowserListRow: View {
    let entry: OpenBrowserEntry
    let index: Int
    let isSelected: Bool
    let isFavorite: Bool
    let isRevealed: Bool
    let reduceMotion: Bool
    let onClick: (OpenBrowserEntry) -> Void
    let onDoubleClick: (OpenBrowserEntry) -> Void
    let onShare: ([OpenBrowserEntry]) -> Void
    let onToggleFavorite: (OpenBrowserEntry) -> Void
    let onAddFolderFavorite: (OpenBrowserEntry) -> Void

    var body: some View {
        Button {
            onClick(entry)
        } label: {
            HStack(spacing: 12) {
                listPreview

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.system(size: 13, weight: .regular))
                        .lineLimit(1)
                    Text(entry.isDirectory ? "Folder" : entry.url.pathExtension.uppercased())
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isFavorite && !entry.isDirectory {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 9)
            .frame(height: 40)
            .background(isSelected ? Color.openBrowserSelection.opacity(0.16) : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.openBrowserSelection.opacity(0.24) : .clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.name)
        .simultaneousGesture(TapGesture(count: 2).onEnded {
            onDoubleClick(entry)
        })
        .contextMenu {
            Button(entry.isDirectory ? "Open Folder" : "Open") {
                onDoubleClick(entry)
            }

            Button("Share...") {
                onShare([entry])
            }
            .disabled(entry.isDirectory)

            if entry.isDirectory {
                Button("Add to Sidebar") {
                    onAddFolderFavorite(entry)
                }
            } else {
                Button(isFavorite ? "Remove Favorite" : "Favorite") {
                    onToggleFavorite(entry)
                }
            }
        }
        .opacity(isRevealed || reduceMotion ? 1 : 0)
        .scaleEffect(isRevealed || reduceMotion ? 1 : 0.985)
        .offset(y: isRevealed || reduceMotion ? 0 : 12)
        .animation(revealAnimation, value: isRevealed)
    }

    private var revealAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .smooth(duration: 0.38, extraBounce: 0.04)
            .delay(min(Double(index % 18) * 0.015, 0.2))
    }

    @ViewBuilder
    private var listPreview: some View {
        if entry.isDirectory {
            OpenBrowserItemPreview(entry: entry, targetPixelSize: 96)
                .frame(width: 44, height: 32)
        } else {
            OpenBrowserItemPreview(entry: entry, targetPixelSize: 96)
                .frame(width: 44, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(Color.openBrowserSeparator.opacity(0.65))
                }
        }
    }
}

private struct OpenBrowserItemPreview: View {
    let entry: OpenBrowserEntry
    let targetPixelSize: CGFloat

    var body: some View {
        ZStack {
            if entry.isDirectory {
                OpenBrowserFolderPreview(url: entry.url)
            } else if SupportedImageTypes.isPDF(entry.url) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.openBrowserControlFill)

                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 34, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            } else {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.openBrowserControlFill)

                ImageBrowserThumbnail(url: entry.url, targetPixelSize: targetPixelSize)
            }
        }
    }
}

private struct OpenBrowserFolderPreview: View {
    let url: URL

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .scaledToFit()
            .padding(.horizontal, 2)
    }
}

private extension Color {
    static let openBrowserWindowBackground = Color(nsColor: .windowBackgroundColor)
    static let openBrowserContentBackground = Color(nsColor: .underPageBackgroundColor)
    static let openBrowserSidebarBackground = Color(nsColor: .controlBackgroundColor).opacity(0.96)
    static let openBrowserSelection = Color(nsColor: .selectedContentBackgroundColor)
    static let openBrowserSeparator = Color(nsColor: .separatorColor).opacity(0.45)
    static let openBrowserControlFill = Color(nsColor: .controlBackgroundColor).opacity(0.64)
}

private struct ImageBrowserThumbnailCell: View {
    let url: URL
    let index: Int
    let thumbnailSize: CGFloat
    let isSelected: Bool
    let isRevealed: Bool
    let reduceMotion: Bool
    let onSelect: (Int) -> Void

    var body: some View {
        Button {
            onSelect(index)
        } label: {
            VStack(spacing: 9) {
                ImageBrowserThumbnail(url: url, targetPixelSize: max(thumbnailSize * 1.6, 160))
                    .frame(width: thumbnailSize, height: thumbnailSize * 0.72)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(isSelected ? .white : .white.opacity(0.14), lineWidth: isSelected ? 2 : 1)
                    }
                    .shadow(color: .black.opacity(isSelected ? 0.42 : 0.24), radius: isSelected ? 18 : 10, y: isSelected ? 9 : 5)

                Text(url.lastPathComponent)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.74))
                    .frame(width: thumbnailSize)
            }
            .padding(8)
            .background(isSelected ? .white.opacity(0.15) : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(url.lastPathComponent)
        .opacity(isRevealed || reduceMotion ? 1 : 0)
        .scaleEffect(isRevealed || reduceMotion ? 1 : 0.965)
        .offset(y: isRevealed || reduceMotion ? 0 : 18)
        .animation(revealAnimation, value: isRevealed)
    }

    private var revealAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .smooth(duration: 0.46, extraBounce: 0.08)
            .delay(Self.revealDelay(for: index))
    }

    private static func revealDelay(for index: Int) -> Double {
        min(Double(index % 24) * 0.018, 0.26)
    }
}

private struct ImageBrowserListRow: View {
    let url: URL
    let index: Int
    let isSelected: Bool
    let isRevealed: Bool
    let reduceMotion: Bool
    let onSelect: (Int) -> Void

    var body: some View {
        Button {
            onSelect(index)
        } label: {
            HStack(spacing: 12) {
                ImageBrowserThumbnail(url: url, targetPixelSize: 96)
                    .frame(width: 58, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(.white.opacity(0.14))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(url.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(url.deletingLastPathComponent().lastPathComponent)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.54))
                        .lineLimit(1)
                }

                Spacer()

                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.52))
            }
            .padding(.horizontal, 12)
            .frame(height: 58)
            .background(isSelected ? .white.opacity(0.16) : .white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? .white.opacity(0.48) : .white.opacity(0.08))
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(url.lastPathComponent)
        .opacity(isRevealed || reduceMotion ? 1 : 0)
        .scaleEffect(isRevealed || reduceMotion ? 1 : 0.985)
        .offset(y: isRevealed || reduceMotion ? 0 : 12)
        .animation(revealAnimation, value: isRevealed)
    }

    private var revealAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .smooth(duration: 0.38, extraBounce: 0.04)
            .delay(Self.revealDelay(for: index))
    }

    private static func revealDelay(for index: Int) -> Double {
        min(Double(index % 18) * 0.015, 0.2)
    }
}

private struct ImageBrowserThumbnail: View {
    let url: URL
    let targetPixelSize: CGFloat
    @State private var image: NSImage?

    private var requestedPixelSize: CGFloat {
        ImageBrowserThumbnailCache.normalizedPixelSize(targetPixelSize)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(.white.opacity(0.08))

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white.opacity(0.36))
            }
        }
        .clipped()
        .task(id: "\(url.path)-\(Int(requestedPixelSize))") {
            image = await ImageBrowserThumbnailCache.shared.image(
                for: url,
                targetPixelSize: requestedPixelSize
            )
        }
    }
}

private final class ImageBrowserThumbnailCache: @unchecked Sendable {
    static let shared = ImageBrowserThumbnailCache()

    private let cache = NSCache<NSString, NSImage>()
    private let renderQueue = DispatchQueue(label: "com.seinel.Viewooa.ImageBrowserThumbnailCache", qos: .utility)
    private let renderLimiter = DispatchSemaphore(value: 2)

    private init() {
        cache.countLimit = 384
        cache.totalCostLimit = 80 * 1024 * 1024
    }

    func image(for url: URL, targetPixelSize: CGFloat) async -> NSImage? {
        let pixelSize = Self.normalizedPixelSize(targetPixelSize)
        let cacheKey = Self.cacheKey(for: url, pixelSize: pixelSize)

        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        if let quickLookImage = await quickLookThumbnail(for: url, pixelSize: pixelSize) {
            store(quickLookImage, forKey: cacheKey)
            return quickLookImage
        }

        guard let imageSourceThumbnail = await imageIOLimitedThumbnail(for: url, pixelSize: pixelSize) else {
            return nil
        }

        store(imageSourceThumbnail, forKey: cacheKey)
        return imageSourceThumbnail
    }

    static func normalizedPixelSize(_ targetPixelSize: CGFloat) -> CGFloat {
        let clampedSize = min(max(targetPixelSize, 96), 512)
        return (clampedSize / 32).rounded(.up) * 32
    }

    private static func cacheKey(for url: URL, pixelSize: CGFloat) -> NSString {
        "\(url.path)|\(Int(pixelSize))" as NSString
    }

    private func store(_ image: NSImage, forKey key: NSString) {
        let estimatedCost = max(1, Int(image.size.width * image.size.height * 4))
        cache.setObject(image, forKey: key, cost: estimatedCost)
    }

    private func quickLookThumbnail(for url: URL, pixelSize: CGFloat) async -> NSImage? {
        await withCheckedContinuation { continuation in
            let request = QLThumbnailGenerator.Request(
                fileAt: url,
                size: CGSize(width: pixelSize, height: pixelSize),
                scale: NSScreen.main?.backingScaleFactor ?? 2,
                representationTypes: .thumbnail
            )

            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
                continuation.resume(returning: representation?.nsImage)
            }
        }
    }

    private func imageIOLimitedThumbnail(for url: URL, pixelSize: CGFloat) async -> NSImage? {
        await withCheckedContinuation { continuation in
            renderQueue.async { [renderLimiter] in
                renderLimiter.wait()
                defer { renderLimiter.signal() }

                continuation.resume(returning: Self.makeImageIOThumbnail(for: url, pixelSize: pixelSize))
            }
        }
    }

    private static func makeImageIOThumbnail(for url: URL, pixelSize: CGFloat) -> NSImage? {
        autoreleasepool {
            let options: [CFString: Any] = [
                kCGImageSourceShouldCache: false,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: Int(pixelSize)
            ]

            if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
               let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                return NSImage(
                    cgImage: cgImage,
                    size: NSSize(width: cgImage.width, height: cgImage.height)
                )
            }

            return nil
        }
    }
}

private struct ImageBrowserEscapeCatcher: NSViewRepresentable {
    let onEscape: () -> Void

    func makeNSView(context: Context) -> EscapeCatcherView {
        let view = EscapeCatcherView()
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: EscapeCatcherView, context: Context) {
        nsView.onEscape = onEscape
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    final class EscapeCatcherView: NSView {
        var onEscape: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            guard event.keyCode == 53 else {
                super.keyDown(with: event)
                return
            }

            onEscape?()
        }
    }
}

private struct OpenBrowserKeyboardCatcher: NSViewRepresentable {
    let onEscape: () -> Void
    let onSelectAll: () -> Void
    let onOpen: () -> Void
    let onParent: () -> Void

    func makeNSView(context: Context) -> KeyboardCatcherView {
        let view = KeyboardCatcherView()
        view.onEscape = onEscape
        view.onSelectAll = onSelectAll
        view.onOpen = onOpen
        view.onParent = onParent
        return view
    }

    func updateNSView(_ nsView: KeyboardCatcherView, context: Context) {
        nsView.onEscape = onEscape
        nsView.onSelectAll = onSelectAll
        nsView.onOpen = onOpen
        nsView.onParent = onParent

        DispatchQueue.main.async {
            if nsView.window?.firstResponder is NSTextView == false {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    final class KeyboardCatcherView: NSView {
        var onEscape: (() -> Void)?
        var onSelectAll: (() -> Void)?
        var onOpen: (() -> Void)?
        var onParent: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            switch (event.keyCode, event.modifierFlags.intersection(.deviceIndependentFlagsMask)) {
            case (53, _):
                onEscape?()
            case (0, let modifiers) where modifiers.contains(.command):
                onSelectAll?()
            case (36, _), (76, _):
                onOpen?()
            case (126, let modifiers) where modifiers.contains(.command):
                onParent?()
            case (51, _):
                onParent?()
            default:
                super.keyDown(with: event)
            }
        }
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
        Image(systemName: "1.magnifyingglass")
            .font(.system(size: 16, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
        .opacity(isActive ? 1.0 : 0.92)
        .frame(width: 30, height: 30)
    }
}
