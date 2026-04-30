import SwiftUI
import AppKit

struct OpenBrowserFooter: View {
    let currentDirectory: URL
    let pathComponents: [OpenBrowserPathComponent]
    let openButtonTitle: String
    @Binding var isPathEditing: Bool
    @Binding var editablePath: String
    let isPathEditorFocused: FocusState<Bool>.Binding
    let onNavigate: (URL) -> Void
    let onBeginPathEditing: () -> Void
    let onCommitEditedPath: () -> Void
    let onDismiss: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            pathBar
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button("Cancel", action: onDismiss)
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel("Cancel")
                .accessibilityIdentifier("OpenBrowserCancelButton")

            Button(openButtonTitle, action: onOpen)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(openButtonTitle)
                .accessibilityIdentifier("OpenBrowserOpenButton")
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(Color.openBrowserContentBackground)
        .overlay(alignment: .top) {
            Divider().overlay(VisualInteractionPalette.openBrowserContentDivider)
        }
    }

    @ViewBuilder
    private var pathBar: some View {
        if isPathEditing {
            TextField("Path", text: $editablePath)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, weight: .regular))
                .focused(isPathEditorFocused)
                .onSubmit(onCommitEditedPath)
                .onExitCommand {
                    isPathEditing = false
                }
        } else {
            HStack(spacing: 4) {
                ForEach(pathComponents) { component in
                    PathComponentButton(component: component, onNavigate: onNavigate)

                    if component.id != pathComponents.last?.id {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }

                Button(action: onBeginPathEditing) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.001))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .visualHitArea(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit Path")
                .frame(minWidth: 24)
                .frame(maxWidth: .infinity)
                .visualHitArea(Rectangle())
                .contextMenu {
                    pathContextMenuItems
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.openBrowserControlFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .visualHitArea(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .contextMenu {
                pathContextMenuItems
            }
        }
    }

    @ViewBuilder
    private var pathContextMenuItems: some View {
        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(currentDirectory.path, forType: .string)
        }

        Button("Edit Path", action: onBeginPathEditing)
    }
}

private struct PathComponentButton: View {
    let component: OpenBrowserPathComponent
    let onNavigate: (URL) -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)

        VisualHoverContentButton(
            accessibilityLabel: component.title,
            shape: shape,
            style: Self.style
        ) {
                onNavigate(component.url)
        } label: { _ in
            Text(component.title)
                .font(.system(size: 12, weight: .regular))
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 5)
                .frame(height: 20)
        }
    }

    private static let style = VisualHoverContentStyle(
        backgroundColor: VisualInteractionPalette.subtleToolbarHover
    )
}
