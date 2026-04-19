import SwiftUI

struct ViewerWindowShell: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("Open a file or folder to begin")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 900, minHeight: 620)
    }
}
