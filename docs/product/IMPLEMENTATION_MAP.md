# Viewooa / 자체파인더 Implementation Map

This map translates `docs/product/DESIGN.md` into the current code architecture. Use it when deciding where a new feature belongs.

## Product Areas

### Viewooa Photo Viewer

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
- A quiet preference to make Viewooa the default app for supported image file types through public macOS default-app mechanisms, when feasible.

Must not own:
- 자체파인더 sidebar state.
- Folder/favorite organization policy.
- AI file mutation logic.

### 자체파인더

Purpose:
Browse, select, search, and open files/folders in a Finder-class surface.

Primary code:
- `Viewooa/OpenBrowser/`
- `Viewooa/Shared/ImageBrowserDisplayMode.swift`
- `Viewooa/Shared/ImageBrowserThumbnail.swift`
- `Viewooa/Shared/ThumbnailSizeStepperControl.swift`

Owns:
- Sidebar, locations, path, grid/list browsing.
- Selection model and open confirmation behavior.
- Thumbnail presentation and 자체파인더-specific layout.
- Finder-like path bar presentation, including selected-file final segments and per-segment system icons.
- All-file visibility, system icon fallback, Quick Look routing, default-app Open routing, and system-like Open With routing, including Viewooa as a normal compatible photo app for supported image types.
- Finder-like context menu composition for public/system-backed actions, while delegating system-owned behavior to macOS where possible.
- App-native tag presentation and editing, plus optional clearly labeled macOS Finder/system tag display, write, or sync.
- Finder-like package and app bundle presentation: treat packages as single items by default, use system Open behavior, and expose Show Package Contents for explicit inspection.

Must not own:
- Viewer zoom/pan/rendering internals.
- Long-term cross-feature favorites, app-native tags, ratings, or sync policy directly.
- File mutation execution without a preview/command layer.
- Direct custom handling for system-owned file behaviors such as mounting DMGs, choosing default apps, launching apps/packages, opening unrelated document types, or cloning private Finder extension behavior.

### App Bridge / Shared Metadata

Purpose:
Coordinate Viewooa and 자체파인더 without coupling their internals, and provide `SharedMetadataKit` for ecosystem state.

Primary code:
- `Viewooa/AppBridge/ViewooaBridge.swift`
- `Viewooa/AppBridge/BrowserOverlayStore.swift`
- `Viewooa/ViewerWindowShell.swift`
- Future: `Viewooa/SharedMetadataKit/`
- Future: `Viewooa/FileAccess/`

Owns:
- Which overlay is visible.
- Routing 자체파인더 selections into the Viewooa photo viewer.
- Shared presentation state such as image browser display mode and thumbnail size.
- SQLite-backed shared metadata ownership for favorites, app-native tags, ratings, and future AI command previews.
- Ecosystem behavior that lets Viewooa and 자체파인더 launch independently while improving when used together.
- Packaging expectation that installing either Viewooa or 자체파인더 includes the shared bridge/metadata capability.
- Durable metadata persistence safeguards: atomic/journaled writes, versioned migrations, pre-migration backups, corruption detection, explicit user-confirmed recovery, detailed backup comparison, and import/export paths.
- Layered file identity: app-owned `file_id` primary keys with path/bookmark/resource-id/volume/package/fingerprint observations instead of path-only keys.
- Distribution adapters: App Store sandbox/security-scoped access and direct/GitHub file access differences hidden behind `FileAccessManager` and metadata location providers.

Must not own:
- Low-level image rendering.
- 자체파인더 cell layout details.
- Direct unsafe file operations.

## Feature Routing Rules

- Viewer-only behavior goes into `PhotoViewerStore`, `PhotoViewerFeatureView`, or the focused `ImageViewer...` coordinator.
- 자체파인더-only behavior goes into `OpenBrowser...` stores/views/coordinators.
- Anything that links Viewooa and 자체파인더 goes through `ViewooaBridge`.
- Anything that changes user files must go through a command model with undo/recovery metadata. Direct user-initiated recoverable Finder-like actions should execute without nagging confirmations; previews/confirmations are for irreversible, AI/automation, metadata restore, ambiguous broad, risky batch, or unclear-undo operations.
- Anything AI-related must call the same command model as the UI; it must not mutate files through a parallel path.
- Shared metadata must use SQLite as the canonical store through `SharedMetadataKit`; do not use UserDefaults, plist, raw JSON, Finder/system tags, or per-app Core Data/SwiftData stores as the source of truth.
- Normal Open follows the user's macOS default app choice. Viewooa is reached through normal Open With/default-app behavior for supported images, not through prominent custom 자체파인더-only launch controls.
- App-native tags are primary. macOS Finder/system tags, if shown, written, or synchronized, must remain visually and behaviorally distinct and permission-aware. Sync conflicts must be reported to the user with explicit choices, not resolved silently.
- Packages and app bundles follow Finder semantics: present as package items by default, Open through macOS, and enter contents only through Show Package Contents.
- 자체파인더 should not expose open/save-dialog Open or Cancel buttons. It is a Finder-class browser, not a modal file picker.
- App Store/sandboxed builds should show discoverable inaccessible items as disabled with a clear permission explanation, not hide them as if they do not exist.
- New user-facing actions should be shaped so they can later be exposed through command palette, App Intents, or MCP without bypassing UI safety, permissions, preview, or undo rules.

## Design Checklist For New Work

- Does the feature preserve content-first presentation?
- Is the action discoverable from UI, menu, context menu, or shortcut?
- If files are changed, is the operation previewed or undoable?
- Does the feature work without AI?
- Does it keep Viewooa independently releasable?
- Does 자체파인더 remain replaceable by native `NSOpenPanel` or a future standalone browser app?

## Current Implementation Priorities

### P0 Alignment

- Keep the viewer stable: fit/actual/zoom/pan must be predictable.
- Keep 자체파인더 opening replaceable: the bottom viewer control-bar Open action should remain bridge-routed.
- Keep menu bar commands in sync with window toolbar, path bar, and context actions.
- Avoid hidden file mutations until a command model exists.
- Make 자체파인더 behave like a real file browser: show all files, browse folders, use the user's default app for normal Open, expose system-like Open With, include Viewooa as an ordinary compatible photo app for supported images, and delegate system-owned behavior to macOS.
- Fix thumbnail size stepping so `-` / `+` only disable at true min/max and each step creates a meaningful layout change.
- Align icon view to Finder-like top-left layout with native-feeling spacing and stable scroll position.
- Replace open/save-dialog bottom controls with a Finder-like path bar that shows the selected file and per-segment icons.

### P1 Alignment

- Improve 자체파인더 selection, focus, keyboard navigation, sorting, and metadata in small slices.
- Add Finder-like shortcuts: arrow navigation, Return/Cmd-Down open, Cmd-F search, type-to-select, and Space for Quick Look.
- Add Windows-style file cut/paste improvement: `Cmd+X` cuts selected files and `Cmd+V` moves/pastes them, while preserving undo/recovery behavior.
- Add Quick Look integration through macOS system APIs instead of custom preview decoding.
- Add Finder-like right-click menus using public macOS/system integrations first: Open, Open With, Move to Trash, Get Info, Rename, Compress, Duplicate, Make Alias, Quick Look, Copy, Share, tag colors, Tags, Quick Actions, and third-party services where feasible.
- Add video/audio hover preview with one active inline playback at a time.
- Add app-native favorites/tags through bridge-owned shared state, not 자체파인더-only state.
- Add optional Finder/system tag display, write, or sync only with clear labeling, permissions, undo/conflict handling, and separate semantics.
- Add thumbnail cache and progressive loading improvements behind the 자체파인더 data source.

### P2 Alignment

- Add Finder-style tabs. When asked to implement all remaining Finder work, confirm whether tabs are included before starting.
- Add a preview-first command model before AI features.
- Add command palette/App Intents/MCP only after command model boundaries are explicit, while keeping new work command-addressable as it is built.
