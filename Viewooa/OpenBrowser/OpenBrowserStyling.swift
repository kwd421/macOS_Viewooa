import SwiftUI
import AppKit

enum OpenBrowserLayout {
    static let titlebarControlHeight: CGFloat = 34
    static let titlebarButtonSize: CGFloat = 32
}

extension Color {
    static let openBrowserWindowBackground = Color(nsColor: .windowBackgroundColor)
    static let openBrowserContentBackground = Color(nsColor: .textBackgroundColor)
    static let openBrowserSidebarBackground = Color(nsColor: .underPageBackgroundColor)
    static let openBrowserSelection = Color(nsColor: .selectedContentBackgroundColor)
    static let openBrowserSidebarSelectionBackground = Color(nsColor: .unemphasizedSelectedContentBackgroundColor)
    static let openBrowserSeparator = Color(nsColor: .separatorColor).opacity(0.45)
    static let openBrowserControlFill = Color(nsColor: .controlBackgroundColor).opacity(0.64)
}
