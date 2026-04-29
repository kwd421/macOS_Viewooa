# Viewooa

Viewooa is a native macOS photo viewer and visual file browser. The product goal is calm, fast, Apple-like browsing where photos and files stay more important than the app chrome.

## Product Direction

The design source of truth lives in:

- [Product Design Constitution](docs/product/DESIGN.md)
- [Implementation Map](docs/product/IMPLEMENTATION_MAP.md)

Before adding major behavior, check that the work fits the design principles: native first, content first, reversible file operations, and quiet AI assistance through explicit app commands.

## Architecture

Viewooa is organized into three product areas:

- `Photo Viewer`: image rendering, fit/actual size, zoom, pan, rotate, page layout, slideshow, and viewer overlays.
- `Browser`: Finder/Photos-inspired browsing, sidebar, path, grid/list display, selection, and open confirmation.
- `App Bridge`: cross-feature routing between viewer and browser, shared overlay state, and future shared favorites/tags/AI command previews.

The photo viewer should remain independently releasable. The browser should remain replaceable by native macOS open panels or a future standalone browser app.

## Run

Double-click:

```text
Open Viewooa.command
```

Or run from Terminal:

```bash
./script/build_and_run.sh
```

## Build And Test

Build:

```bash
xcodebuild -project Viewooa.xcodeproj -scheme Viewooa -configuration Debug -derivedDataPath .build/DerivedData build
```

Run tests:

```bash
xcodebuild test -project Viewooa.xcodeproj -scheme Viewooa -configuration Debug -derivedDataPath .build/DerivedData
```

The app targets macOS 15.0 and Swift 6.

## Current Capabilities

- Open images and folders through the Viewooa browser flow.
- Browse folder images with previous/next controls and keyboard shortcuts.
- Fit all, fit width, fit height, actual size, zoom in/out, and pan oversized images.
- Use single page, two-page spread, cover mode, and vertical strip layouts.
- Show metadata, navigation count, slideshow controls, and post-processing options.
- Browse image lists through an Apple-inspired internal browser overlay.
- Keep viewer/browser communication routed through the app bridge.

## Working Rules

- Keep viewer-only behavior inside viewer stores/views/coordinators.
- Keep browser-only behavior inside browser stores/views/coordinators.
- Put cross-feature state in the bridge.
- Do not add hidden file mutations; risky file operations need preview and undo where possible.
- AI features must call the same safe command model as the UI.
