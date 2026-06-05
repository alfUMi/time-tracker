# Native GUI Migration Report

## Current State

- The app already uses the SwiftUI application lifecycle via `@main` in `Sources/MacBookNotchTracker/App/MacBookNotchTrackerApp.swift`.
- The overlay system, dashboard window, menu bar UI, and event handling are all implemented with SwiftUI and AppKit.
- The project is packaged only as a Swift Package Manager executable in `Package.swift`.

## CLI-Oriented Components

- `Package.swift` defines a single `.executable` product and `.executableTarget`.
- There is no native macOS app project in the repository.
- There is no application bundle metadata such as `Info.plist`, bundle identifier, or app target configuration.
- There is no `.app` packaging path for Finder, Spotlight, Dock, or Launchpad launching.

## Why Terminal Opens

- A SwiftPM executable is treated as a command-line style product.
- Running it through `swift run`, package schemes, or similar tooling launches it in a terminal-oriented execution context.
- Even though the executable renders UI, its packaging does not describe a native macOS application bundle.

## Why The App Is Not Treated As Native GUI

- Native GUI apps on macOS are expected to launch from an `.app` bundle with bundle metadata and app target settings.
- The current repository has UI code but lacks the bundle/project layer that makes macOS recognize it as a standard application.
- As a result, the product behaves like a package executable with windows rather than a normal Finder-launchable app.

## Current Startup Flow

1. The executable starts from the SwiftPM product.
2. `MacBookNotchTrackerApp` initializes `AppContainer`.
3. `IslandSceneController` installs the overlay windows.
4. SwiftUI creates the dashboard window group, menu bar extra, and settings scene.

## Migration Direction

- Keep the existing SwiftUI/AppKit runtime code.
- Add native macOS app packaging with:
  - a proper Xcode app project
  - app bundle metadata
  - a launchable `.app` product
- Use the native app target as the canonical launch path instead of the SwiftPM executable target.
- Remove the runnable SwiftPM executable path by keeping the package as shared support code rather than an app entry point.
