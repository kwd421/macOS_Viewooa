import AppKit
import XCTest
@testable import Viewooa

final class ImagePreloadQueueTests: XCTestCase {
    func testWarmupLoadsImagesOffMainThread() async {
        let url = URL(fileURLWithPath: "/tmp/preload.jpg")
        let expectedImage = NSImage(size: NSSize(width: 10, height: 10))
        let loadedOffMainThread = expectation(description: "loaded off main thread")

        let queue = ImagePreloadQueue { loadedURL in
            XCTAssertEqual(loadedURL, url)
            XCTAssertFalse(Thread.isMainThread)
            loadedOffMainThread.fulfill()
            return expectedImage
        }

        queue.preload(urls: [url])

        await fulfillment(of: [loadedOffMainThread], timeout: 1.0)
        XCTAssertTrue(queue.image(for: url) === expectedImage)
    }

    func testTargetsPreviousAndNextImages() {
        let urls = (0..<6).map { URL(fileURLWithPath: "/tmp/\($0).jpg") }
        let queue = ImagePreloadQueue()

        let targets = queue.targetURLs(for: urls, currentIndex: 2)

        XCTAssertEqual(targets.map(\.lastPathComponent), ["1.jpg", "3.jpg", "4.jpg", "5.jpg"])
    }

    func testTargetsOnlyAdjacentImagesWhenBrowsingRaw() {
        let urls = (0..<6).map { URL(fileURLWithPath: "/tmp/\($0).NEF") }
        let queue = ImagePreloadQueue()

        let targets = queue.targetURLs(for: urls, currentIndex: 2)

        XCTAssertEqual(targets.map(\.lastPathComponent), ["1.NEF", "3.NEF"])
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
