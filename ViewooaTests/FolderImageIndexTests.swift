import XCTest
@testable import Viewooa

final class FolderImageIndexTests: XCTestCase {
    func testSortsSupportedImagesByFilename() throws {
        let urls = [
            URL(fileURLWithPath: "/tmp/c.png"),
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.heic"),
            URL(fileURLWithPath: "/tmp/readme.md")
        ]

        let result = FolderImageIndex.sortedImageURLs(from: urls)
        XCTAssertEqual(result.map(\.lastPathComponent), ["a.jpg", "b.heic", "c.png"])
    }

    func testFindsCurrentIndexForOpenedFile() throws {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg"),
            URL(fileURLWithPath: "/tmp/c.jpg")
        ]

        let index = FolderImageIndex.currentIndex(
            for: URL(fileURLWithPath: "/tmp/b.jpg"),
            in: urls
        )

        XCTAssertEqual(index, 1)
    }
}
