# Viewooa Implementation Map

This map translates `docs/product/DESIGN.md` into the current code architecture. Use it when deciding where a new feature belongs.

## Product Areas

### Photo Viewer

Purpose:
Display and navigate images with minimal chrome.

Primary code:
- `Viewooa/Viewer/PhotoViewerFeatureView.swift`
- `Viewooa/Viewer/PhotoViewerStore.swift`
- `Viewooa/Viewer/ImageViewerNSView.swift`
- `Viewooa/Viewer/ImageViewerContainerView.swift`
- `Viewooa/Viewer/ViewerControlBars.swift`

Owns:
- Image display, fit, actual size, zoom, pan, rotate.
- Page layout modes, slideshow, metadata overlay.
- Viewer control bars and transient viewer notices.

Must not own:
- Browser sidebar state.
- Folder/favorite organization policy.
- AI file mutation logic.

### Browser

Purpose:
Browse, select, search, and open files/folders in a Finder/Photos-inspired surface.

Primary code:
- `Viewooa/OpenBrowser/`
- `Viewooa/Shared/ImageBrowserDisplayMode.swift`
- `Viewooa/Shared/ImageBrowserThumbnail.swift`
- `Viewooa/Shared/ThumbnailSizeStepperControl.swift`

Owns:
- Sidebar, locations, path, grid/list browsing.
- Selection model and open confirmation behavior.
- Thumbnail presentation and browser-specific layout.

Must not own:
- Viewer zoom/pan/rendering internals.
- Long-term cross-feature favorites or tags directly.
- File mutation execution without a preview/command layer.

### App Bridge

Purpose:
Coordinate viewer and browser without coupling their internals.

Primary code:
- `Viewooa/AppBridge/ViewooaBridge.swift`
- `Viewooa/AppBridge/BrowserOverlayStore.swift`
- `Viewooa/ViewerWindowShell.swift`

Owns:
- Which overlay is visible.
- Routing browser selections into the viewer.
- Shared presentation state such as image browser display mode and thumbnail size.
- Future cross-feature state sync such as favorites, tags, ratings, and AI command previews.

Must not own:
- Low-level image rendering.
- Browser cell layout details.
- Direct unsafe file operations.

## Feature Routing Rules

- Viewer-only behavior goes into `PhotoViewerStore`, `PhotoViewerFeatureView`, or the focused `ImageViewer...` coordinator.
- Browser-only behavior goes into `OpenBrowser...` stores/views/coordinators.
- Anything that links viewer and browser goes through `ViewooaBridge`.
- Anything that changes user files must go through an explicit previewable command model before execution.
- Anything AI-related must call the same command model as the UI; it must not mutate files through a parallel path.

## Design Checklist For New Work

- Does the feature preserve content-first presentation?
- Is the action discoverable from UI, menu, context menu, or shortcut?
- If files are changed, is the operation previewed or undoable?
- Does the feature work without AI?
- Does it keep Photo Viewer independently releasable?
- Does Browser remain replaceable by native `NSOpenPanel` or a future standalone browser app?

## Current Implementation Priorities

### P0 Alignment

- Keep the viewer stable: fit/actual/zoom/pan must be predictable.
- Keep browser opening replaceable: bottom toolbar open action should remain bridge-routed.
- Keep menu bar commands in sync with toolbar/context actions.
- Avoid hidden file mutations until a command model exists.

### P1 Alignment

- Improve browser selection, sorting, and metadata in small slices.
- Add favorites/tags through bridge-owned shared state, not browser-only state.
- Add thumbnail cache and progressive loading improvements behind the browser data source.

### P2 Alignment

- Add a preview-first command model before AI features.
- Add command palette/App Intents/MCP only after command model boundaries are explicit.
