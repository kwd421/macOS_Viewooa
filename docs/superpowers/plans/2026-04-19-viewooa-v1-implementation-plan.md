# Viewooa v1 Implementation Plan

> Index for the original 2026-04-19 implementation plan. The detailed tasks are split so Markdown files stay under 500 lines.

**For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first usable version of a Honeyview-style macOS image viewer with fast single-image browsing, zoom controls, and bounded preloading.

**Architecture:** Use a mixed macOS app architecture with a SwiftUI shell for app lifecycle, windows, and toolbar wiring, plus an AppKit viewer core for image rendering, zoom, pan, gestures, and keyboard-driven navigation. Keep v1 intentionally small: open file or folder, browse images by filename order, fit or actual-size viewing, rotate, fullscreen, and resilient error handling.

**Tech Stack:** Swift, SwiftUI, AppKit, ImageIO, UniformTypeIdentifiers, XCTest, Xcode macOS app target

## Plan Files

- `2026-04-19-viewooa-v1-plan-tasks-1-3.md`: bootstrap, folder indexing, viewer state, and open flows.
- `2026-04-19-viewooa-v1-plan-tasks-4-7.md`: AppKit viewer core, preloading/cache management, toolbar polish, final verification, and self-review.

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
