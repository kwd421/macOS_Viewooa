import XCTest
@testable import Viewooa

final class OpenBrowserPathResolverTests: XCTestCase {
    func testBuildsFinderLikePathComponents() {
        let components = OpenBrowserPathResolver.components(for: URL(fileURLWithPath: "/Users/seinel/Downloads"))

        XCTAssertEqual(components.map(\.title), ["Macintosh HD", "Users", "seinel", "Downloads"])
        XCTAssertEqual(components.map(\.url.path), ["/", "/Users", "/Users/seinel", "/Users/seinel/Downloads"])
    }

    func testExpandsTildePathsBeforeValidation() {
        let expandedPath = OpenBrowserPathResolver.expandedPath(from: "~/")

        XCTAssertFalse(expandedPath.hasPrefix("~"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: expandedPath))
    }

    func testReadableDirectoryRejectsUnreadableOrMissingPath() {
        let missingPath = "/tmp/viewooa-missing-\(UUID().uuidString)"

        XCTAssertNil(OpenBrowserPathResolver.readableDirectory(from: missingPath))
    }
}
