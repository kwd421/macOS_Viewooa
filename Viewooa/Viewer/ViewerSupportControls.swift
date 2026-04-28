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

struct ActualSizeIcon: View {
    var body: some View {
        Image(systemName: "1.magnifyingglass")
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 30, height: 30)
    }
}
