# UX_SPEC.md

> UX specification index for Viewooa and Better Finder. Read `DESIGN.md` first for the product constitution.

This file stays short on purpose. Agents should use it to choose the right detailed UX document instead of loading one very long spec by default.

## Read Order

1. `docs/product/DESIGN.md` for product constitution and non-negotiable principles.
2. This file to route UX questions.
3. The focused topic doc below that matches the work.

## UX Topic Docs

| If the task is about... | Read |
| --- | --- |
| Core experience goals, browsing, previewing, organizing, search/filter, AI assistance, or window structure | `docs/product/EXPERIENCE_GOALS.md` |
| Visual hierarchy, materials, colors, icons, spacing, animation, or native-feeling UI polish | `docs/product/VISUAL_DESIGN.md` |
| Selection, drag/drop, keyboard shortcuts, context menus, AI command behavior, or file safety | `docs/product/INTERACTION_AND_FILE_SAFETY.md` |
| Performance, accessibility, onboarding, non-goals, implementation guardrails, feature priority, or Apple-like quality | `docs/product/QUALITY_AND_PRIORITIES.md` |

## Cross-References

- Better Finder-specific behavior lives in `docs/product/FINDER_BEHAVIOR.md`.
- Known Better Finder issues live in `docs/product/KNOWN_ISSUES.md`.
- Shared metadata, tags, favorites, ratings, backups, and recovery live in `docs/product/METADATA_ARCHITECTURE.md`.
- App Store/GitHub distribution and permission behavior lives in `docs/product/DISTRIBUTION_AND_PERMISSIONS.md`.
- Current priority and status live in `docs/product/ROADMAP.md`.

## Maintenance Rule

- Keep this file under 500 lines. If a UX topic grows, split it into a new focused topic doc and update this index plus `AGENTS.md`.
