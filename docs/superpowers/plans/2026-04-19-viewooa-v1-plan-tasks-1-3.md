# Viewooa v1 Implementation Plan: Tasks 1-3

> Split from `2026-04-19-viewooa-v1-implementation-plan.md` to keep Markdown files under 500 lines.

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
