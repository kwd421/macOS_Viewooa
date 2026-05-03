# Agent Reading Guide

This file tells AI coding agents what to read first and where to look for specific kinds of work in this repository.

## Read First

Before changing code or product docs, read these files in order:

1. `INBOX.md`
   - Human scratchpad for rough notes, bug reports, ideas, and unresolved questions.
   - Skim this for fresh user context before making product, roadmap, or code changes.
   - Do not treat notes here as approved work until they are clarified or promoted into a source-of-truth doc.
2. `docs/product/DESIGN.md`
   - Product constitution.
   - Use this for product principles, naming, non-negotiable decisions, and links to topic docs.
3. `docs/product/IMPLEMENTATION_MAP.md`
   - Architecture and ownership boundaries.
   - Use this to decide where code belongs and which module owns a behavior.
4. `docs/product/ROADMAP.md`
   - Current status.
   - Use this to distinguish Active, Done, Needs Verification, Deferred, and Cancelled/Replaced work.
5. `docs/engineering/AI_AGENT_RULES.md`
   - Execution rules.
   - Use this for coding conduct, safety, verification, and preserving user changes.

Do not treat Cancelled or Replaced roadmap items as active work.

## Product Naming

- `Viewooa` means the photo viewer.
- `Better Finder` is the current working name for the Finder-class browser app.
- Some product docs may still use `자체파인더` as the internal shorthand for the Finder-class browser.
- Do not use `Viewooa` to mean the Finder-class browser.

## Task Router

| If the task is about... | Read this first | Then check |
| --- | --- | --- |
| Fresh user notes, rough ideas, unprocessed bug reports, or Obsidian scratchpad updates | `INBOX.md` | Ask before promoting into source-of-truth docs |
| Product direction, principles, UX philosophy, or "what should this feel like?" | `docs/product/DESIGN.md` | `docs/product/ROADMAP.md` |
| Where to implement a feature | `docs/product/IMPLEMENTATION_MAP.md` | Relevant Swift files under `Viewooa/` |
| Whether a feature is active, deferred, done, or cancelled | `docs/product/ROADMAP.md` | `docs/product/DESIGN.md` if product intent is unclear |
| Detailed Viewooa photo viewer UX | `docs/product/UX_SPEC.md` | `docs/product/IMPLEMENTATION_MAP.md`, `Viewooa/Viewer/` |
| Detailed UX topic work | `docs/product/UX_SPEC.md` | The focused UX doc linked from that index |
| Better Finder / Finder-class browser behavior | `docs/product/FINDER_BEHAVIOR.md` | `docs/product/IMPLEMENTATION_MAP.md`, `Viewooa/OpenBrowser/` |
| Known bugs, regressions, or observed product issues | `docs/product/KNOWN_ISSUES.md` | `docs/product/ROADMAP.md`, relevant topic docs |
| Open, Open With, default apps, Quick Look, context menus, packages, app bundles | `docs/product/FINDER_BEHAVIOR.md` | `docs/product/IMPLEMENTATION_MAP.md`, `docs/product/ROADMAP.md` |
| Path bar, selected-file breadcrumbs, icons, Cancel/Open removal | `docs/product/FINDER_BEHAVIOR.md` | `docs/product/IMPLEMENTATION_MAP.md`, `Viewooa/OpenBrowser/` |
| Keyboard shortcuts, selection, cut/paste, undo, recoverable file operations | `docs/product/FINDER_BEHAVIOR.md` | `docs/product/INTERACTION_AND_FILE_SAFETY.md`, `Viewooa/OpenBrowser/` |
| Metadata, favorites, app-native tags, ratings, backups, recovery | `docs/product/METADATA_ARCHITECTURE.md` | `docs/product/IMPLEMENTATION_MAP.md` App Bridge / Shared Metadata section |
| SQLite, `SharedMetadataKit`, file identity, external disk relinking | `docs/product/METADATA_ARCHITECTURE.md` | `docs/product/IMPLEMENTATION_MAP.md`, `docs/product/ROADMAP.md` |
| App Store vs GitHub/direct builds, sandboxing, permissions, inaccessible items | `docs/product/DISTRIBUTION_AND_PERMISSIONS.md` | `docs/product/IMPLEMENTATION_MAP.md`, `docs/product/ROADMAP.md` |
| Finder/system tag display, write, sync, or conflict handling | `docs/product/METADATA_ARCHITECTURE.md` | `docs/product/FINDER_BEHAVIOR.md`, `docs/product/ROADMAP.md` |
| App Intents, MCP, AI file operations, automation safety | `docs/product/INTERACTION_AND_FILE_SAFETY.md` | `docs/product/IMPLEMENTATION_MAP.md`, `docs/engineering/AI_AGENT_RULES.md` |
| Historical rationale or dated decisions | `docs/product/DECISIONS.md` | Current source-of-truth docs above |
| Tests, verification, safe edits, dirty worktrees, user changes | `docs/engineering/AI_AGENT_RULES.md` | Existing tests and local project conventions |

## Source Of Truth Rules

- `DESIGN.md` wins for product intent.
- `IMPLEMENTATION_MAP.md` wins for architecture boundaries.
- `ROADMAP.md` wins for current status and priority.
- `INBOX.md` is not a source of truth. It is a human scratchpad. Use it to discover fresh context, then clarify, summarize, or promote agreed items into the correct source-of-truth doc.
- Topic docs (`UX_SPEC.md` and the UX docs it routes to, `FINDER_BEHAVIOR.md`, `METADATA_ARCHITECTURE.md`, `DISTRIBUTION_AND_PERMISSIONS.md`) win for detailed behavior in their area unless `DESIGN.md` explicitly says otherwise.
- `KNOWN_ISSUES.md` wins for observed current bugs and regressions until the issue is fixed or moved into normal roadmap work.
- `DECISIONS.md` is historical rationale, not a replacement for the current source-of-truth docs.
- `AI_AGENT_RULES.md` wins for execution discipline.
- If these files conflict, stop and surface the conflict instead of guessing.

## High-Risk Areas

Read the relevant source-of-truth sections carefully before touching:

- Shared metadata persistence, migrations, backups, recovery, import/export.
- `SharedMetadataKit`, file identity, security-scoped bookmarks, external disks.
- File operations that move, rename, delete, tag, sync, restore, or batch-change user data.
- App Store sandbox permissions, inaccessible item UI, and GitHub/direct build differences.
- AI, App Intents, MCP, and any automation that can change files.

## Implementation Notes

- Prefer existing local patterns and code boundaries.
- Keep Markdown docs under 500 lines wherever possible. If any `.md` file grows beyond 500 lines, split it into focused topic docs and update this reading guide plus the relevant index file.
- Keep Viewooa and Better Finder independently launchable.
- Keep shared state behind bridge/shared metadata boundaries.
- Direct user-initiated recoverable Finder-like actions should execute without nagging confirmations.
- Irreversible, AI/automation, metadata restore, ambiguous broad, risky batch, or unclear-undo operations require preview/confirmation.
- Use `rg` for search and inspect relevant files before editing.
