# Phase 5 - Dashboard Experience

## Objective

Build the detailed management surface that complements the notch and gives the user confidence in the data.

This phase turns raw session data into a complete desktop workflow.

## Scope

- implement dashboard navigation and layout
- add overview cards and current-session detail
- add history browsing and editing
- add settings and mirrored controls

## Work Items

### Structure

- define the dashboard as a single-window experience with clear sections
- choose a navigation model that feels native on macOS
- keep the current session and primary actions immediately visible

### Overview And Insights

- build today, week, and month summary cards
- add charts that emphasize trend and duration clarity
- use solid fills and restrained borders instead of decorative gradients

### History And Editing

- build a session list or timeline
- add filters by date and session state
- support correction flows for manual edits with confirmation and undo

### Settings And Controls

- duplicate core session controls in the dashboard
- expose hover behavior, reminders, startup, and appearance settings
- keep form design simple, readable, and consistent with macOS expectations

## Deliverables

- dashboard layout
- summary cards and charts
- history and editing tools
- settings panels
- mirrored control layer

## Implementation Outputs

The first development pass for this phase is now captured in:

- `docs/phase-05/DASHBOARD_FOUNDATION.md`
- `Sources/MacBookNotchTracker/Features/Dashboard/DashboardRootView.swift`
- `Sources/MacBookNotchTracker/Core/Session/SessionEngine.swift`

## Exit Criteria

- the dashboard can fully manage the app without the notch
- history is readable and trustworthy
- settings are clear and easy to change
- overview metrics align with the same shared logic used by the notch

## Risks To Watch

- making the dashboard visually heavier than the notch
- hiding important settings too deeply
- charts becoming decorative instead of useful
