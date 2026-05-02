# DESIGN.md

> Product constitution for Viewooa and Better Finder. Keep this file short and high-signal. Detailed specs live in the linked product docs.

---

## Read Order

1. `DESIGN.md` for product constitution and non-negotiable principles.
2. `IMPLEMENTATION_MAP.md` for architecture ownership and code boundaries.
3. `ROADMAP.md` for active/deferred/done/cancelled status.
4. Topic docs below when the task touches that area.

Topic docs:
- `UX_SPEC.md`: UX topic index that routes to focused detailed UX docs.
- `FINDER_BEHAVIOR.md`: Better Finder behavior, Open/Open With, path bar, package handling, direct file operations, keyboard improvements, and Finder-like UX.
- `KNOWN_ISSUES.md`: concrete observed bugs and regressions that should be fixed or reclassified.
- `METADATA_ARCHITECTURE.md`: `SharedMetadataKit`, SQLite store, file identity, backups, recovery, Finder tag sync, and durability rules.
- `DISTRIBUTION_AND_PERMISSIONS.md`: App Store/direct builds, sandboxing, `FileAccessManager`, Macintosh HD/external disk permission UX, and inaccessible item handling.
- `DECISIONS.md`: dated decision log and open questions.

---

## Product Identity

Working names:
- `Viewooa`: the photo viewer experience and app name.
- `Better Finder`: current working name for the Finder-class file browser / custom Finder app; final app name is TBD.
- `자체파인더`: internal Korean shorthand used in existing notes for Better Finder.

One-line concept:
A calm, fast, native macOS photo viewer and Finder-class browser pair that makes browsing, previewing, organizing, and AI-assisted file operations feel effortless.

Product promise:
The apps should feel like they belong on macOS: familiar at first glance, quiet during normal use, powerful when needed, and respectful of the user's files.

App relationship:
Viewooa and Better Finder are independently launchable apps in one ecosystem. Each app must remain useful on its own, while shared state such as favorites, app-native tags, ratings, and future AI command context synchronizes through `SharedMetadataKit` / bridge-owned shared metadata boundaries. Installing either app should include the shared metadata capability without exposing a separate manager app.

Do not use `Viewooa` to mean Better Finder.

---

## Product Principles

### Native First
Use system conventions before inventing custom ones. Prefer SwiftUI/AppKit-native controls where they provide expected macOS behavior. Respect system appearance, window behavior, menus, keyboard shortcuts, drag and drop, context menus, undo, accessibility, and platform privacy/security expectations.

Design test:
> If a Mac user can guess how to use it without a tutorial, the design is probably correct.

### Content First
The user's files are the hero. UI chrome should support the content, not compete with it. File thumbnails, names, metadata, and preview states should dominate the interface.

Design test:
> In screenshot form, the user should notice their files before noticing the app interface.

### Finder First, Selective Improvements
Better Finder should feel like Finder where Finder works well, then improve workflows where the project has a clear reason to be better.

Rules:
- Follow Finder and macOS interaction patterns for navigation, opening, context menus, selection, drag and drop, sharing, tags, Quick Look, and system-owned file behavior.
- Do not reimplement built-in Finder/macOS behavior just to own it. Use public system mechanisms first.
- Keep improvements incremental and familiar.
- Keep Viewooa quiet and ordinary as a photo app. Better Finder should surface it through Open With/default-app behavior, not a prominent custom launch path.
- Better Finder is not a modal file picker. It must not show open/save-dialog Cancel/Open buttons.

Design test:
> If a user already knows Finder, Better Finder should feel obvious first and better second.

### Trust And Reversibility
File management is high-stakes. The app must make risky operations legible and reversible without nagging users for direct recoverable Finder-like actions.

Rules:
- Direct user-initiated recoverable actions execute without repeated confirmation, including Move to Trash, move, rename, cut, paste, duplicate, alias, compress, and tag changes.
- Use Undo for rename, move, tag, delete, and batch operations whenever technically possible.
- Prefer Trash over permanent deletion.
- Confirmations/previews are for irreversible actions, metadata restore, automation/AI mutations, ambiguous broad commands, risky batch transformations, or operations where undo/recovery is unavailable or unclear.
- Never silently overwrite, move, delete, restore, or replace shared metadata.
- Automatic metadata backup is allowed; automatic metadata recovery is not.
- Metadata recovery must show candidate versions and require explicit final confirmation before replacing active metadata.

Design test:
> A user should feel safe experimenting because recovery is obvious.

### Calm Intelligence
AI should behave like a precise assistant, not a noisy chatbot bolted onto the UI.

Rules:
- AI features should be contextual: selected files, current folder, visible results, or explicit user command.
- AI file mutations require user-visible preview and must use the same command layer as the UI.
- AI cannot access files the app cannot access, escalate permissions, permanently delete files, or run shell commands unless a developer mode explicitly enables it.
- App Intents and MCP should be considered while features are implemented so actions, selections, permissions, previews, and undo paths are naturally addressable later.

Design test:
> AI should make the app easier to use, not harder to trust.

---

## Non-Negotiable Product Decisions

### Viewooa
- Viewooa is the photo viewer, not the Finder-class browser.
- Viewooa should feel like a normal, quiet macOS photo app.
- Better Finder reaches Viewooa through Open With/default-app behavior for supported images.
- A quiet preference may let users make Viewooa the default image app through public macOS mechanisms where feasible.

### Better Finder
- Better Finder is the working name for the Finder-class browser; final name is TBD.
- It should show all files, not just supported media.
- Normal Open follows the user's macOS default app choice.
- Open With exposes compatible apps through system-like behavior.
- Packages and app bundles follow Finder semantics: package item by default, system Open behavior, Show Package Contents for explicit inspection.
- The path bar is Finder-like: include the selected file as the final segment and show the correct system icon for each path segment.
- Use Windows-style file cut/paste improvement: `Cmd+X` cuts selected files and `Cmd+V` moves/pastes them.

### Metadata
- `SharedMetadataKit` owns shared ecosystem metadata.
- SQLite is the canonical metadata store.
- Prefer a shared App Group container; use adapter/fallback storage only when App Group sharing is unavailable.
- Do not use UserDefaults, plist, raw JSON, Finder/system tags, or per-app Core Data/SwiftData stores as the source of truth.
- Use app-owned stable `file_id` values and layered observations instead of path-only identity.
- Treat metadata as durable user data: atomic/journaled writes, migrations, backups, corruption detection, explicit recovery, import/export.
- Finder/system tag display/write/sync is optional and clearly separate from app-native tags. Conflicts must be shown to the user with explicit choices.

### Distribution And Permissions
- Use one codebase and one product model.
- Hide App Store/direct differences behind `FileAccessManager` and metadata location providers.
- App Store/sandboxed builds should assume security-scoped access constraints.
- Direct/GitHub builds may use a more flexible notarized permission model.
- First-run permission onboarding should be soft and clearly branded as this app, not a fake system dialog.
- Macintosh HD/external disk permission should be requestable through a clear one-click path where possible.
- Show discoverable inaccessible items as disabled with a clear explanation instead of hiding them.
- Mixed App Store/direct automatic sharing can be deferred; if not authorized, use explicit import/export or migration UI and never silently bridge stores.

---

## Implementation Checks

Before implementing product behavior, confirm:
- Is this active in `ROADMAP.md`, and not Cancelled/Replaced?
- Which product area owns this in `IMPLEMENTATION_MAP.md`?
- Does it preserve Viewooa and Better Finder as independently launchable apps?
- Does it preserve Finder-like direct action behavior without needless confirmation?
- Does any file mutation have undo/recovery or a required preview/confirmation path?
- Does any metadata operation preserve durability and explicit recovery rules?
- Does any AI/App Intents/MCP behavior use the same command, permission, preview, and undo model as UI actions?

---

## Historical Detail

This file intentionally stays short. For detailed rules, see:
- `UX_SPEC.md`
- `FINDER_BEHAVIOR.md`
- `KNOWN_ISSUES.md`
- `METADATA_ARCHITECTURE.md`
- `DISTRIBUTION_AND_PERMISSIONS.md`
- `DECISIONS.md`
