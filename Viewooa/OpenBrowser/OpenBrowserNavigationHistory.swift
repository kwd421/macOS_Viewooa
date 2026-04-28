import Foundation

struct OpenBrowserNavigationHistory {
    private(set) var backStack: [URL] = []
    private(set) var forwardStack: [URL] = []

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }

    mutating func recordNavigation(from currentURL: URL) {
        backStack.append(currentURL)
        forwardStack.removeAll()
    }

    mutating func popBack(currentURL: URL) -> URL? {
        guard let previousURL = backStack.popLast() else { return nil }
        forwardStack.append(currentURL)
        return previousURL
    }

    mutating func popForward(currentURL: URL) -> URL? {
        guard let nextURL = forwardStack.popLast() else { return nil }
        backStack.append(currentURL)
        return nextURL
    }
}
