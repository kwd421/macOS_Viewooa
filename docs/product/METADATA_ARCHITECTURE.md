# METADATA_ARCHITECTURE.md

> Shared metadata architecture for Viewooa and Better Finder. Read `DESIGN.md` first.

## Core Decision

Use `SharedMetadataKit` with SQLite as the single canonical metadata store.

- Shared metadata includes favorites/likes, app-native tags, ratings, and future AI/App Intents/MCP command context.
- Installing either Viewooa or Better Finder should include the shared metadata capability.
- Users should not see or launch a separate manager app.
- Neither app should keep an isolated canonical copy of shared metadata.

## Storage

Preferred location:

```text
<AppGroupContainer>/
  Library/Application Support/ViewooaMetadata/
    metadata.sqlite
    metadata.sqlite-wal
    metadata.sqlite-shm
    Backups/
    Exports/
    Quarantine/
    Locks/
```

Use:

- SQLite canonical DB.
- WAL mode.
- Short transactions.
- Serial writer per process.
- Transactions/change-log table.
- Versioned schema migrations.
- Explicit maintenance lock for migration, restore, compaction, backup pruning, and destructive import.

Do not use as the canonical store:

- UserDefaults
- plist
- raw JSON
- Finder/system tags
- per-app Core Data stores
- per-app SwiftData stores

JSON is appropriate for import/export packages, not live state.

## Durability

Treat metadata as durable user data.

Required safeguards:

- atomic or journaled writes
- SQLite integrity checks
- versioned migrations
- pre-migration backups
- automatic backups
- corruption detection
- explicit recovery UI
- import/export
- quarantine of replaced/corrupt stores

Automatic backup is allowed. Automatic restore is forbidden.

If recovery is needed, show candidate versions with:

- last modified date
- source app/version/build/distribution
- schema version
- counts of files, favorites, tags, tag assignments, ratings, and Finder mappings
- affected file examples where feasible
- integrity status
- warnings about consequences

The user must choose a version and confirm again before restore.

## File Identity

Do not key durable metadata by absolute path only.

Use app-owned stable `file_id` values as primary keys and store identity observations:

- current path
- path hash
- bookmark reference
- file resource identifier
- volume identifier
- kind: file, directory, package, app bundle
- size
- content modification date
- creation date
- optional content fingerprint when needed

Path-only metadata breaks when files are renamed, moved, or reconnected from external disks.

When confidence is low, preserve metadata and ask the user to relink or choose among candidates. Do not delete or silently reassign metadata.

## External Disks

- Do not delete metadata when a volume is offline.
- Mark affected files as offline/unresolved.
- Try bookmark/resource/volume observations first when the disk returns.
- If automatic recovery is uncertain, ask the user to relink.
- Initial stress testing should focus on external disks and packages/app bundles.

## Finder/System Tags

App-native tags are primary.

Finder/system tags are optional and clearly separate:

- display
- read
- write
- sync

Finder tag write/sync can come later after permissions, undo, recovery, and conflict handling are reliable.

Sync conflicts must not be resolved silently. Notify the user and offer explicit choices such as:

- keep app-native
- keep Finder/system
- merge
- skip

## AI/App Intents/MCP Metadata

Durable user-facing AI results belong in metadata tables such as annotations. Rebuildable embeddings or indexes should live in separate rebuildable stores keyed by `file_id`.
