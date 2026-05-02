# DESIGN.md

> Product design specification for a native macOS file browser / photo-oriented Finder alternative.  
> This document is the project constitution: implementation should follow it unless a later design decision explicitly updates this file.

---

## 1. Product Identity

### Working Name
`Viewooa`

### One-line Concept
A calm, fast, native macOS file browser that makes browsing, previewing, organizing, and AI-assisted file operations feel effortless.

### Product Promise
The app should feel like it belongs on macOS: familiar at first glance, quiet during normal use, powerful when needed, and respectful of the user’s files.

### Target User
- Mac users who browse many images, folders, references, downloads, project files, or assets.
- Users who find Finder too limited for visual browsing and contextual preview.
- Users who want both human-friendly and AI-friendly file operations.

---

## 2. Apple-inspired Design Philosophy

This app follows Apple platform design values without copying Apple branding or imitating system apps blindly.

### 2.1 Native First
Use system conventions before inventing custom ones.

Rules:
- Prefer SwiftUI / AppKit-native controls where they provide expected macOS behavior.
- Respect system appearance: Light, Dark, increased contrast, reduce motion, accent color, vibrancy, and dynamic type where relevant.
- Use macOS-standard window behavior, menus, keyboard shortcuts, drag and drop, context menus, and undo.

Design test:
> If a Mac user can guess how to use it without a tutorial, the design is probably correct.

### 2.2 Content First
The user’s files are the hero. UI chrome should support the content, not compete with it.

Rules:
- Avoid heavy borders, loud colors, unnecessary panels, and persistent decorative UI.
- File thumbnails, names, metadata, and preview states should be visually dominant.
- Controls should appear when useful and stay quiet when not needed.

Design test:
> In screenshot form, the user should notice their files before noticing the app interface.

### 2.3 Clarity Over Decoration
Every visible element must explain either location, selection, action, state, or consequence.

Rules:
- Use plain labels for destructive or file-moving operations.
- Do not hide dangerous actions behind ambiguous icons.
- Prefer concise text plus familiar symbols over custom visual metaphors.
- Empty states should explain what happened and offer the next useful action.

Design test:
> A user should never wonder, “What just happened to my file?”

### 2.4 Progressive Power
Basic browsing should be simple. Advanced control should be discoverable, not forced.

Rules:
- Keep the default toolbar minimal.
- Put advanced sorting, filtering, batch actions, and AI commands behind menus, inspectors, command palette, or contextual controls.
- Do not overload the first-run interface.

Design test:
> A beginner can browse immediately; an expert can work quickly after learning shortcuts.

### 2.5 Trust and Reversibility
File management is high-stakes. The app must make risky operations legible and reversible.

Rules:
- Use Undo for rename, move, tag, delete, and batch operations whenever technically possible.
- Prefer Trash over permanent deletion.
- Require stronger confirmation for irreversible operations.
- Show progress and completion states for long-running operations.
- Never silently overwrite, move, or delete files.

Design test:
> A user should feel safe experimenting because recovery is obvious.

### 2.6 Calm Intelligence
AI should behave like a precise assistant, not a noisy chatbot bolted onto the UI.

Rules:
- AI features should be contextual: selected files, current folder, visible results, or explicit user command.
- AI must ask before changing files unless the command is clearly reversible and user-initiated.
- AI actions should expose what they will do before execution.
- AI should use the same file-operation layer as the UI, not a hidden parallel path.

Design test:
> AI should make the app easier to use, not harder to trust.

---

## 3. Core Experience Goals

### 3.1 Browse
Users can move through folders quickly with clear orientation.

Requirements:
- Sidebar for top-level locations, favorites, tags, smart collections, and recent places.
- Main content area supports grid, list, column, and gallery-like browsing modes.
- Breadcrumb or path control always makes the current location understandable.
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
- Tags and favorites are visible but not visually noisy.

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
│ Toolbar: Back / Forward | Path | Search | View | Actions     │
├──────────────┬───────────────────────────────┬───────────────┤
│ Sidebar      │ Content Browser               │ Preview /     │
│              │ Grid / List / Gallery         │ Inspector     │
│              │                               │               │
└──────────────┴───────────────────────────────┴───────────────┘
```

Principles:
- Sidebar = where am I?
- Content browser = what is here?
- Preview / inspector = what is selected?
- Toolbar = what can I do now?

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

### 4.3 Content Browser

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

### 4.5 Toolbar

Default toolbar items:
- Back / Forward
- Current path or title
- Search
- View switcher
- Sort / Filter
- Share / Actions
- Toggle inspector

Rules:
- Toolbar controls must be grouped by purpose.
- Avoid placing every command in the toolbar.
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
- Menu command names should match toolbar/context menu labels.

---

## 5. Visual Design System

### 5.1 Tone
The visual tone should be:
- Calm
- Precise
- Lightweight
- Native
- Slightly warm, but not playful to the point of reducing trust

Avoid:
- Heavy skeuomorphism
- Neon dashboards
- Overly rounded mobile-style UI
- Excessive glass effects
- Visual noise around thumbnails

### 5.2 Color
Rules:
- Use system colors by default.
- Respect user accent color.
- Use color to communicate selection, status, tags, and destructive warnings.
- Do not use saturated brand color across large surfaces.

Semantic color usage:
- Accent: selection, primary actions, focus
- Red: destructive or failed state only
- Yellow / orange: warning or needs review
- Green: success or confirmed safe action
- Blue / purple: optional smart or AI-related affordances, used sparingly

### 5.3 Typography
Rules:
- Use system font.
- Prioritize legibility over personality.
- File names need stable, readable sizing.
- Metadata should be secondary, not tiny.

Suggested hierarchy:
- Window / folder title: title or headline scale
- File name: body / callout scale
- Metadata: caption / footnote scale
- Empty state title: headline scale
- Empty state explanation: body scale

### 5.4 Spacing
Rules:
- Use consistent spacing tokens.
- Dense modes are allowed, but the default should breathe.
- Grid cells should preserve thumbnail clarity first, text second.
- Inspector content should use grouped sections.

Suggested spacing tokens:
- `4px`: tight icon/text pairing
- `8px`: standard internal spacing
- `12px`: compact group spacing
- `16px`: standard panel padding
- `24px`: large section separation

### 5.5 Iconography
Rules:
- Prefer SF Symbols when possible.
- Icons must support the label, not replace it for risky actions.
- Custom icons should match SF Symbol weight and optical size.
- App icon should read clearly at small sizes and avoid overly complex detail.

### 5.6 Motion
Motion should explain state change, not decorate it.

Allowed motion:
- Sidebar/inspector reveal
- Selection transitions
- Thumbnail loading fade
- Drag destination feedback
- Preview zoom

Rules:
- Respect Reduce Motion.
- Avoid bouncy or playful motion in file operations.
- Long operations need progress indicators, not vague animation.

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
2. Preview
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
- Destructive commands require confirmation.
- Command palette should not replace the menu bar; it complements it.

---

## 7. AI and Automation Design

### 7.1 AI Principle
AI is an interface to existing app capabilities, not a separate hidden system.

All AI actions must map to explicit internal commands.

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

## 9. Performance Design

### 9.1 Perceived Performance
The app should feel fast even when processing large folders.

Rules:
- Show partial results quickly.
- Load thumbnails progressively.
- Keep scrolling smooth.
- Avoid blocking the main thread.
- Cache previews and metadata carefully.

### 9.2 Large Folder Behavior
Requirements:
- Browsing 10,000+ items should remain usable.
- Sorting and filtering should show progress when expensive.
- Search results should appear incrementally if possible.
- Image folders should not freeze while thumbnails generate.

### 9.3 Startup
Startup should prioritize showing the last useful state quickly.

Rules:
- Restore last window state.
- Defer expensive indexing.
- Avoid modal setup flows on launch.

---

## 10. Accessibility

Requirements:
- Full keyboard navigation.
- VoiceOver labels for toolbar items, thumbnails, previews, and inspector fields.
- Respect Reduce Motion.
- Respect Increase Contrast.
- Do not rely on color alone for tags or status.
- Hit targets must remain usable in compact layouts.
- Text should remain legible in both Light and Dark appearance.

Accessibility design test:
> The app must remain understandable without thumbnails, without color, and without a mouse.

---

## 11. Onboarding

Principle:
Do not explain everything. Reveal only what helps the user begin.

First-run experience:
- Ask for folder access only when needed.
- Explain why access is needed in plain language.
- Offer example locations: Pictures, Downloads, Desktop, custom folder.
- Do not force account creation.
- Do not force AI setup.

Empty states:
- No folder selected: explain how to add a location.
- Empty folder: show that the folder is empty, not that the app failed.
- No search results: suggest changing scope or filters.
- AI unavailable: explain setup requirement without blocking normal browsing.

---

## 12. Non-goals

This app is not:
- A full replacement for every Finder feature on day one.
- A terminal or shell automation tool.
- A cloud storage provider.
- A photo editor.
- A DAM system with every enterprise asset-management feature.
- A chatbot-first file manager.

The app may grow into some of these areas later, but the initial identity is:
> Native, visual, safe, fast file browsing for macOS.

---

## 13. Implementation Guardrails

Before adding a feature, answer:
1. Does this make browsing, previewing, organizing, searching, or AI assistance better?
2. Does it feel native on macOS?
3. Is it reversible or clearly safe?
4. Does it respect user files and permissions?
5. Can it be discovered through menu, shortcut, context menu, or command palette?
6. Does it still work without AI?
7. Does it still work with keyboard-only interaction?

Reject or redesign the feature if the answer is “no” to more than one of these.

---

## 14. UI Quality Checklist

Use this checklist before shipping a screen.

### Layout
- [ ] Current location is obvious.
- [ ] Selection state is obvious.
- [ ] Main content has priority over chrome.
- [ ] Sidebar, content, and inspector have clear roles.
- [ ] Empty states are helpful.

### macOS Fit
- [ ] Menu bar commands exist for major actions.
- [ ] Keyboard shortcuts are present and shown in menus.
- [ ] Drag and drop behaves predictably.
- [ ] Context menus are selection-aware.
- [ ] Window resizing does not break layout.

### Safety
- [ ] Risky actions show consequences.
- [ ] Batch operations have preview.
- [ ] Undo exists where feasible.
- [ ] Errors are specific.
- [ ] AI cannot silently mutate files.

### Visual
- [ ] Uses system colors where possible.
- [ ] Works in Light and Dark appearance.
- [ ] Icons match system weight.
- [ ] Text is readable.
- [ ] Motion is purposeful and respects settings.

### Performance
- [ ] Large folders do not freeze the UI.
- [ ] Thumbnails load progressively.
- [ ] Search/filter feedback appears quickly.
- [ ] Long operations show progress.

---

## 15. Initial Feature Priority

### P0: Core Native Browser
- Folder access
- Sidebar locations
- Grid and list view
- Preview pane
- Basic metadata inspector
- Open, rename, move to Trash
- Search current folder
- Keyboard navigation

### P1: Visual Workflow
- Gallery mode
- Better image metadata
- Tags and favorites
- Batch rename preview
- Sort and filter controls
- Thumbnail cache

### P2: AI-friendly Workflow
- Command palette
- App Intents
- MCP server
- Folder summarization
- AI rename proposal
- AI duplicate/similarity review proposal

### P3: Advanced Power
- Smart collections
- Saved searches
- Visual similarity grouping
- Custom metadata notes
- Multi-window workflows

---

## 16. Definition of “Apple-like” for This Project

“Apple-like” does not mean glass everywhere, copied icons, or pretending to be Finder.

For this project, “Apple-like” means:
- The interface feels inevitable.
- The user knows where they are.
- The content is more important than the controls.
- The app uses platform conventions respectfully.
- Risky operations are clear and reversible.
- Details are polished without becoming decorative noise.
- AI is integrated as a quiet capability, not a separate personality.

---

## 17. Design Decision Log

Use this section to record major design decisions.

### 2026-04-29 — Adopt modular viewer/browser architecture

Decision:
Viewooa is organized as three cooperating product areas: Photo Viewer, Browser, and App Bridge.

Reason:
The photo viewer must remain independently releasable, while the browser can grow toward a Finder/Photos-style file browsing experience. The bridge owns cross-feature state and command routing so favorites, selection, and future AI commands can stay synchronized without hard-coupling the viewer and browser.

Alternatives considered:
Keeping all viewer and browser state in one large app state object, or making the browser directly own viewer actions.

Trade-offs:
The bridge adds one more layer, but it prevents the viewer and browser from depending on each other's implementation details.

Follow-up:
Keep new commands routed through explicit bridge/store APIs, not ad hoc view references.

### 2026-04-29 — Treat this document as product constitution

Decision:
This document is the default design authority for new Viewooa product work.

Reason:
The project needs a stable definition of Apple-like behavior: native conventions, content-first UI, reversible file operations, and quiet AI assistance.

Alternatives considered:
Relying on per-feature notes in chat or screenshots only.

Trade-offs:
The document is intentionally broader than the current implementation, so feature work must still be scoped through smaller plans.

Follow-up:
Use `docs/product/IMPLEMENTATION_MAP.md` to translate this constitution into current code boundaries.

### 2026-05-02 — Move the browser toward Finder-class behavior

Decision:
The built-in browser should move toward a Finder-class file browser, not remain only an image/PDF picker. It should show every file in the current location. Files Viewooa can preview well, such as images, RAW files, GIFs, and PDFs, should open inside Viewooa. Other files, such as DMGs, archives, documents, apps, video, and audio, should remain visible and be opened through macOS system handling unless Viewooa later adds a dedicated viewer for that type.

Reason:
The browser looks and feels close enough to Finder that hiding unsupported files makes normal folders feel incomplete or broken. Finder-like behavior is safer and easier to understand: folders are browsed, supported media opens in Viewooa, and everything else is delegated to the system.

Alternatives considered:
Keeping the browser as a focused image/PDF picker, or showing unsupported files as disabled items. These are simpler, but they conflict with the Finder replacement direction and make Downloads-style folders feel wrong.

Trade-offs:
Finder-class behavior increases scope. It requires stronger keyboard navigation, clearer selection and focus states, system icon and thumbnail handling, Quick Look integration, and careful lazy loading. The app must avoid becoming heavy by loading only visible content, caching results, limiting concurrent work, and delegating system file behavior to macOS.

Follow-up:
Prioritize left-aligned Finder-like icon layout, meaningful thumbnail sizing, all-file visibility, system-open fallback, Quick Look on Space, media hover preview, and future Finder-style tabs. If a future task says to implement everything, explicitly confirm whether Finder-style tabs are included before starting.

### Decision Template

```md
### YYYY-MM-DD — Decision title

Decision:

Reason:

Alternatives considered:

Trade-offs:

Follow-up:
```

---

## 18. Open Questions

- What is the final product name?
- Should preview be right-side only, bottom-side optional, or detachable?
- Should column view be implemented early or delayed?
- Should AI features be local-only first, cloud-model optional, or both?
- Should the app support editing metadata directly or only through tags/notes?
- Which Finder-class features should ship in v1 versus later, especially tabs, Quick Look, media hover playback, and all-file operations?
