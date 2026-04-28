import Foundation

struct OpenBrowserPathResolver {
    static func components(for directory: URL) -> [OpenBrowserPathComponent] {
        let components = directory.standardizedFileURL.pathComponents
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

    static func expandedPath(from editablePath: String) -> String {
        guard editablePath.hasPrefix("~") else { return editablePath }
        return (editablePath as NSString).expandingTildeInPath
    }

    static func readableDirectory(from editablePath: String) -> URL? {
        let expandedPath = expandedPath(from: editablePath)
        return OpenBrowserDataSource.validDirectory(URL(fileURLWithPath: expandedPath))
    }

    static func unreadablePathMessage(for editablePath: String) -> String {
        let expandedPath = expandedPath(from: editablePath)
        return "The path \(expandedPath) is not a readable folder."
    }

    static func accessErrorMessage(for directory: URL) -> String {
        let directoryName = directory.lastPathComponent.isEmpty ? directory.path : directory.lastPathComponent
        return "Viewooa needs permission to read \(directoryName). Allow access in the macOS prompt, or enable access in System Settings."
    }
}
