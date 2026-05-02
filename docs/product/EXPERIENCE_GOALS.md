# EXPERIENCE_GOALS.md

> Core experience goals and app structure for Viewooa and Better Finder. Read `DESIGN.md` and `UX_SPEC.md` first.

---

## 3. Core Experience Goals

### 3.1 Browse
Users can move through folders quickly with clear orientation.

Requirements:
- Sidebar for top-level locations, favorites, tags, smart collections, and recent places.
- Main content area supports grid, list, column, and gallery-like browsing modes.
- Finder-style path control always makes the current location or selected item understandable.
- When a file is selected, the path bar should include the selected file as the final segment, not stop at the containing folder.
- Each path segment should include the appropriate system icon for the volume, folder, package, or file.
- Back / forward navigation works predictably.

### 3.2 Preview
Users can inspect files without committing to opening them.

Requirements:
- Preview pane supports images first, then common documents and media where feasible.
- Preview pane must not cause layout instability when switching selection.
- Metadata appears in an inspector, not as clutter over the content.
- Spacebar preview behavior should feel familiar to Mac users.

### 3.3 Organize
Users can rename, move, tag, group, filter, and batch-edit files safely.

Requirements:
- Drag and drop should behave like macOS users expect.
- Batch operations show item count and destination/action clearly.
- Rename flow supports single and batch rename.
- App-native tags and favorites are visible but not visually noisy.
- App-native tags are the primary tagging model for the Viewooa/자체파인더 ecosystem. macOS Finder/system tags may be displayed, read, written, or synchronized as an optional, clearly labeled secondary layer where public APIs and user permissions allow, but the UI must not blur which tags are ecosystem-only and which are visible to macOS/Finder.

### 3.4 Search and Filter
Users can narrow large folders quickly.

Requirements:
- Search field is always easy to reach.
- Search scope is explicit: current folder, selected collection, or entire indexed area.
- Filters are composable: type, date, size, tag, rating, dimensions, extension.
- Search results should preserve enough path context to prevent confusion.

### 3.5 AI Assistance
Users can ask for file-related help without losing control.

Examples:
- “Find the best screenshots from this folder.”
- “Group these images by visual similarity.”
- “Rename selected files using this pattern.”
- “Summarize what is inside this project folder.”
- “Move low-quality duplicates to a review folder.”

AI requirements:
- All AI operations must have a preview step before file mutation.
- AI must explain affected file count and destination.
- AI must produce undoable operations where possible.
- AI must never bypass macOS permissions or sandboxing.

---

## 4. App Structure

### 4.1 Window Layout

Default layout:

```text
┌──────────────────────────────────────────────────────────────┐
│ Window toolbar: Back / Forward | Path | Search | View        │
├──────────────┬───────────────────────────────┬───────────────┤
│ Sidebar      │ Content Area                  │ Preview /     │
│              │ Grid / List / Gallery         │ Inspector     │
│              │                               │               │
└──────────────┴───────────────────────────────┴───────────────┘
```

Principles:
- Sidebar = where am I?
- Content area = what is here?
- Preview / inspector = what is selected?
- Window toolbar = what can I do now?

### 4.2 Sidebar

Purpose:
Top-level navigation, not a dumping ground.

Sections:
- Favorites
- Recents
- Tags
- Smart Collections
- External Volumes
- AI Collections, optional

Rules:
- Keep labels short.
- Preserve user ordering for favorites.
- Do not auto-add too many items.
- Use system-style disclosure where sections can collapse.

### 4.3 Content Area

Modes:
- Grid: best for images and visual assets.
- List: best for metadata-heavy file work.
- Columns: best for deep folder navigation.
- Gallery: best for focused visual review.

Rules:
- Selection state must be obvious.
- Thumbnail loading must be progressive and non-blocking.
- Placeholder thumbnails should be calm and consistent.
- Long file names should be readable without destroying layout.

### 4.4 Preview / Inspector

Preview pane:
- Shows visual content first.
- Avoids controls unless they are directly relevant.
- Supports zoom, fit, actual size, rotate, reveal in folder, open with.

Inspector:
- Shows metadata, dimensions, dates, tags, permissions, and AI notes.
- Editable fields must look editable.
- Read-only fields must not look interactive.

### 4.5 Window Toolbar

Definition:
A window toolbar is the command row inside an app window, such as Finder's in-window row with back/forward, view controls, actions, and search. It is not the macOS Dock and not the top system menu bar/status area.

Related bars:
- Window toolbar: the top in-window command row in Finder-like windows.
- Path bar: a Finder-like bottom location row with icon-bearing path segments. In 자체파인더 it should not include open/save-dialog buttons such as Open or Cancel.
- Viewer control bar: Viewooa's photo-viewer overlay controls for viewing actions such as zoom, rotate, previous, and next.

Default window toolbar items:
- Back / Forward
- Current path or title
- Search
- View switcher
- Sort / Filter
- Share / Actions
- Toggle inspector

Rules:
- Window toolbar controls must be grouped by purpose.
- Avoid placing every command in the window toolbar.
- In 자체파인더, do not add a special Viewooa or "Open in Viewooa" window-toolbar button by default. Viewooa should appear through Open With/default-app behavior like a normal photo app.
- Use menu bar and command palette for less frequent commands.

### 4.6 Menu Bar

The menu bar is part of the product interface, not an afterthought.

Required menus:
- File: New Window, Open, Open With, Reveal, Move to Trash, Duplicate
- Edit: Undo, Redo, Cut, Copy, Paste, Rename, Select All
- View: Grid, List, Columns, Gallery, Show Sidebar, Show Inspector, Sort By
- Go: Back, Forward, Enclosing Folder, Favorites, Recents
- Tools: Batch Rename, Duplicate Finder, AI Commands
- Window: standard macOS window commands
- Help: shortcuts, onboarding, privacy notes

Rules:
- Every major command should be discoverable from the menu bar.
- Keyboard shortcuts should appear in menu items.
- Menu command names should match window toolbar/context menu labels.

---
