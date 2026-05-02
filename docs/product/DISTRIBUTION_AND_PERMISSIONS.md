# DISTRIBUTION_AND_PERMISSIONS.md

> Distribution and file-permission behavior for Viewooa and Better Finder. Read `DESIGN.md` first.

## Core Decision

Use one codebase and one product model.

App Store and direct/GitHub builds may differ in permission implementation and metadata location fallback, but UI and product behavior should use shared abstractions:

- `FileAccessManager`
- metadata location provider
- `SharedMetadataKit`

Do not branch product behavior throughout the app.

## App Store Builds

Assume sandbox/security-scoped access constraints.

Expected behavior:

- First-run permission onboarding is soft, non-alarmist, and clearly branded as Viewooa/Better Finder.
- Do not pretend to be a system dialog.
- Offer a clear one-click path to request broad locations such as Macintosh HD or external disks where possible.
- Store and refresh security-scoped bookmarks when needed.
- If access cannot be restored after update or environment change, explain gently and offer a re-allow button.

If the user grants Macintosh HD or another broad folder, access generally extends within that folder, but not necessarily to every protected location. System protection, privacy controls, other users, other app containers, POSIX/ACL restrictions, and other OS limits can still block access.

## Direct/GitHub Builds

Direct/GitHub notarized builds may use a more flexible permission model, but should still preserve user trust:

- no fake system UI
- no hidden broad file mutations
- clear permission explanations
- same command/undo/recovery model as App Store builds

## Inaccessible Items

In App Store/sandboxed builds:

- Show discoverable inaccessible files/folders as disabled.
- Do not hide them as if they do not exist.
- Selecting or opening a disabled item should explain that current permissions do not allow access.
- Offer a gentle permission path where possible.
- Some protected items may not be discoverable at all; distinguish "visible but inaccessible" from "not visible to the app."

## FileAccessManager

Use a common interface so UI does not care about distribution details.

Example responsibilities:

- request access to a file/folder/volume
- restore previously granted access
- determine read/write access
- resolve stale bookmarks
- represent inaccessible/offline/unresolved states
- provide permission explanations for UI

App Store adapter:

- security-scoped bookmarks
- sandbox-compatible access
- App Group-aware metadata location

Direct/GitHub adapter:

- more flexible file access where available
- same user-facing access model where possible
- fallback storage only when App Group sharing is unavailable

## Mixed Installs

Mixed installs can happen:

- App Store Viewooa + App Store Better Finder
- direct Viewooa + direct Better Finder
- App Store Viewooa + direct Better Finder
- direct Viewooa + App Store Better Finder

Same-channel installs should share automatically where entitlements allow.

Mixed App Store/direct automatic sharing can be deferred. If sharing is not authorized, use explicit import/export or migration UI. Do not silently bridge stores or silently choose one store over another.

## Permission Tone

The tone should feel macOS-native: calm, clear, concise.

But it must be obvious the app is speaking. Never trick users into thinking an app-created sheet is a system dialog.
