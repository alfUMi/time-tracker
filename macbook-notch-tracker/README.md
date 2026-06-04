# MacBook Notch Tracker

This directory contains the planning package for a new native macOS app that combines:

- a hover-activated notch surface at the top center of the MacBook display
- a full dashboard window with detailed data, settings, and controls
- a modern visual system with strong color discipline, sharp iconography, and no gradients

## Planning Files

- `docs/PROJECT_PLAN.md` - master product, technical, and delivery plan
- `docs/phases/PHASE_01_PRODUCT_AND_UX.md` - product definition and experience blueprint
- `docs/phases/PHASE_02_APP_FOUNDATION.md` - macOS shell, scenes, windows, and system hooks
- `docs/phases/PHASE_03_SHARED_LOGIC.md` - tracking engine, persistence, and shared services
- `docs/phases/PHASE_04_NOTCH_EXPERIENCE.md` - hover-triggered notch UI and quick controls
- `docs/phases/PHASE_05_DASHBOARD_EXPERIENCE.md` - dashboard information architecture and control surface
- `docs/phases/PHASE_06_POLISH_AND_RELEASE.md` - QA, accessibility, performance, and release prep

## Source Scaffold

- `Package.swift` - Swift package entry point for the native macOS scaffold
- `Sources/MacBookNotchTracker/App/` - app entry and shared dependency container
- `Sources/MacBookNotchTracker/Core/` - commands, models, persistence protocols, and session engine
- `Sources/MacBookNotchTracker/Features/` - dashboard, notch, menu bar, and settings surfaces
- `Sources/MacBookNotchTracker/DesignSystem/` - shared colors, spacing, and panel styling
- `Sources/MacBookNotchTracker/Platform/` - windowing and overlay platform adapters
- `docs/phase-02/FOUNDATION_SCAFFOLD.md` - source-level explanation of the scaffold
- `docs/phase-03/SHARED_LOGIC_FOUNDATION.md` - persistence, session-state, and query-layer handoff
- `docs/phase-04/NOTCH_FOUNDATION.md` - overlay coordination and compact notch interaction handoff
- `docs/phase-05/DASHBOARD_FOUNDATION.md` - dashboard layout, history workflows, and settings handoff

## Working Assumption

This plan assumes the new product keeps the same core domain as the current project: a time-tracking and productivity utility.

If you want the notch-and-dashboard shell to support a different app concept later, the platform plan still holds and the domain modules can be swapped.
