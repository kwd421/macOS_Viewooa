# KNOWN_ISSUES.md

> Current known product and implementation issues. Read `DESIGN.md`, `ROADMAP.md`, and the relevant topic doc before fixing.

This file is for concrete observed problems, not broad product direction. Keep it current as issues are fixed, moved to roadmap work, or replaced by a better diagnosis.

## Viewooa Photo Viewer

### Active Bugs And Polish Issues

1. Image count notice can conflict with native window buttons
   - The top-left image count notice can be hidden by or visually collide with native macOS window controls.
   - Expected behavior: the count should remain readable in windowed, maximized, and fullscreen modes.

2. Info panel animation and background need refinement
   - The Info panel enter/exit animation does not yet feel smooth enough.
   - Expected behavior: the panel should move naturally and its background should not feel heavier than needed.

3. Pinch detection is too strict
   - Pinch-in / pinch-out detection needs to be more forgiving.
   - Expected behavior: pinch gestures should feel responsive without being confused with scroll/navigation gestures.

4. Double-click detection is too strict
   - Double-click can fail when there is small pointer movement.
   - Expected behavior: normal human double-click movement should still count as a double-click.

5. Viewer control-bar readability and hit areas still need polish
   - Viewer controls can still need readability and target-size polish, especially over bright images.
   - Expected behavior: controls should remain readable and easy to hit regardless of image brightness.

### Needs Verification

1. RAW stability in very large folders
   - Existing thumbnail/preload safeguards need real-world stress testing.

2. Viewer zoom lower-bound policy
   - Verify behavior across small images, large images, vertical images, rotated images, GIFs, and PDFs.

3. Zoom percentage display
   - Verify the displayed percentage against the effective rendered scale.

4. Double-click and pinch tolerance tuning
   - Recheck gesture tolerance after related implementation changes.

5. Viewer count notice placement
   - Recheck placement in windowed, maximized, and fullscreen modes.

## Better Finder

### Active Bugs

1. Initial scroll jump
   - When Better Finder first opens, the scroll area visibly jumps or flickers.
   - Expected behavior: the initial layout should settle without visible scroll-position or scrollbar snapping.

2. Drag origin after scrolling
   - After scrolling down, drag selection does not start from the current mouse position.
   - Expected behavior: the drag origin should match the pointer location in the visible content coordinate space, even after scrolling.

3. Command-drag selection toggling
   - When multiple files are already selected, Command-drag over unselected files should add those files to the existing selection.
   - When multiple files are already selected, Command-drag over selected files should remove those files from the selection.
   - Expected behavior: this should feel like Finder-style additive/subtractive selection, not replace or misalign the existing selection.

4. Top toolbar readability
   - The top toolbar currently lacks enough Finder-like material/opacity, making it hard to read against content.
   - Expected behavior: the toolbar should use a native-feeling opaque/translucent background treatment similar to Finder so controls remain readable.

5. Scroll containment below the top toolbar
   - Scrolled content currently appears to intrude into or under the top toolbar area.
   - Expected behavior: match Finder's visual containment, where scrolling content does not visually invade the top bar.

6. Thumbnail size stepping disables too early
   - Window size can make the `-` / `+` thumbnail controls disable before the true min/max size is reached.
   - Expected behavior: controls should disable only at real min/max, and every step should create a meaningful visible size/layout change.

7. Icon view layout and scroll position need Finder-like stability
   - Icon view still needs Finder-like top-left alignment, native-feeling spacing, and stable scroll position.
   - Expected behavior: resizing or refreshing should not make the grid feel jumpy or visually reflow in surprising ways.

8. Selection and focus states are not strong enough
   - Better Finder selection and focus states still need refinement.
   - Expected behavior: selected files, focused files, and active keyboard target should be obvious without visual noise.

9. Open/save-dialog buttons are still a product bug if present
   - Better Finder must not show open/save-dialog-style Cancel or Open buttons.
   - Expected behavior: it should feel like Finder, with a Finder-like path bar instead of modal picker controls.

10. Path bar is incomplete if it stops at the folder
   - The path bar must include the selected file as the final segment and show the correct system icon for each segment.
   - Expected behavior: match Finder-style selected-item path context.

### Needs Verification

1. External disk stress testing
   - Stress testing should cover external disks, offline/reconnected volumes, and large folders.

2. Package and app bundle behavior
   - Verify `.app` bundles and packages appear as package items by default, open through macOS, and reveal contents only through explicit Show Package Contents.

3. Finder-class context menu coverage
   - Verify how far public macOS integrations can support Open, Open With, Move to Trash, Get Info, Rename, Compress, Duplicate, Make Alias, Quick Look, Copy, Share, tag colors, Tags, Quick Actions, and third-party services.

4. App Store sandbox inaccessible-item UI
   - Verify that discoverable inaccessible files/folders appear disabled with a clear explanation instead of being silently hidden.

5. Heavy-folder performance
   - Verify that large folders remain lazy, cached, concurrency-limited, and cancelable.

## Shared Metadata And Permissions

### Design Risks To Track As Issues

1. Shared metadata durability is not yet proven
   - Favorites, tags, ratings, backups, recovery, import/export, and migrations must not become user-critical until SQLite-backed durability and recovery flows are in place.

2. Metadata restore must never be silent
   - Automatic backups are allowed, but restore must require explicit user choice with detailed comparison and final confirmation.

3. File identity and relinking need implementation before metadata is trusted
   - The app needs app-owned `file_id`, path/resource-id/volume/bookmark/package observations, offline/unresolved states, and user-confirmed relink when confidence is low.

4. File access behavior needs distribution adapters
   - App Store sandbox/security-scoped access and direct/GitHub permission behavior must stay behind `FileAccessManager`-style adapters.

5. Finder tag sync must not silently overwrite user metadata
   - macOS Finder/system tag write/sync needs explicit mode, conflict detection, user choice, and undo before it becomes active.
