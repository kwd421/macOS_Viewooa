# QUALITY_AND_PRIORITIES.md

> Performance, accessibility, onboarding, guardrails, priority, and Apple-like quality definitions. Read `DESIGN.md` and `UX_SPEC.md` first.

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
- VoiceOver labels for window toolbar items, thumbnails, previews, and inspector fields.
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

### P0: Core 자체파인더
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
