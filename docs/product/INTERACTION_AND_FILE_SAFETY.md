# INTERACTION_AND_FILE_SAFETY.md

> Interaction, AI/automation, and file safety rules for Viewooa and Better Finder. Read `DESIGN.md` and `UX_SPEC.md` first.

---

## 6. Interaction Model

### 6.1 Selection
Rules:
- Single click selects.
- Double click opens.
- Space previews.
- Return renames if consistent with platform expectations.
- Command-click and Shift-click support multi-select.
- Selection count appears when multiple items are selected.
- 자체파인더 should improve file cut/paste semantics over Finder: `Cmd+X` cuts selected files and `Cmd+V` pastes/moves them, matching Windows-style cut/paste expectations rather than requiring Finder's `Cmd+Option+V` move-on-paste flow.

### 6.2 Drag and Drop
Rules:
- Drag feedback must show item count.
- Destination highlight must be clear.
- Copy vs move behavior must follow macOS modifier-key expectations.
- Dropping onto a folder should make the destination obvious.

### 6.3 Context Menus
Context menu should contain high-frequency, selection-specific actions.

Suggested order:
1. Open / Open With
2. Quick Look / Preview
3. Rename
4. Duplicate
5. Move / Copy / Tag
6. AI Actions, if relevant
7. Reveal / Show Info
8. Move to Trash

### 6.4 Keyboard Shortcuts
Required shortcuts:
- `⌘N`: New Window
- `⌘O`: Open
- `⌘F`: Search
- `⌘I`: Show Info / Inspector
- `⌘R`: Reveal or Refresh, depending on final decision
- `Space`: Preview
- `Return`: Rename
- `⌘X`: Cut selected files for move.
- `⌘V`: Paste/move cut files or paste copied files.
- `⌘Delete`: Move to Trash
- `⌘1`: Grid
- `⌘2`: List
- `⌘3`: Columns
- `⌘4`: Gallery

### 6.5 Command Palette
Purpose:
Fast access for expert users and AI-compatible command discovery.

Rules:
- Commands must be searchable by natural language and exact command name.
- Commands should show keyboard shortcuts where available.
- Irreversible, automation/AI, metadata restore, ambiguous broad, risky batch, or unclear-undo commands require confirmation. Direct recoverable Finder-like actions should execute without repeated confirmation.
- Command palette should not replace the menu bar; it complements it.

---

## 7. AI and Automation Design

### 7.1 AI Principle
AI is an interface to existing app capabilities, not a separate hidden system.

All AI actions must map to explicit internal commands. App Intents and MCP should be considered while features are implemented so actions, selections, permissions, previews, and undo paths are naturally addressable later; however, public App Intents/MCP surfaces should ship only after the safe command boundaries are explicit.

Example command shape:

```ts
type FileCommand =
  | { type: "search"; query: string; scope: FileScope }
  | { type: "preview"; fileIDs: string[] }
  | { type: "rename"; fileIDs: string[]; pattern: string; previewOnly: boolean }
  | { type: "move"; fileIDs: string[]; destination: string; previewOnly: boolean }
  | { type: "tag"; fileIDs: string[]; tags: string[]; previewOnly: boolean }
  | { type: "summarizeFolder"; folderID: string };
```

### 7.2 Permission Boundaries
Rules:
- AI cannot access files the app cannot access.
- AI cannot escalate permissions.
- AI cannot permanently delete files.
- AI cannot run shell commands unless the user explicitly enables a developer mode.
- AI file mutations require a user-visible preview.

### 7.3 App Intents
Expose safe, useful actions through App Intents where appropriate.

Candidate intents:
- Search files
- Open folder
- Open file
- Preview selected files
- Tag files
- Rename files with preview
- Summarize folder
- Create smart collection

### 7.4 MCP Interface
If MCP is supported, it should reflect the same safe command model.

MCP tools should be:
- Small
- Explicit
- Permission-aware
- Preview-first for mutation
- Easy for AI clients to inspect

Candidate MCP tools:
- `list_locations()`
- `search_files(query, scope)`
- `get_selection()`
- `preview_files(file_ids)`
- `propose_rename(file_ids, pattern)`
- `apply_rename(plan_id)`
- `propose_move(file_ids, destination)`
- `apply_move(plan_id)`
- `summarize_folder(folder_id)`

---

## 8. File Safety Rules

### 8.1 Destructive Actions
Destructive actions include:
- Move to Trash
- Permanent delete
- Overwrite
- Batch rename
- Batch move
- Metadata removal

Rules:
- Move to Trash should be undoable when possible.
- Permanent delete should not be a default visible action.
- Batch operations require preview.
- Overwrite conflicts require explicit resolution.

### 8.2 Operation Preview
Before risky batch operations, show:
- Number of affected files
- Source and destination
- Before / after file names if renaming
- Conflicts
- Skipped files
- Undo availability

### 8.3 Error Handling
Error messages should be specific and actionable.

Bad:
> Operation failed.

Good:
> 3 files could not be moved because the destination is read-only.

---
