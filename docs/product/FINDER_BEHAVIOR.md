# FINDER_BEHAVIOR.md

> Better Finder behavior specification. Read `DESIGN.md` first.

## Core Direction

Better Finder is a Finder-class browser, not an image picker and not a modal open/save panel.

- Show all files.
- Browse folders like Finder.
- Delegate system-owned behavior to macOS where possible.
- Improve Finder only where the improvement is clear, familiar, and useful.
- Do not add prominent Better-Finder-only `Open in Viewooa` controls by default.

## Open Behavior

- Normal Open follows the user's macOS default app choice.
- Open With exposes compatible apps through system-like behavior.
- Viewooa appears as an ordinary compatible photo app for supported images.
- If the user makes Viewooa the default image app, normal Open follows that default.
- Unsupported files remain visible and use macOS system handling.

## Context Menus

Aim to mirror Finder's core context menu shape where public APIs and safety allow:

- Open
- Open With
- Move to Trash
- Get Info
- Rename
- Compress
- Duplicate
- Make Alias
- Quick Look
- Copy
- Share
- tag colors / Tags
- Show Package Contents for packages and app bundles
- Quick Actions
- third-party service actions where macOS exposes safe integration points

## Path Bar

- The bottom path bar should be Finder-like, not open/save-dialog-like.
- Do not show open/save-dialog Cancel or Open buttons in Better Finder.
- If a folder is selected, show the path through that folder.
- If a file is selected, include the selected file as the final segment.
- Each path segment should include the correct system icon for the volume, folder, package, or file.

## Packages And App Bundles

- Treat `.app` bundles and package documents as package items by default.
- Normal Open delegates to macOS, such as launching an app bundle.
- Internals remain hidden unless the user chooses Show Package Contents.
- When browsing package contents explicitly, attach metadata to internal files only if the user is intentionally browsing internals.

## Direct File Operations

Direct user-initiated recoverable actions should execute without repeated confirmations:

- Move to Trash
- move
- rename
- cut
- paste
- duplicate
- alias
- compress
- tag changes

Safety should come from Undo, Trash, recoverability, and clear state. Confirmation/preview is for irreversible actions, metadata restore, automation/AI, ambiguous broad commands, risky batch transformations, or unclear-undo operations.

## Keyboard Improvements

- Keep Finder-like navigation: arrows, Return/Cmd-Down open, Cmd-F search, type-to-select, Space for Quick Look.
- Improve cut/paste semantics over Finder:
  - `Cmd+X` cuts selected files for move.
  - `Cmd+V` moves/pastes cut files or pastes copied files.
  - Do not require Finder's `Cmd+Option+V` move-on-paste flow for the main cut/paste path.

## Tabs

Finder-style tabs are planned, but when asked to implement all remaining Finder work, confirm whether tabs are included before starting.
