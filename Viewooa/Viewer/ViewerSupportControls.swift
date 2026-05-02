import SwiftUI

struct ImageMetadataPanel: View {
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
                .strokeBorder(VisualInteractionPalette.viewerSurfaceBorder)
        }
        .shadow(color: VisualInteractionPalette.viewerCardShadow, radius: 18, y: 8)
    }
}

enum ViewerControlVisualStyle {
    static let iconSize: CGFloat = 30
    static let iconBackground = VisualInteractionPalette.viewerIconBackground
    static let iconForeground = VisualInteractionPalette.viewerIconForeground
    static let capsuleBackground = VisualInteractionPalette.viewerCapsuleBackground
    static let capsuleBorder = VisualInteractionPalette.viewerCapsuleBorder

    static func iconActionStyle(isActive: Bool) -> VisualIconActionStyle {
        VisualIconActionStyle(
            size: iconSize,
            foregroundColor: { isHovering in
                iconForeground.color(isSelected: isActive, isHovering: isHovering)
            },
            backgroundColor: { isHovering in
                iconBackground.color(isHovering: isHovering)
            }
        )
    }
}

struct RepeatingControlButton: View {
    let accessibilityLabel: String
    let systemImage: String
    let action: () -> Void
    let onHoldChange: (Bool) -> Void

    @State private var isPressed = false
    @State private var didStartRepeating = false
    @State private var repeatTask: Task<Void, Never>?

    private static let initialDelay: Duration = .milliseconds(500)

    var body: some View {
        ViewerControlIconSurface(systemImage: systemImage, isPressed: isPressed)
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

struct ViewerControlIconButton: View {
    let accessibilityLabel: String
    let systemImage: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        VisualIconActionButton(
            accessibilityLabel: accessibilityLabel,
            systemImage: systemImage,
            style: ViewerControlVisualStyle.iconActionStyle(isActive: isActive),
            shape: Circle(),
            action: action
        )
    }
}

struct ViewerControlIconSurface: View {
    let systemImage: String
    var isActive = false
    var isPressed = false

    var body: some View {
        VisualHoverState(shape: Circle()) { isHovering in
            VisualIconButtonLabel(
                systemImage: systemImage,
                size: ViewerControlVisualStyle.iconSize,
                foregroundColor: ViewerControlVisualStyle.iconForeground.color(isSelected: isActive, isHovering: isHovering),
                backgroundColor: ViewerControlVisualStyle.iconBackground.color(
                    isHovering: isHovering,
                    isPressed: isPressed
                )
            )
        }
    }
}

struct ViewerControlCapsuleLabel: View {
    let systemImage: String
    let title: String
    var titleWidth: CGFloat?

    var body: some View {
        VisualHoverState(shape: Capsule()) { isHovering in
            VisualCapsuleIconTextLabel(
                systemImage: systemImage,
                title: title,
                titleWidth: titleWidth,
                backgroundColor: ViewerControlVisualStyle.capsuleBackground.color(isHovering: isHovering)
            )
        }
    }
}

struct ViewerFitModeIconLabel: View {
    let fitMode: FitMode

    var body: some View {
        VisualHoverState(shape: Capsule()) { isHovering in
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(.white.opacity(0.95), lineWidth: 1.7)
                    .frame(width: 23, height: 16)

                Image(systemName: fitModeIconName)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 38, height: 28)
            .background(ViewerControlVisualStyle.capsuleBackground.color(isHovering: isHovering), in: Capsule())
            .visualHitArea(Capsule())
        }
    }

    private var fitModeIconName: String {
        switch fitMode {
        case .height:
            return "arrow.up.and.down"
        case .width:
            return "arrow.left.and.right"
        case .all:
            return "arrow.up.left.and.arrow.down.right"
        }
    }
}
