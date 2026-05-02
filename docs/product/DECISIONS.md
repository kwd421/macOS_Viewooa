# DECISIONS.md

> Product decision log and open questions. Read `DESIGN.md` first for current product principles; use this file for historical rationale and unresolved decisions.

---

## 17. Design Decision Log

Use this section to record major design decisions.

### 2026-04-29 — Adopt modular Viewooa/자체파인더 architecture

Decision:
The project is organized as three cooperating product areas: Viewooa Photo Viewer, 자체파인더, and App Bridge.

Reason:
The photo viewer must remain independently releasable, while 자체파인더 can grow toward a Finder/Photos-style file browsing experience. The bridge owns cross-feature state and command routing so favorites, selection, and future AI commands can stay synchronized without hard-coupling Viewooa and 자체파인더.

Alternatives considered:
Keeping all Viewooa and 자체파인더 state in one large app state object, or making 자체파인더 directly own viewer actions.

Trade-offs:
The bridge adds one more layer, but it prevents Viewooa and 자체파인더 from depending on each other's implementation details.

Follow-up:
Keep new commands routed through explicit bridge/store APIs, not ad hoc view references.

### 2026-04-29 — Treat this document as product constitution

Decision:
This document is the default design authority for new project work.

Reason:
The project needs a stable definition of Apple-like behavior: native conventions, content-first UI, reversible file operations, and quiet AI assistance.

Alternatives considered:
Relying on per-feature notes in chat or screenshots only.

Trade-offs:
The document is intentionally broader than the current implementation, so feature work must still be scoped through smaller plans.

Follow-up:
Use `docs/product/IMPLEMENTATION_MAP.md` to translate this constitution into current code boundaries.

### 2026-05-02 — Move 자체파인더 toward Finder-class behavior

Decision:
자체파인더 should move toward a Finder-class file browser, not remain only an image/PDF picker. It should show every file in the current location. Opening a file should follow Finder-style system semantics: the normal Open action uses the user's macOS default app for that file type, and Open With exposes the default app plus compatible apps where public system APIs allow. Viewooa should appear as an ordinary compatible photo app in Open With for supported image types, not as a forced global policy or a prominent custom shortcut. If the user makes Viewooa the default image app through macOS or a Viewooa preference, then normal Open follows that default. Other files, such as DMGs, archives, documents, apps, video, and audio, should remain visible and be handed to macOS system behavior unless the project later adds a dedicated viewer for that type.

Reason:
자체파인더 looks and feels close enough to Finder that hiding unsupported files makes normal folders feel incomplete or broken. Finder-like behavior is safer and easier to understand: folders are browsed, the user's default app choices are respected, Viewooa participates as a normal photo app through Open With/default-app behavior, and system-owned behavior is delegated to macOS instead of being reimplemented.

Alternatives considered:
Keeping 자체파인더 as a focused image/PDF picker, or showing unsupported files as disabled items. These are simpler, but they conflict with the Finder replacement direction and make Downloads-style folders feel wrong.

Trade-offs:
Finder-class behavior increases scope. It requires stronger keyboard navigation, clearer selection and focus states, system icon and thumbnail handling, Quick Look integration, Finder-like Open/Open With behavior, context menu parity where public APIs allow, and careful lazy loading. 자체파인더 must avoid becoming heavy by loading only visible content, caching results, limiting concurrent work, and delegating system file behavior to macOS. The project should not create brittle manual clones of private Finder behavior; it should use system mechanisms first and implement only the improvements it intentionally owns.

Follow-up:
Prioritize left-aligned Finder-like icon layout, meaningful thumbnail sizing, all-file visibility, default-app Open, system-like Open With, Finder-like right-click menus, Quick Look on Space, media hover preview, and future Finder-style tabs. Right-click should aim to mirror Finder's core context menu shape: Open, Open With, Move to Trash, Get Info, Rename, Compress, Duplicate, Make Alias, Quick Look, Copy, Share, tag colors, Tags, Show Package Contents for packages/bundles, Quick Actions, and third-party service actions where macOS exposes safe public integration points. Viewooa should be reached through Open With/default-app behavior for supported images rather than special 자체파인더-only launch controls. If a future task says to implement everything, explicitly confirm whether Finder-style tabs are included before starting.

### 2026-05-03 — Keep Viewooa a quiet photo app in the ecosystem

Decision:
Viewooa and 자체파인더 are independently launchable ecosystem apps. Viewooa should not try to stand out inside 자체파인더 with prominent custom launch UI. 자체파인더 should expose Viewooa the way Finder would expose any compatible image app: through Open With and through the user's macOS default-app choice. Viewooa may offer a quiet preference to become the default app for supported image file types through public macOS mechanisms where feasible.

Reason:
The desired product feel is "just a photo app" that fits macOS, not a branded replacement flow that fights the user's defaults. The ecosystem value should come from shared favorites, app-native tags, ratings, and future command context, not from forcing Viewooa as the special opening path.

Alternatives considered:
Adding a window-toolbar button, dedicated shortcut, or prominent "Open in Viewooa" action inside 자체파인더. These could be faster, but they would make 자체파인더 feel less Finder-like and make Viewooa feel too intrusive.

Trade-offs:
Open With/default-app behavior is less visually assertive, so users may discover Viewooa integration more slowly. This is acceptable because the product should stay quiet and familiar. Stronger integration can come from shared ecosystem state rather than custom launch controls.

Follow-up:
Design app-native tags as the primary tagging model, with optional macOS Finder/system tag display or sync as a clearly labeled secondary layer.

### 2026-05-03 — Keep Finder tag write/sync open as a long-term option

Decision:
Finder/system tag write and bidirectional sync should remain a possible future feature, not just read-only display. It must be opt-in, clearly separated from app-native tags, permission-aware, and built through public macOS metadata APIs where possible.

Reason:
App-native tags are safer and more flexible for the ecosystem, but users may eventually expect tags to interoperate with Finder. Keeping write/sync open preserves that path without forcing it into the first implementation.

Alternatives considered:
Declaring Finder/system tags read-only forever. This is simpler, but it would block a useful Better Finder behavior if the permission and conflict model becomes solid enough.

Trade-offs:
Writing Finder/system tags introduces file metadata mutation, conflict handling, undo expectations, and sandbox permission constraints. It should wait until the shared metadata manager and recovery story are reliable.

Follow-up:
Design Finder tag write/sync after app-native tags, with preview/undo where feasible, conflict handling, and clear labels that show whether a tag is app-native, Finder/system, or synchronized. When app-native tags and Finder/system tags conflict, notify the user and offer explicit choices such as keep app-native, keep Finder/system, merge, or skip; do not resolve conflicts silently.

### 2026-05-03 — Treat packages and app bundles like Finder

Decision:
자체파인더 should handle macOS packages and app bundles the same way Finder does. Normal Open should use system behavior, such as launching `.app` bundles or opening package documents with their default app. Package internals should remain hidden during ordinary browsing and become visible only through a Finder-like Show Package Contents action.

Reason:
The product direction is "Better Finder", not a new package explorer. Users expect app bundles and package documents to behave as single items unless they explicitly ask to inspect the contents.

Alternatives considered:
Always treating packages as folders, hiding them, or building custom package-specific explorers. These add surprise or scope without improving the Finder replacement goal.

Trade-offs:
Matching Finder means some real directory structure is intentionally hidden by default. That is acceptable because it preserves macOS expectations and still allows explicit package inspection.

Follow-up:
Use public macOS APIs and metadata where possible to identify packages/bundles and expose Show Package Contents in context menus and menu commands.

### 2026-05-03 — Put shared ecosystem state behind the bridge

Decision:
Favorites, app-native tags, ratings, and similar ecosystem metadata should be owned by `SharedMetadataKit`, a shared framework that ships with either Viewooa or 자체파인더. SQLite is the canonical metadata store. The preferred location is a shared App Group container, with direct/GitHub fallback storage handled through the same metadata API when App Group sharing is unavailable. Neither app should keep an isolated canonical copy of shared metadata.

Reason:
The ecosystem value comes from using either app independently while seeing the same likes, tags, and future shared context everywhere. Installing either app should bring the shared manager along so the user does not have to think about a separate dependency.

Alternatives considered:
Letting each app own its own metadata store, or requiring a separate user-facing sync app. These would make the ecosystem feel fragmented or too heavy.

Trade-offs:
A shared manager adds an architectural boundary and migration responsibility, but it keeps Viewooa and 자체파인더 independently launchable while preserving one source of truth for shared state.

Follow-up:
Implement the store with SQLite WAL, short transactions, a serial writer per process, a transactions/change-log table, versioned schema migrations, and explicit maintenance locking for migration/restore/compaction. Do not use UserDefaults, plist, raw JSON, Finder tags, or per-app Core Data/SwiftData stores as the canonical shared metadata source. The metadata store must be treated as durable user data: updates must create migration backups, writes should be atomic or journaled, corruption should be detectable, and recovery/import/export paths should exist so favorites, app-native tags, and ratings are not lost after patches. Backup creation may be automatic, but recovery must never silently replace active data. If multiple metadata versions or backups exist, the app must show a detailed comparison, including recent modification date, item counts, favorites, tags, affected files where feasible, source version, and warnings. The user must explicitly choose a version and confirm again before restore.

### 2026-05-03 — Use layered file identity, not path-only metadata keys

Decision:
Shared metadata should use app-owned stable `file_id` values as primary keys and store path, bookmark, file resource identifier, volume identifier, package/app-bundle kind, size, dates, and optional content fingerprints as observations. Absolute path alone must not be the durable identity key.

Reason:
Favorites, tags, and ratings should survive file rename, folder rename, move, external disk remount, package handling, and external changes made by Finder, Terminal, or other apps. 자체파인더 can track changes it performs directly, but shared metadata also needs to survive changes outside the app.

Alternatives considered:
Keying metadata by absolute path only. This is simple and readable, but it breaks when files are renamed or moved and is fragile for external disks.

Trade-offs:
Layered identity is more complex and needs confidence/relink logic, but it prevents user-visible metadata loss. If automatic matching is uncertain, the app should preserve metadata and ask the user to relink or choose among candidates rather than deleting or reassigning silently.

Follow-up:
Ask the architecture review to specify the exact identity fields and reconnection strategy for security-scoped bookmarks, external disks, stale bookmarks, and package/app bundle behavior.

### 2026-05-03 — Keep distribution differences behind adapters

Decision:
Use one codebase and one product model. App Store and direct/GitHub builds may differ in metadata location fallback and file access permission implementation, but Viewooa and 자체파인더 UI should use shared abstractions such as `SharedMetadataKit` and `FileAccessManager` rather than branching behavior throughout the app.

Reason:
The apps should behave consistently while still respecting sandbox/security-scoped access for App Store builds and more flexible notarized permission models for direct/GitHub builds.

Alternatives considered:
Maintaining separate App Store and direct implementations. This would increase drift and make metadata recovery, permissions, and bugs harder to reason about.

Trade-offs:
Adapters add some upfront structure, but they keep distribution-specific complexity contained.

Follow-up:
Same-channel installs should share automatically where entitlements allow. Mixed App Store/direct installs can be deferred; if automatic sharing is not authorized, use explicit import/export or migration UI and do not silently bridge stores.

### 2026-05-03 — Show inaccessible items instead of hiding them

Decision:
In App Store/sandboxed builds, 자체파인더 should show inaccessible files and folders when they are discoverable, but mark them disabled rather than hiding them. Selecting or opening such an item should explain that the App Store build cannot access it with current permissions and offer a gentle permission path where possible.

Reason:
Better Finder behavior should preserve the shape of a folder. Hiding inaccessible items makes folders feel incomplete and undermines trust.

Alternatives considered:
Hiding inaccessible items, or treating permission failures as generic errors. These are simpler, but they make the browser feel broken or mysterious.

Trade-offs:
Showing disabled items requires careful loading and error handling, and some protected items may not be discoverable at all. The UI should distinguish "visible but inaccessible" from "not visible to the app".

Follow-up:
Design a soft first-run permission screen and a one-click permission request path for broad locations such as Macintosh HD or external disks, while avoiding alarmist wording.

### 2026-05-03 — Treat 자체파인더 as a temporary label

Decision:
`자체파인더` is a temporary working label, not the final public app name.

Reason:
The current work needs a clear word that separates the Finder-class browser from Viewooa, but final naming can wait until product shape and distribution are clearer.

Alternatives considered:
Locking `자체파인더` as the public name now. This is unnecessary and could make branding decisions premature.

Trade-offs:
Temporary naming means code and docs may need a naming pass later, but it prevents Viewooa from being overloaded as both photo viewer and Finder app.

Follow-up:
Before public release packaging, choose final naming for the Finder-class app and update docs, bundle names, README copy, and user-facing strings together.

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
