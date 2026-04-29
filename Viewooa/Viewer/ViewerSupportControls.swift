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
                .strokeBorder(.white.opacity(0.14))
        }
        .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
    }
}

enum ViewerControlVisualStyle {
    static let iconSize: CGFloat = 30
    static let iconBaseOpacity = 0.10
    static let iconHoverOpacity = 0.28
    static let iconPressedOpacity = 0.32
    static let capsuleBaseOpacity = 0.10
    static let capsuleHoverOpacity = 0.26
    static let capsuleBorderBaseOpacity = 0.10
    static let capsuleBorderHoverOpacity = 0.28

    static func iconBackgroundOpacity(isHovering: Bool, isPressed: Bool = false) -> Double {
        if isPressed {
            return iconPressedOpacity
        }

        return isHovering ? iconHoverOpacity : iconBaseOpacity
    }

    static func capsuleBackgroundOpacity(isHovering: Bool) -> Double {
        isHovering ? capsuleHoverOpacity : capsuleBaseOpacity
    }

    static func capsuleBorderOpacity(isHovering: Bool) -> Double {
        isHovering ? capsuleBorderHoverOpacity : capsuleBorderBaseOpacity
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
        Button(action: action) {
            ViewerControlIconSurface(systemImage: systemImage, isActive: isActive)
        }
        .buttonStyle(.plain)
        .visualHitArea()
        .foregroundStyle(.white)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct ViewerControlIconSurface: View {
    let systemImage: String
    var isActive = false
    var isPressed = false

    var body: some View {
        VisualHoverState { isHovering in
            VisualIconButtonLabel(
                systemImage: systemImage,
                size: ViewerControlVisualStyle.iconSize,
                foregroundColor: .white,
                backgroundColor: .white.opacity(ViewerControlVisualStyle.iconBackgroundOpacity(
                    isHovering: isHovering,
                    isPressed: isPressed
                ))
            )
        }
    }
}

struct ViewerControlCapsuleLabel: View {
    let systemImage: String
    let title: String

    var body: some View {
        VisualHoverState { isHovering in
            VisualCapsuleIconTextLabel(
                systemImage: systemImage,
                title: title,
                backgroundColor: .white.opacity(ViewerControlVisualStyle.capsuleBackgroundOpacity(isHovering: isHovering))
            )
        }
    }
}
