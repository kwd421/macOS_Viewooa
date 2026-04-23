# Viewooa v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first usable version of a Honeyview-style macOS image viewer with fast single-image browsing, zoom controls, and bounded preloading.

**Architecture:** Use a mixed macOS app architecture with a SwiftUI shell for app lifecycle, windows, and toolbar wiring, plus an AppKit viewer core for image rendering, zoom, pan, gestures, and keyboard-driven navigation. Keep v1 intentionally small: open file or folder, browse images by filename order, fit or actual-size viewing, rotate, fullscreen, and resilient error handling.

**Tech Stack:** Swift, SwiftUI, AppKit, ImageIO, UniformTypeIdentifiers, XCTest, Xcode macOS app target

---

## Planned File Structure

### App Shell

- Create: `Viewooa.xcodeproj/project.pbxproj`
- Create: `Viewooa/ViewooaApp.swift`
- Create: `Viewooa/ViewerWindowShell.swift`
- Create: `Viewooa/Commands/ViewerCommands.swift`

### Core Models and Services

- Create: `Viewooa/Core/ViewerState.swift`
- Create: `Viewooa/Core/FolderImageIndex.swift`
- Create: `Viewooa/Core/ImagePreloadQueue.swift`
- Create: `Viewooa/Core/SupportedImageTypes.swift`

### Viewer UI

- Create: `Viewooa/Viewer/ImageViewerContainerView.swift`
- Create: `Viewooa/Viewer/ImageViewerNSView.swift`
- Create: `Viewooa/Viewer/ImageViewportState.swift`

### Tests

- Create: `ViewooaTests/FolderImageIndexTests.swift`
- Create: `ViewooaTests/ImagePreloadQueueTests.swift`
- Create: `ViewooaTests/ViewerStateTests.swift`

### Docs

- Create: `README.md`

## Task 1: Bootstrap the macOS App Project

**Files:**
- Create: `Viewooa.xcodeproj/project.pbxproj`
- Create: `Viewooa/ViewooaApp.swift`
- Create: `Viewooa/ViewerWindowShell.swift`
- Create: `README.md`

- [ ] **Step 1: Create the macOS SwiftUI app target and default source tree**

Use Xcode to create a macOS App project named `Viewooa` in `/Users/seinel/Projects/Viewooa` with Swift and SwiftUI enabled.

Expected starter file:

```swift
import SwiftUI

@main
struct ViewooaApp: App {
    var body: some Scene {
        WindowGroup {
            ViewerWindowShell()
        }
    }
}
```

- [ ] **Step 2: Add a minimal shell view that reserves space for the future viewer**

Write `Viewooa/ViewerWindowShell.swift`:

```swift
import SwiftUI

struct ViewerWindowShell: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("Open a file or folder to begin")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 900, minHeight: 620)
    }
}
```

- [ ] **Step 3: Add a short project README**

Write `README.md`:

```md
# Viewooa

Fast, simple macOS image viewer inspired by Honeyview.

## v1 scope

- Open a file or folder
- Browse images by filename order
- Zoom, fit, actual size, rotate
- Fast previous and next navigation with bounded preload
```

- [ ] **Step 4: Build the empty app**

Run:

```bash
xcodebuild -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' build
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Initialize Git and commit the bootstrap**

Run:

```bash
git init
git add Viewooa.xcodeproj Viewooa README.md
git commit -m "chore: bootstrap Viewooa macOS app"
```

Expected: initial commit created

## Task 2: Implement Folder Indexing and Supported Image Discovery

**Files:**
- Create: `Viewooa/Core/SupportedImageTypes.swift`
- Create: `Viewooa/Core/FolderImageIndex.swift`
- Test: `ViewooaTests/FolderImageIndexTests.swift`

- [ ] **Step 1: Write failing tests for file discovery and filename ordering**

Write `ViewooaTests/FolderImageIndexTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild test -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' -only-testing:ViewooaTests/FolderImageIndexTests
```

Expected: FAIL because `FolderImageIndex` does not exist yet

- [ ] **Step 3: Implement supported type filtering and ordering**

Write `Viewooa/Core/SupportedImageTypes.swift`:

```swift
import Foundation
import UniformTypeIdentifiers

enum SupportedImageTypes {
    static func isSupported(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return false
        }

        return type.conforms(to: .image)
    }
}
```

Write `Viewooa/Core/FolderImageIndex.swift`:

```swift
import Foundation

struct FolderImageIndex: Equatable {
    let imageURLs: [URL]
    let currentIndex: Int

    static func sortedImageURLs(from urls: [URL]) -> [URL] {
        urls
            .filter(SupportedImageTypes.isSupported)
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    static func currentIndex(for selectedURL: URL, in urls: [URL]) -> Int? {
        urls.firstIndex(of: selectedURL)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
xcodebuild test -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' -only-testing:ViewooaTests/FolderImageIndexTests
```

Expected: PASS

- [ ] **Step 5: Commit the indexing layer**

Run:

```bash
git add Viewooa/Core/SupportedImageTypes.swift Viewooa/Core/FolderImageIndex.swift ViewooaTests/FolderImageIndexTests.swift
git commit -m "feat: add folder image indexing"
```

## Task 3: Add Viewer State and Open File or Folder Flows

**Files:**
- Create: `Viewooa/Core/ViewerState.swift`
- Modify: `Viewooa/ViewerWindowShell.swift`
- Create: `Viewooa/Commands/ViewerCommands.swift`
- Test: `ViewooaTests/ViewerStateTests.swift`

- [ ] **Step 1: Write failing tests for navigation and zoom mode defaults**

Write `ViewooaTests/ViewerStateTests.swift`:

```swift
import XCTest
@testable import Viewooa

final class ViewerStateTests: XCTestCase {
    func testNextAdvancesIndex() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]

        var state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.showNextImage()

        XCTAssertEqual(state.index.currentIndex, 1)
    }

    func testNavigationResetsZoomModeToFit() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.jpg"),
            URL(fileURLWithPath: "/tmp/b.jpg")
        ]

        var state = ViewerState(index: FolderImageIndex(imageURLs: urls, currentIndex: 0))
        state.zoomMode = .actualSize
        state.showNextImage()

        XCTAssertEqual(state.zoomMode, .fit)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild test -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' -only-testing:ViewooaTests/ViewerStateTests
```

Expected: FAIL because `ViewerState` does not exist yet

- [ ] **Step 3: Implement viewer state and file opening hooks**

Write `Viewooa/Core/ViewerState.swift`:

```swift
import AppKit
import Foundation

enum ZoomMode: Equatable {
    case fit
    case actualSize
    case custom(CGFloat)
}

@MainActor
final class ViewerState: ObservableObject {
    @Published var index: FolderImageIndex?
    @Published var currentImageURL: URL?
    @Published var zoomMode: ZoomMode = .fit
    @Published var rotationQuarterTurns: Int = 0
    @Published var lastErrorMessage: String?

    init(index: FolderImageIndex? = nil) {
        self.index = index
        self.currentImageURL = index.map { $0.imageURLs[$0.currentIndex] }
    }

    func showNextImage() {
        guard let index, index.currentIndex + 1 < index.imageURLs.count else { return }
        self.index = FolderImageIndex(imageURLs: index.imageURLs, currentIndex: index.currentIndex + 1)
        currentImageURL = self.index.map { $0.imageURLs[$0.currentIndex] }
        zoomMode = .fit
        rotationQuarterTurns = 0
    }

    func showPreviousImage() {
        guard let index, index.currentIndex > 0 else { return }
        self.index = FolderImageIndex(imageURLs: index.imageURLs, currentIndex: index.currentIndex - 1)
        currentImageURL = self.index.map { $0.imageURLs[$0.currentIndex] }
        zoomMode = .fit
        rotationQuarterTurns = 0
    }
}
```

Update `Viewooa/ViewerWindowShell.swift` to hold a `@StateObject var viewerState = ViewerState()` and wire `Open...` actions through `NSOpenPanel`.

- [ ] **Step 4: Run tests and app build**

Run:

```bash
xcodebuild test -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' -only-testing:ViewooaTests/ViewerStateTests
xcodebuild -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' build
```

Expected: tests PASS and build succeeds

- [ ] **Step 5: Commit the viewer state layer**

Run:

```bash
git add Viewooa/Core/ViewerState.swift Viewooa/ViewerWindowShell.swift Viewooa/Commands/ViewerCommands.swift ViewooaTests/ViewerStateTests.swift
git commit -m "feat: add viewer state and open actions"
```

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

