import AppKit
import XCTest
@testable import Viewooa

final class ImagePreloadQueueTests: XCTestCase {
    func testTargetsPreviousAndNextImages() {
        let urls = (0..<6).map { URL(fileURLWithPath: "/tmp/\($0).jpg") }
        let queue = ImagePreloadQueue()

        let targets = queue.targetURLs(for: urls, currentIndex: 2)

        XCTAssertEqual(targets.map(\.lastPathComponent), ["1.jpg", "3.jpg", "4.jpg", "5.jpg"])
    }

    func testEvictsFarAwayImages() {
        let queue = ImagePreloadQueue(maxCachedImages: 3)
        queue.store(NSImage(size: NSSize(width: 10, height: 10)), for: URL(fileURLWithPath: "/tmp/a.jpg"))
        queue.store(NSImage(size: NSSize(width: 10, height: 10)), for: URL(fileURLWithPath: "/tmp/b.jpg"))
        queue.store(NSImage(size: NSSize(width: 10, height: 10)), for: URL(fileURLWithPath: "/tmp/c.jpg"))
        queue.store(NSImage(size: NSSize(width: 10, height: 10)), for: URL(fileURLWithPath: "/tmp/d.jpg"))

        XCTAssertNil(queue.image(for: URL(fileURLWithPath: "/tmp/a.jpg")))
    }
}
