import XCTest
@testable import Viewooa

final class FolderImageIndexTests: XCTestCase {
    func testSortsSupportedImagesByFilename() throws {
        let urls = [
            URL(fileURLWithPath: "/tmp/c.png"),
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.heic"),
            URL(fileURLWithPath: "/tmp/document.pdf"),
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

    func testOpenBrowserDirectoryListingIncludesPDFs() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ViewooaDataSourceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try Data().write(to: directory.appendingPathComponent("image.jpg"))
        try Data().write(to: directory.appendingPathComponent("document.pdf"))
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("nested", isDirectory: true), withIntermediateDirectories: true)

        let entries = try OpenBrowserDataSource.loadEntries(in: directory, sortOption: .name, ascending: true)

        XCTAssertEqual(entries.map(\.name), ["nested", "document.pdf", "image.jpg"])
    }
}
