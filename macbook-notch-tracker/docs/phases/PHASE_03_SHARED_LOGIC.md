# Phase 3 - Shared Logic

## Objective

Build the app logic that both the notch surface and the dashboard depend on.

This is the foundation for trustworthy data and mirrored controls.

## Scope

- implement the session state model
- add persistence for sessions and settings
- expose shared commands to all UI surfaces
- provide dashboard-ready queries and summaries

## Work Items

### Session Engine

- define session states such as idle, running, paused, and on break
- implement start, stop, pause, resume, and break transitions
- ensure only one active session can exist at a time

### Persistence

- define local data models for sessions, tags, notes, and preferences
- store timestamps, durations, and correction metadata
- prepare migration-safe data handling for future changes

### Shared Commands

- expose a single action layer used by both notch and dashboard controls
- keep validation out of the view layer
- define undo-friendly operations where possible

### Query Layer

- build summary queries for today, week, and month views
- build history queries with filters
- prepare chart-ready series data for Swift Charts

## Deliverables

- session engine
- persistence layer
- shared command handlers
- reusable summary and history queries

## Implementation Outputs

The first development pass for this phase is now captured in:

- `docs/phase-03/SHARED_LOGIC_FOUNDATION.md`
- `Sources/MacBookNotchTracker/Core/Models/SessionModels.swift`
- `Sources/MacBookNotchTracker/Core/Services/ServiceProtocols.swift`
- `Sources/MacBookNotchTracker/Core/Services/InMemoryPersistence.swift`
- `Sources/MacBookNotchTracker/Core/Session/SessionEngine.swift`
- `Sources/MacBookNotchTracker/App/AppContainer.swift`

## Exit Criteria

- both UI surfaces can call the same actions without branching logic
- summaries match raw session data
- app restarts preserve current and historical state correctly
- settings changes can be observed by both the notch and the dashboard

## Risks To Watch

- duplicated state between view models and services
- weak data modeling that blocks future analytics
- missing audit fields for edited or corrected sessions
