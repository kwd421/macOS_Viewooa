# Viewooa Design Spec

Date: 2026-04-19
Topic: Honeyview-style macOS image viewer

## Goal

Build a macOS image viewer that feels closer to Honeyview than BandiView: light, immediate, and focused on viewing one image at a time.

The first version should optimize for:

- Opening a folder and immediately viewing a large single image
- Moving to previous and next images with near-instant response
- Supporting both regular window use and fullscreen use
- Keeping the interface quiet and simple

The first version explicitly does not include:

- Archive browsing
- File delete, move, copy, or organize flows
- Favorites, tags, or library features
- Complex thumbnail management
- Finder sort order sync

## Product Direction

This app is a viewer first, not a browser first.

The primary experience is:

1. Open a folder or image
2. Show the current image large in the main window
3. Move quickly through neighboring images
4. Zoom in, pan, fit to window, return to actual size, rotate, and continue browsing

The app should feel natural on macOS but not overloaded with native UI chrome. The image should remain the focus. Toolbars and controls should stay minimal and predictable.

## User Experience

### Main Window

The main window uses almost all available space for the image.

It contains:

- A central image canvas
- A slim top toolbar
- Optional fullscreen support using normal macOS window behavior

The first version does not include a visible sidebar. A thumbnail strip is out of scope for the initial release unless later added as a hidden or optional enhancement.

### Supported Actions

The first version supports:

- Open file or folder
- Move to previous image
- Move to next image
- Zoom in
- Zoom out
- Fit image to window
- Show actual size
- Rotate left and right
- Pan while zoomed
- Enter and leave fullscreen

### Input Model

The same browsing actions should be reachable from multiple input methods.

- Keyboard: left and right arrows for navigation, standard zoom shortcuts, fullscreen shortcut
- Mouse: toolbar buttons and double-click for a fast zoom behavior
- Trackpad: swipe and pinch where appropriate
- Scroll wheel: available for navigation or zoom depending on the final implementation defaults

The key requirement is consistency and responsiveness. Input method matters less than instant feedback.

## Technical Architecture

The app uses a mixed SwiftUI and AppKit design.

### Why Mixed Architecture

SwiftUI is a good fit for:

- App lifecycle
- Window scenes
- Toolbar composition
- Simple state bindings

AppKit is a better fit for the image viewer core:

- Image rendering behavior
- Scroll and zoom precision
- Gesture handling
- Keyboard handling
- Performance-sensitive navigation

### Proposed Structure

- `ViewooaApp`
  SwiftUI app entry, scenes, commands, and top-level window setup
- `ViewerWindowShell`
  SwiftUI container for toolbar, commands, and bindings to the viewer state
- `ViewerState`
  Shared state for current file, zoom mode, rotation, fit mode, and UI-facing commands
- `FolderImageIndex`
  Builds and manages the ordered list of image files in the current folder
- `ImagePreloadQueue`
  Handles background loading and nearby image caching
- `ImageViewerContainerView`
  AppKit bridge that hosts the actual viewer
- `ImageViewerNSView`
  AppKit image view implementation for rendering, pan, zoom, and input events

## Data Flow

### Opening Content

When a user opens a file:

1. Detect the parent folder
2. Enumerate supported image files in that folder
3. Sort by filename for v1
4. Locate the selected file within that ordered list
5. Load the current image immediately
6. Start background preload for neighboring images

When a user opens a folder directly:

1. Enumerate supported image files
2. Sort by filename
3. Open the first valid image
4. Begin preload around that index

### Navigation

On previous or next:

1. Update the current index
2. Swap in a preloaded image if available
3. Fall back to synchronous load only when preload missed
4. Refresh preload targets around the new index
5. Drop far-away cached images to control memory use

### Zoom and Fit

Viewer state stores whether the image is:

- In fit-to-window mode
- In actual-size mode
- At an arbitrary zoom level

Navigation behavior should keep zoom rules simple and predictable. For the first version, a newly navigated image should default back to fit-to-window unless the implementation proves persistent zoom is clearly better and still simple.

## Performance Plan

Performance is a product requirement, not an optimization pass.

### Initial Loading

The app should not decode every image in a folder at open time. It should:

- Index file paths first
- Decode only the current image immediately
- Preload a small nearby window around the current index

### Preload Strategy

Initial target:

- Current image: fully loaded now
- Previous image: preload if available
- Next 2 to 3 images: preload if available

This biases forward navigation while still allowing a quick back step.

### Memory Strategy

The cache should be bounded and proximity-based.

- Keep only nearby decoded images
- Release images that are several steps away
- Tune cache window later based on real memory behavior

The design should support future use of thumbnail caches separately, but v1 does not require them.

## File Support

The first version should support common still-image formats that macOS handles well through native frameworks, such as:

- JPEG
- PNG
- GIF
- WebP if supported cleanly by the chosen stack
- HEIC if available through system support

The exact supported set should be derived from what the implementation can render reliably through native APIs without extra complexity.

Animated image handling is not a core requirement for v1. If native support comes naturally, it is acceptable, but not a primary success criterion.

## Error Handling

The app should fail quietly and clearly.

Expected cases:

- Folder contains no supported images
- Current image is unreadable or corrupt
- User opens a folder with mixed file types
- A neighboring image fails to decode during preload

Handling rules:

- Show a simple empty state if no images are available
- If one image fails, show a clear inline error and still allow moving to previous and next files
- Preload failures should not block foreground navigation
- Avoid modal alerts for normal browsing problems unless the user explicitly requested an action that requires one

## Testing Strategy

### Manual Testing

Primary manual scenarios:

- Open a folder with many images and navigate rapidly
- Open a single file inside a folder and verify correct indexing
- Use keyboard, toolbar, mouse, and trackpad interactions
- Enter fullscreen and return to windowed mode
- Zoom, pan, switch images, and verify expected reset behavior
- Try corrupt or unsupported files in the folder

### Automated Testing

Unit-test coverage should focus on logic, not UI rendering internals:

- Folder enumeration and filename sorting
- Current index selection
- Neighbor preload targeting
- Cache eviction policy behavior
- Error-tolerant navigation when some files fail

UI automation can be added later, but it is not required to start implementation.

## Out of Scope for v1

- Archive file browsing
- Finder extension behavior
- Custom sortable metadata views
- Delete, move, copy, or batch actions
- Thumbnail browser as a primary mode
- Favorites, ratings, tags
- Multi-window compare mode
- Editing tools

## Recommended Implementation Order

1. App shell and single viewer window
2. Open file and folder flows
3. Folder indexing and filename ordering
4. AppKit image viewer with fit, zoom, pan, rotate
5. Previous and next navigation
6. Background preload and bounded cache
7. Fullscreen polish and empty or error states

## Open Decisions Resolved In This Spec

- Primary mode is single-image viewing
- Initial file ordering is filename-based
- The app is intentionally simple in v1
- Default usage is regular windowed mode with fullscreen support
- Architecture is SwiftUI shell plus AppKit viewer core
- File management features are out of scope

## Success Criteria

The first release is successful if:

- A folder opens quickly
- The first image appears without friction
- Previous and next navigation feels immediate in normal use
- Zoom and fit interactions feel stable and native on macOS
- The UI stays minimal and does not distract from the image
