# Viewooa v1 Implementation Plan: Tasks 4-7

> Split from `2026-04-19-viewooa-v1-implementation-plan.md` to keep Markdown files under 500 lines.

## Task 4: Build the AppKit Image Viewer Core

**Files:**
- Create: `Viewooa/Viewer/ImageViewportState.swift`
- Create: `Viewooa/Viewer/ImageViewerNSView.swift`
- Create: `Viewooa/Viewer/ImageViewerContainerView.swift`
- Modify: `Viewooa/ViewerWindowShell.swift`

- [ ] **Step 1: Write the AppKit bridge and canvas wrapper**

Write `Viewooa/Viewer/ImageViewerContainerView.swift`:

```swift
import SwiftUI

struct ImageViewerContainerView: NSViewRepresentable {
    @ObservedObject var viewerState: ViewerState

    func makeNSView(context: Context) -> ImageViewerNSView {
        ImageViewerNSView()
    }

    func updateNSView(_ nsView: ImageViewerNSView, context: Context) {
        nsView.apply(
            imageURL: viewerState.currentImageURL,
            zoomMode: viewerState.zoomMode,
            rotationQuarterTurns: viewerState.rotationQuarterTurns
        )
    }
}
```

- [ ] **Step 2: Implement zoom, fit, actual size, and pan behavior**

Write `Viewooa/Viewer/ImageViewerNSView.swift` around an `NSScrollView` and `NSImageView`:

```swift
import AppKit

final class ImageViewerNSView: NSView {
    private let scrollView = NSScrollView()
    private let imageView = NSImageView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        imageView.imageScaling = .scaleNone
        scrollView.documentView = imageView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.05
        scrollView.maxMagnification = 8.0
        addSubview(scrollView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        scrollView.frame = bounds
    }

    func apply(imageURL: URL?, zoomMode: ZoomMode, rotationQuarterTurns: Int) {
        guard let imageURL else {
            imageView.image = nil
            return
        }

        imageView.image = NSImage(contentsOf: imageURL)

        switch zoomMode {
        case .fit:
            scrollView.magnification = min(bounds.width / max(imageView.image?.size.width ?? 1, 1), 1.0)
        case .actualSize:
            scrollView.magnification = 1.0
        case let .custom(scale):
            scrollView.magnification = scale
        }
    }
}
```

- [ ] **Step 3: Embed the AppKit viewer in the SwiftUI shell**

Update `Viewooa/ViewerWindowShell.swift`:

```swift
import SwiftUI

struct ViewerWindowShell: View {
    @StateObject private var viewerState = ViewerState()

    var body: some View {
        ImageViewerContainerView(viewerState: viewerState)
            .background(Color.black)
            .toolbar {
                Button("Prev") { viewerState.showPreviousImage() }
                Button("Next") { viewerState.showNextImage() }
                Button("Fit") { viewerState.zoomMode = .fit }
                Button("100%") { viewerState.zoomMode = .actualSize }
            }
    }
}
```

- [ ] **Step 4: Build and manually verify zoom behavior**

Run:

```bash
xcodebuild -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' build
open Viewooa.xcodeproj
```

Expected manual result: open the app, load an image, confirm fit mode, 100% mode, and panning while zoomed

- [ ] **Step 5: Commit the AppKit viewer core**

Run:

```bash
git add Viewooa/Viewer/ImageViewportState.swift Viewooa/Viewer/ImageViewerNSView.swift Viewooa/Viewer/ImageViewerContainerView.swift Viewooa/ViewerWindowShell.swift
git commit -m "feat: add AppKit image viewer core"
```

## Task 5: Add Preloading and Bounded Cache Management

**Files:**
- Create: `Viewooa/Core/ImagePreloadQueue.swift`
- Modify: `Viewooa/Core/ViewerState.swift`
- Test: `ViewooaTests/ImagePreloadQueueTests.swift`

- [ ] **Step 1: Write failing tests for neighbor targeting and eviction**

Write `ViewooaTests/ImagePreloadQueueTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild test -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' -only-testing:ViewooaTests/ImagePreloadQueueTests
```

Expected: FAIL because `ImagePreloadQueue` does not exist yet

- [ ] **Step 3: Implement a small preload queue with bounded caching**

Write `Viewooa/Core/ImagePreloadQueue.swift`:

```swift
import AppKit
import Foundation

final class ImagePreloadQueue {
    private let cache = NSCache<NSURL, NSImage>()
    private let maxCachedImages: Int
    private var insertionOrder: [URL] = []

    init(maxCachedImages: Int = 4) {
        self.maxCachedImages = maxCachedImages
        cache.countLimit = maxCachedImages
    }

    func targetURLs(for urls: [URL], currentIndex: Int) -> [URL] {
        let candidateIndexes = [currentIndex - 1, currentIndex + 1, currentIndex + 2, currentIndex + 3]
        return candidateIndexes.compactMap { index in
            guard urls.indices.contains(index) else { return nil }
            return urls[index]
        }
    }

    func store(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
        insertionOrder.removeAll { $0 == url }
        insertionOrder.append(url)
        while insertionOrder.count > maxCachedImages {
            let evicted = insertionOrder.removeFirst()
            cache.removeObject(forKey: evicted as NSURL)
        }
    }

    func image(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }
}
```

- [ ] **Step 4: Integrate preload refresh into `ViewerState`**

Extend `ViewerState` so `showNextImage()` and `showPreviousImage()` call a preload refresh hook after updating `currentImageURL`.

Core integration shape:

```swift
private let preloadQueue = ImagePreloadQueue()

private func refreshPreloadTargets() {
    guard let index else { return }
    let targets = preloadQueue.targetURLs(for: index.imageURLs, currentIndex: index.currentIndex)
    for url in targets where preloadQueue.image(for: url) == nil {
        if let image = NSImage(contentsOf: url) {
            preloadQueue.store(image, for: url)
        }
    }
}
```

- [ ] **Step 5: Run tests and commit**

Run:

```bash
xcodebuild test -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' -only-testing:ViewooaTests/ImagePreloadQueueTests
git add Viewooa/Core/ImagePreloadQueue.swift Viewooa/Core/ViewerState.swift ViewooaTests/ImagePreloadQueueTests.swift
git commit -m "feat: add bounded image preload cache"
```

Expected: tests PASS and commit succeeds

## Task 6: Polish Toolbar Actions, Errors, and Fullscreen Behavior

**Files:**
- Modify: `Viewooa/ViewerWindowShell.swift`
- Modify: `Viewooa/Core/ViewerState.swift`
- Modify: `Viewooa/Viewer/ImageViewerNSView.swift`

- [ ] **Step 1: Add toolbar actions for rotate, zoom in, and zoom out**

Update the toolbar wiring in `Viewooa/ViewerWindowShell.swift`:

```swift
ToolbarItemGroup {
    Button("Prev") { viewerState.showPreviousImage() }
    Button("Next") { viewerState.showNextImage() }
    Button("Fit") { viewerState.zoomMode = .fit }
    Button("100%") { viewerState.zoomMode = .actualSize }
    Button("+") { viewerState.zoomIn() }
    Button("-") { viewerState.zoomOut() }
    Button("Rotate") { viewerState.rotateClockwise() }
}
```

- [ ] **Step 2: Add simple empty and error states**

Expose one lightweight status string from `ViewerState`:

```swift
var overlayMessage: String? {
    if let lastErrorMessage { return lastErrorMessage }
    if currentImageURL == nil { return "Open a file or folder to begin" }
    return nil
}
```

Render that message on top of the black background when no image is loaded.

- [ ] **Step 3: Add keyboard shortcuts and fullscreen-friendly behavior**

Add commands:

```swift
.commands {
    CommandGroup(after: .toolbar) {
        Button("Next Image") { viewerState.showNextImage() }.keyboardShortcut(.rightArrow, modifiers: [])
        Button("Previous Image") { viewerState.showPreviousImage() }.keyboardShortcut(.leftArrow, modifiers: [])
    }
}
```

Ensure the main viewer remains the dominant content area in fullscreen by avoiding side panels or inspectors in v1.

- [ ] **Step 4: Build and run a manual smoke test**

Run:

```bash
xcodebuild -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' build
```

Manual verification:

- Open a file inside a folder
- Navigate forward and backward quickly
- Click `Fit` then `100%`
- Enter fullscreen and leave fullscreen
- Verify corrupt or unsupported files do not break the session

- [ ] **Step 5: Commit the polish pass**

Run:

```bash
git add Viewooa/ViewerWindowShell.swift Viewooa/Core/ViewerState.swift Viewooa/Viewer/ImageViewerNSView.swift
git commit -m "feat: polish toolbar, errors, and fullscreen behavior"
```

## Task 7: Final Verification and Packaging Readiness

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Document build and run instructions**

Expand `README.md`:

```md
## Build

```bash
xcodebuild -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' build
```

## Current capabilities

- Open image or folder
- Browse by filename order
- Fit to window and 100% viewing
- Rotate and navigate
- Bounded neighbor preload
```

- [ ] **Step 2: Run the full macOS test suite**

Run:

```bash
xcodebuild test -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS'
```

Expected: all tests PASS

- [ ] **Step 3: Run one final build**

Run:

```bash
xcodebuild -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' build
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Review the app manually against the spec**

Manual checklist:

- Large single-image viewing is the main mode
- Next and previous feel immediate in normal usage
- The UI is minimal
- Windowed and fullscreen use both work well
- File management and archive features are still out of scope

- [ ] **Step 5: Commit the release-ready v1**

Run:

```bash
git add README.md
git commit -m "docs: finalize Viewooa v1 usage notes"
```

## Self-Review

Spec coverage check:

- Single-image-first viewer: covered by Tasks 1, 4, and 6
- Filename-based folder ordering: covered by Task 2
- Open file or folder flow: covered by Task 3
- Fit-to-window, 100%, rotate, pan: covered by Tasks 4 and 6
- Near-instant neighboring navigation via preload: covered by Task 5
- Error and empty handling: covered by Task 6
- Fullscreen support: covered by Task 6
- Out-of-scope features remain excluded: reinforced by Tasks 6 and 7

Placeholder scan:

- No `TODO`, `TBD`, or deferred placeholders remain in task steps
- All commands, files, and initial code shapes are explicit

Type consistency check:

- `ViewerState`, `FolderImageIndex`, `ImagePreloadQueue`, and `ZoomMode` names are used consistently across all tasks
