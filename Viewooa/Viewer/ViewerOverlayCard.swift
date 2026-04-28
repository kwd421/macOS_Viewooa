import SwiftUI

enum OverlayKind {
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

struct ViewerOverlayCard: View {
    let kind: OverlayKind
    let onOpen: () -> Void
    let onDismissError: () -> Void

    var body: some View {
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
                Button("Open...", action: onOpen)

                if case .error = kind {
                    Button("Dismiss", action: onDismissError)
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
}
