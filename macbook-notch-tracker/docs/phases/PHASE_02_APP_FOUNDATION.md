# Phase 2 - App Foundation

## Objective

Create the native macOS shell that can host both the notch overlay and the dashboard window.

This phase focuses on lifecycle, windows, scenes, and system-level behavior.

## Scope

- initialize the macOS app project
- configure app scenes and shared state
- set up overlay window infrastructure
- add dashboard window infrastructure
- prepare system integrations and startup behavior

## Work Items

### Project Setup

- create the SwiftUI macOS app target
- define folder structure for app shell, services, features, and design system
- set up shared environment objects or observation models

### Window And Scene Management

- create the main dashboard scene
- create a dedicated overlay or panel manager for the notch surface
- define how the app opens, hides, and restores windows

### System Integration

- add menu bar access
- add keyboard shortcut entry points
- add launch-at-login support
- define notification permission flow if reminders are part of MVP

### Hardware And Display Rules

- detect the built-in display
- anchor the notch trigger to the top center of the correct screen
- define fallback behavior when the internal display is unavailable

## Deliverables

- running macOS app shell
- dashboard window placeholder
- overlay panel placeholder
- menu bar access path
- startup and scene management notes

## Implementation Outputs

The first development pass for this phase is now captured in:

- `Package.swift`
- `docs/phase-02/FOUNDATION_SCAFFOLD.md`
- `Sources/MacBookNotchTracker/App/`
- `Sources/MacBookNotchTracker/Core/`
- `Sources/MacBookNotchTracker/DesignSystem/`
- `Sources/MacBookNotchTracker/Features/`
- `Sources/MacBookNotchTracker/Platform/`

## Exit Criteria

- app launches cleanly
- dashboard window can open and close on demand
- overlay infrastructure can be positioned on the built-in display
- fallback activation paths exist even before the notch UI is finished

## Risks To Watch

- brittle positioning across different MacBook display scales
- overreliance on SwiftUI for behaviors that need AppKit control
- unclear app activation behavior when the overlay appears
