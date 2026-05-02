# VISUAL_DESIGN.md

> Visual design system details for Viewooa and Better Finder. Read `DESIGN.md` and `UX_SPEC.md` first.

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
