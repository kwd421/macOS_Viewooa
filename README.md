# Viewooa

Fast, simple macOS image viewer inspired by Honeyview.

## Build

Open `Viewooa.xcodeproj` in Xcode and run the `Viewooa` scheme, or build from Terminal:

```bash
xcodebuild -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' build
```

Run the full test suite:

```bash
xcodebuild test -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS'
```

The app targets macOS 15.0 and builds with Xcode 26.4.1 / Swift 6.

## Current capabilities

- Open a single image file or an image folder
- Browse folder images by filename order
- Show one image large in a minimal viewer-first window
- Move to previous and next images with toolbar buttons or arrow keys
- Zoom in, zoom out, fit to window, and jump to 100%
- Rotate clockwise
- Reuse bounded neighbor preload for faster nearby navigation
- Show lightweight inline empty and error states
- Work in both standard windowed mode and fullscreen

## Shortcuts

- `Left Arrow`: previous image
- `Right Arrow`: next image
- `Command` + `=`: zoom in
- `Command` + `-`: zoom out
- `Command` + `0`: actual size
- `Command` + `R`: rotate right

## v1 non-goals

- Archive browsing
- File delete, move, or copy management
- Thumbnail-browser-first workflows
