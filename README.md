# Viewooa

Fast, simple macOS image viewer inspired by Honeyview.

## Build and open

- Open `Viewooa.xcodeproj` in Xcode and run the `Viewooa` scheme, or build from Terminal with `xcodebuild -project Viewooa.xcodeproj -scheme Viewooa -destination 'platform=macOS' build`.
- The app is a macOS SwiftUI target for Xcode 26.4.1 with Swift 6 and a macOS 15.0 deployment target.

## v1 scope

- Open a file or folder
- Browse images by filename order
- Zoom, fit, actual size, rotate
- Fast previous and next navigation with bounded preload
