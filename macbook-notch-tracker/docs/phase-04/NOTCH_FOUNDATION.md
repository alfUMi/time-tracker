# Phase 4 Notch Foundation

## Purpose

This phase turns the notch surface from a simple preview card into a stateful overlay experience with hover-aware reveal rules.

## What Changed

- added a dedicated notch overlay coordinator with reveal, visible, and hidden phases
- added delayed reveal and delayed dismissal timing based on settings
- separated hover-driven presentation from command-pinned presentation
- replaced the generic notch preview with a more compact, state-aware notch surface
- replaced the preview-only host approach with AppKit-backed trigger and overlay windows

## Interaction Model

### Hover Presentation

- entering the trigger zone schedules reveal
- leaving the trigger zone schedules dismissal unless the pointer enters the surface
- entering the surface keeps the notch open
- leaving the surface dismisses it after the configured close delay

### Windowing Model

- a small transparent trigger window sits near the top center of the preferred screen
- a floating borderless panel hosts the notch surface
- both windows reposition when screen parameters change
- the built-in display is preferred when available

### Pinned Presentation

- the dashboard and menu bar can pin the notch surface open
- pinned mode is useful as a fallback path and for testing while the real overlay evolves
- closing the pinned surface resets the coordinator to hidden

## UI Rules Applied

- one primary action per state
- compact width with readable spacing
- dashboard access remains secondary
- state is expressed through icon, label, and color together

## Next Build Steps

- add tighter focus handling and keyboard dismissal rules
- refine the state-specific layout and animations based on real hardware behavior
- improve built-in display detection and multi-display fallback behavior
- add a more precise non-intrusive trigger region that minimizes menu bar interference
