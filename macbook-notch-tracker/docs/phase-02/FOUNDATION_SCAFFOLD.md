# Phase 2 Foundation Scaffold

## Purpose

This scaffold establishes the native macOS app shell and the modular boundaries that later phases will build on.

## Source Layout

```text
Sources/MacBookNotchTracker/
├── App/
│   ├── AppContainer.swift
│   └── MacBookNotchTrackerApp.swift
├── Core/
│   ├── Commands/
│   ├── Models/
│   ├── Services/
│   └── Session/
├── DesignSystem/
├── Features/
│   ├── Dashboard/
│   ├── MenuBar/
│   ├── Notch/
│   └── Settings/
└── Platform/
    └── Windowing/
```

## What Exists Now

- Swift package entry point for a macOS executable app
- shared `AppContainer` for app-wide state and dependencies
- `AppCommandRouter` so surfaces share one action path
- `SessionEngine` for the first session-state scaffold
- in-memory persistence and stubbed platform services
- dashboard shell with modular section registry
- notch preview surface
- menu bar access
- settings placeholder

## Why This Matters

- features can be added as modules without spreading logic across unrelated files
- the notch and dashboard already share one command layer
- platform integrations are behind protocols, making later replacements easier
- dashboard sections can grow through the registry instead of bespoke navigation rewrites

## Next Build Steps

- replace in-memory persistence with real local storage
- add real overlay window handling for the notch trigger region
- connect dashboard window opening and restoration more explicitly
- implement timer updates and richer session history
- add real notification and launch-at-login integrations
