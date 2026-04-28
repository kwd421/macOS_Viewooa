import SwiftUI
import AppKit

enum OpenBrowserScrollCoordinateSpace {
    static let name = "OpenBrowserScrollCoordinateSpace"
}

enum OpenBrowserScrollAnchor {
    static func id(for entryID: String) -> String {
        "OpenBrowserScrollAnchor::\(entryID)"
    }
}

struct OpenBrowserVisibleEntryFramePreferenceKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct OpenBrowserResizeAnchor: Equatable {
    let id: String
    let minY: CGFloat
}

struct OpenBrowserScrollViewResolver: NSViewRepresentable {
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

extension View {
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
