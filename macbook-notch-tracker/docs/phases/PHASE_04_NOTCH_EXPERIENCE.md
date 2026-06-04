# Phase 4 - Notch Experience

## Objective

Build the compact hover-activated surface that makes the app feel uniquely at home on a MacBook.

This phase turns the overlay from a shell into a working quick-control experience.

## Scope

- implement the hover trigger region
- build notch open and close behavior
- add quick session controls
- show compact status, timing, and shortcut information

## Work Items

### Reveal Behavior

- create the invisible top-center activation region
- tune hover delay, open timing, and close timing
- prevent accidental flashing while the pointer crosses the menu bar area

### Layout

- define a compact notch card or sheet layout
- prioritize timer, state, and primary controls
- keep spacing generous enough to avoid cramped interaction targets

### Controls

- add start, stop, pause, resume, and break actions
- add a quick path to open the dashboard
- optionally add a quick task selector or session label field if it fits the width

### Feedback

- animate state changes with subtle scale, opacity, or position
- reflect current state using icon, color, and short text together
- support keyboard focus and screen-reader labels

## Deliverables

- hover-triggered notch overlay
- working quick-control set
- compact session summary UI
- transition spec for reveal and dismissal

## Implementation Outputs

The first development pass for this phase is now captured in:

- `docs/phase-04/NOTCH_FOUNDATION.md`
- `Sources/MacBookNotchTracker/Features/Notch/NotchOverlayCoordinator.swift`
- `Sources/MacBookNotchTracker/Features/Notch/NotchPreviewView.swift`
- `Sources/MacBookNotchTracker/App/MacBookNotchTrackerApp.swift`
- `Sources/MacBookNotchTracker/App/AppContainer.swift`

## Exit Criteria

- the notch opens reliably from the intended hover zone
- quick actions are usable without opening the dashboard
- controls meet minimum touch and pointer target expectations
- the layout remains legible across supported MacBook sizes

## Risks To Watch

- hover-only discovery problems
- small target areas near the top edge
- crowded content that undermines the premium feel
