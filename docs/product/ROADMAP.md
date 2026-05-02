# Viewooa / 자체파인더 Roadmap

This roadmap tracks product-level status. It is intentionally practical: active work, completed work, deferred work, cancelled directions, and items that need verification should be easy to find before starting a new task.

## Active

### Viewooa Photo Viewer

- Keep optimization and memory safety as a top priority across Viewooa, 자체파인더, PDF, GIF, RAW, Webtoon, thumbnail, and preload paths. Avoid eager full-folder/full-document loading where lazy loading is possible.
- Add favorites in the viewer: pressing `F` should toggle favorite state, show a soft heart animation, and sync with 자체파인더/sidebar/future tag state.
- Add a quiet Viewooa preference to make Viewooa the default image app through public macOS default-app mechanisms where feasible.
- Move the top-left image count notice so it is never hidden by native window buttons.
- Refine the Info panel animation so it enters/exits more smoothly; evaluate removing or reducing its background.
- Add customizable number-key actions, such as moving the current image to a configured folder or applying a configured tag.
- Make pinch-in / pinch-out detection more forgiving without confusing scroll/navigation gestures.
- Make double-click detection more forgiving of small pointer movement.
- Add viewer top-right Share and Favorite controls.
- Add a mobile-gallery-like thumbnail scrubber above the bottom viewer control bar, with smooth drag-to-scrub navigation.
- Add Set as Wallpaper through the Share flow, with an intuitive monitor preview.
- Verify zoom-out-below-fit policy: images whose actual size is larger than fit should be allowed to zoom below fit within the agreed lower bound.
- Keep GIF controls polished: lower-left frame counter, previous frame, play/pause, next frame, and bottom-viewer-control-bar-matched height.
- Add Home / End navigation to jump to the first / last image in the current folder.
- Decide and document image rendering strategy, including display-resolution image loading versus full-resolution loading.
- Decide whether RAW needs an explicit 100% high-resolution decode mode.
- Continue viewer control-bar readability and hit-area polish, especially over bright images.

### Better Finder

- Move 자체파인더 toward Finder-class behavior: show all files, browse folders, use the user's macOS default app for normal Open, expose a system-like Open With flow, include Viewooa as an ordinary compatible photo app for supported image types, and delegate system-owned behavior to macOS.
- Fix current Better Finder issues tracked in `KNOWN_ISSUES.md`, prioritizing observed interaction and layout regressions before broader Finder-class parity work.
- Let the user choose whether Open uses the native macOS file picker or 자체파인더; keep 자체파인더 independently usable as a standalone app.
- Add Finder-like right-click menus using public system integrations first: Open, Open With, Move to Trash, Get Info, Rename, Compress, Duplicate, Make Alias, Quick Look, Copy, Share, tag colors, Tags, Quick Actions, and third-party service actions where feasible.
- Add Finder-like previous/next folder navigation, including mouse side-button mapping.
- Match Finder package/app bundle behavior: `.app` and package documents appear as package items, normal Open delegates to macOS, and Show Package Contents reveals internals only when explicitly chosen.
- Add full selection workflows shared by 자체파인더 and single-photo contexts: multi-select, bulk delete/move, new folder, and clear recovery/undo behavior without nagging confirmations for direct recoverable actions.
- Add app-native global and local tags: window toolbar/menu tag controls, tags visible in Info, folder-scoped tags, global pinned tags, and filtering by tag in 자체파인더.
- Keep macOS Finder/system tags as an optional, clearly labeled display/write/sync layer separate from app-native tags; write/sync can come later after permissions, undo, and conflict handling are reliable. Sync conflicts should notify the user and offer explicit choices.
- Add hierarchical/foldable tags.
- Add text-file viewing support with system fonts by default and optional Font Book import for installed fonts.
- Add SD card safe eject behavior similar to Finder.
- Allow removing sidebar favorites without deleting the underlying file/folder.
- Add Finder-style folder tabs. If asked to implement all remaining Finder work, confirm whether tabs are included before starting.
- Remove open/save-dialog-style Cancel and Open buttons from 자체파인더.
- Make the path bar Finder-like: include the selected file as the final segment and show the correct system icon for each path segment.
- Fix 자체파인더 thumbnail size stepping: window size should not make `-` / `+` disable early, and each step should create a meaningful visible size/layout change.
- Align icon view to Finder-like top-left layout with native-feeling spacing and stable scroll position.
- Strengthen 자체파인더 selection and focus states.
- Add Finder-like keyboard navigation: arrows, Return/Cmd-Down open, Cmd-F search, type-to-select, and Space for Quick Look.
- Add Windows-style file cut/paste: `Cmd+X` cuts selected files and `Cmd+V` moves/pastes them, instead of relying on Finder's `Cmd+Option+V` move-on-paste flow.
- Add Quick Look integration through macOS system APIs.
- Add video/audio hover preview with one active inline playback at a time.

### Organization, AI, And Editing

- Add cutout/background-removal workflow similar to Preview but more convenient: user activates cutout, clicks the target object, and gets higher-quality selection behavior.
- Add AI file operations only after a preview/undo-capable command model exists.
- Keep new user-facing actions command-addressable as they are built so command palette, App Intents, and MCP can expose the same safe capabilities later without parallel hidden behavior.
- Keep future favorites, tags, ratings, and selection state synchronized through `SharedMetadataKit`, using SQLite as the canonical shared metadata store rather than direct Viewooa-자체파인더 coupling.
- Keep Viewooa and 자체파인더 as independently launchable ecosystem apps: useful alone, better together through bridge/shared metadata synchronization.
- Ensure either app distribution includes the shared bridge/metadata capability; users should not have to install a separate visible manager app.
- Treat shared metadata as durable user data: add atomic/journaled writes, migration backups, corruption detection, detailed user-confirmed restore, and recovery/import/export before relying on it for favorites, app-native tags, or ratings.
- Add layered file identity before metadata becomes user-critical: app-owned `file_id`, path/resource-id/volume/bookmark/package observations, offline/unresolved states, and user-confirmed relink when confidence is low.
- Add `FileAccessManager` distribution adapters so App Store sandbox/security-scoped access and direct/GitHub permission behavior stay behind one interface.

## Done

- Viewooa and 자체파인더 split into independently releasable feature areas with bridge-owned coordination.
- 자체파인더 direction documented in `DESIGN.md` and `IMPLEMENTATION_MAP.md`.
- GIF file-size loading policy: GIF files up to 100 MB can load.
- GIF frame controls: previous frame, play/pause, and next frame controls are present and wired.
- PDF visibility in 자체파인더: PDFs can appear there.
- PDF lazy page rendering added to reduce up-front memory pressure.
- Viewer control-bar contrast improved for bright images.
- Bottom viewer control-bar separators limited to Open and Pin section boundaries.
- Bottom viewer control-bar pin visibility improved.
- OpenBrowser lazy scroll reveal animation fixed so lazy cells do not fall in from the top while scrolling.
- RAW thumbnail/preload safeguards added: RAW preview/preload paths use bounded thumbnail loading rather than always loading full-resolution images.
- 1x magnifier direction adopted in place of the old 100% magnifier wording/icon concept.
- View menu checkmark alignment and selected-only check behavior fixed.
- Navigation count notice appears on normal navigation, not only long-press navigation.
- 자체파인더 multi-selection supports Shift range selection and modifier-based multi-select.
- 자체파인더 sidebar hide/show exists.
- Double-click zoom uses the clicked image coordinate path.
- Fast repeated double-click handling is covered by click-count logic and tests.
- Internal 자체파인더 trigger from zooming out below fit removed.
- 1x zoom repair context-menu option removed.

## Needs Verification

- RAW stability in very large folders still needs real-world stress testing despite existing thumbnail/preload safeguards.
- 자체파인더 stress testing should start with external disks and package/app bundle behavior.
- Viewer zoom lower-bound policy needs verification across small images, large images, vertical images, rotated images, GIFs, and PDFs.
- Zoom percentage display should be verified against the effective scale shown during zoom.
- Double-click tolerance and pinch tolerance need hands-on tuning after implementation changes.
- Viewer count notice placement should be rechecked in windowed, maximized, and fullscreen modes.

## Deferred

- Smooth zoom animation can be revisited later; current priority is correctness and stability.
- Advanced post-processing controls beyond current safe options.
- Batch rename preview.
- Command palette, App Intents, and MCP integration.
- Advanced folder/media preview modes beyond current thumbnail behavior.

## Cancelled Or Replaced

- Zoom-out from fit opens 자체파인더.
- Touchpad drag gallery transition animation as a custom side-by-side image strip.
- 1x zoom repair user-facing post-processing option.
- Cursor hiding and forced cursor restoration during drag; the later direction was to avoid cursor hiding because it caused delay/interaction problems.

## Reminders

- If asked to implement all remaining Finder work, confirm whether Finder-style tabs are included before starting.
- 자체파인더 being Finder-class does not mean manually reimplement every macOS behavior. Delegate system-owned behavior, such as default-app Open, Open With app choice, DMG opening, unrelated document opening, Quick Look, and service/Quick Action integration, to macOS where possible.
- Do not add prominent 자체파인더-only "Open in Viewooa" controls by default. Viewooa should behave like a normal photo app available through Open With or through the user's default-app choice.
- For packages and app bundles, match Finder: package item by default, system Open behavior, Show Package Contents for explicit inspection.
- Treat `자체파인더` as a temporary working label until final public naming is chosen.
- Distribution permissions need channel-specific verification: Mac App Store builds should assume sandbox/security-scoped access constraints, while GitHub releases may allow a different notarized permission model.
- In App Store/sandboxed builds, show discoverable inaccessible items as disabled with a clear permission explanation instead of hiding them.
- First-run permission onboarding should be soft and non-alarmist, with a one-click path to request broad locations such as Macintosh HD or external disks where possible.
- Heavy 자체파인더 features must remain lazy, cached, concurrency-limited, and cancelable.
- File mutation features must be system-backed, undoable/recoverable, or explicit preview/undo-capable command paths. Direct user-initiated recoverable actions should execute like Finder without repeated confirmations; risky, irreversible, AI/automation, metadata restore, ambiguous broad, or unclear-undo operations require preview/confirmation.
- Keep Viewooa and 자체파인더 independently releasable; shared behavior should go through bridge/shared-state boundaries.
