# MacBook Notch Tracker - Project Plan

## Product Summary

Build a native macOS app that reimagines the current tracker as a premium MacBook utility.

The app has two primary surfaces:

- a hover-activated notch interface that appears when the user moves the pointer to the top center of the built-in display
- a dashboard window that opens on demand and exposes full details, history, configuration, and advanced controls

The notch surface is the fast-control layer.

The dashboard is the detail and management layer.

## Working Assumption

This plan assumes the app remains focused on personal time tracking and work-session management.

Core interactions should support:

- starting and stopping a session
- pausing or taking a break
- seeing current status at a glance
- reviewing session history and totals
- adjusting app behavior from either the notch or the dashboard

## Product Goals

- Create a native-feeling macOS experience instead of a VS Code extension workflow.
- Make the notch interaction fast, discoverable, and elegant without feeling gimmicky.
- Keep essential controls available in both the notch surface and the dashboard.
- Present data in a calm, modern interface with strong contrast and solid colors.
- Support a daily workflow where quick actions happen in the notch and deeper management happens in the dashboard.
- Establish a modular architecture from day one so new features can be added without restructuring the whole app.

## Extensibility Goals

- Keep domain logic independent from any single surface so new surfaces can reuse the same actions and data.
- Design dashboard navigation to accept new sections without reworking the entire window.
- Reserve clear extension points for future modules such as analytics, tags, exports, widgets, and integrations.
- Keep settings and persistence models migration-friendly so new fields can be introduced safely.
- Avoid coupling hover, overlay, storage, and session logic together.

## Non-Goals For The First Version

- iPhone, iPad, or Apple Watch companions
- cloud sync or multi-device collaboration
- team management or shared workspaces
- heavy customization of layout themes
- AI features or automation beyond lightweight smart suggestions

## Experience Model

### 1. Notch Surface

The notch surface acts like a compact command center.

Expected content:

- current session state
- elapsed timer
- quick start, stop, pause, and break controls
- current task or label
- one-tap entry to the dashboard
- short status chips for today totals or pending reminders

Expected behavior:

- hidden by default
- revealed by hover in the top-center trigger region
- stays open briefly while the pointer is inside the surface
- closes gracefully when the pointer leaves
- supports keyboard focus and click interactions, not hover only

### 2. Dashboard Window

The dashboard is the full management surface.

Expected sections:

- overview
- current session
- history and timeline
- daily, weekly, and monthly summaries
- manual corrections or edits
- preferences and system integration settings

Expected controls:

- session actions duplicated from the notch
- filters for date range and session type
- edit and delete actions for logged sessions
- toggles for launch behavior, notifications, reminders, and hover reveal behavior

## Design Direction

### Visual Style

- native macOS feel with custom polish
- minimal, premium, and information-forward
- no gradients
- restrained use of materials and blur
- rounded geometry, thin borders, subtle depth, and crisp typography

### Suggested Palette

- canvas: `#111315`
- surface: `#181C20`
- elevated surface: `#20262B`
- primary text: `#F3F5F7`
- secondary text: `#9CA7B3`
- accent blue: `#4C8DFF`
- accent mint: `#31C48D`
- accent amber: `#F5B942`
- accent red: `#F05D5E`
- border: `rgba(255, 255, 255, 0.10)`

### Typography And Icons

- use SF Pro Text and SF Pro Display where system typography is appropriate
- use SF Mono or tabular numerals for timers and dense metrics
- use SF Symbols consistently for controls and state indicators
- avoid mixed icon families

### Interaction Principles

- reveal should feel intentional and smooth, not flashy
- important actions should remain one click away
- hover can open the notch, but keyboard and click paths must exist too
- all motion should stay in the 150ms to 250ms range where possible
- state changes should be obvious through color, icon, and text together

## Recommended Technical Stack

- language: Swift
- UI layer: SwiftUI
- windowing and overlay behavior: AppKit bridges where SwiftUI alone is not enough
- persistence: SwiftData or SQLite-backed local storage
- charts and dashboards: native Swift Charts
- app state: Observation-based shared state with a small service layer
- notifications: UserNotifications
- launch control: LaunchAtLogin or equivalent native startup integration

## Proposed Architecture

### App Layers

1. `AppShell`

- app lifecycle
- menu bar presence
- window and scene registration
- launch-at-login and startup behavior

2. `OverlayEngine`

- top-center hover detection
- notch panel presentation and dismissal
- multi-display coordination
- pointer tracking and open/close timing

3. `SessionEngine`

- current session state machine
- start, stop, pause, and break flow
- elapsed time updates
- validation around overlapping sessions

4. `DataStore`

- persistence of sessions, tags, tasks, and settings
- queries for dashboard summaries
- export-ready data formatting

5. `DashboardModule`

- overview cards
- trends and charts
- history list
- settings and controls

6. `DesignSystem`

- semantic colors
- typography tokens
- icon rules
- spacing, corner radius, border, and shadow tokens

7. `FeatureModules`

- self-contained modules for future capabilities such as insights, exports, integrations, widgets, and automation
- each module owns its UI models, commands, and persistence needs behind shared contracts

### Architectural Rules

- Keep business logic in services and domain models, not inside SwiftUI views.
- Route user actions through shared commands so notch and dashboard never implement separate behavior.
- Use protocols for storage, notifications, and integrations so implementations can change without rewriting feature code.
- Keep each feature in its own module or folder with clear boundaries around models, services, and views.
- Treat the notch and dashboard as clients of shared application state, not as owners of it.

### Planned Extension Points

#### Command Layer

- shared action handlers for session, settings, reminders, and future feature commands
- supports adding features without duplicating control logic across surfaces

#### Navigation Layer

- dashboard sections should be defined from a lightweight registry or configuration model
- allows new sections such as `Insights`, `Exports`, or `Integrations` to be added cleanly

#### Persistence Layer

- models should support versioning and migration
- optional fields and additive schemas should be preferred for future expansion

#### Integration Layer

- define boundaries for notifications, launch-at-login, calendar, shortcuts, and future external hooks
- isolate platform services from the core session engine

## Functional Scope

### MVP

- local-only data storage
- one active session at a time
- notch hover reveal
- quick controls inside notch
- dashboard with overview, history, and settings
- lightweight reminders and notifications
- launch at login
- modular internal structure for future sections and services

### Version 1.1 Candidates

- task categories and labels
- richer analytics
- keyboard shortcuts
- export to CSV
- session editing with undo support

### Later Candidates

- sync
- focus mode integrations
- calendar awareness
- widgets or menu bar extensions

## Main Risks

### Hover Detection Risk

Hover behavior around the notch area is not a standard first-class app pattern on macOS.

Mitigation:

- implement the hover trigger using a carefully positioned invisible activation region
- provide a fallback activation path through a menu bar item and keyboard shortcut
- test across MacBook models and display scale settings

### Windowing Complexity

The app needs both lightweight overlay behavior and a full dashboard scene.

Mitigation:

- keep overlay and dashboard scenes separate
- centralize state in shared services
- bridge to AppKit only for window behavior that SwiftUI cannot handle reliably

### Multiple Display Behavior

The notch only exists on the built-in display, while the user may work on external monitors.

Mitigation:

- anchor the notch trigger to the built-in display only
- keep dashboard opening available regardless of active display
- define clear behavior when the MacBook lid is closed or the internal display is inactive

## Delivery Phases

### Phase 1 - Product And UX Blueprint

Define workflows, information architecture, control inventory, design tokens, and growth rules for future features.

### Phase 2 - App Foundation

Stand up the native app shell, scenes, window management, system integrations, and modular feature boundaries.

### Phase 3 - Shared Logic

Implement tracking state, persistence, settings, service boundaries, and extension-friendly contracts.

### Phase 4 - Notch Experience

Build the hover-triggered overlay, quick interactions, and compact status presentation.

### Phase 5 - Dashboard Experience

Build the detailed dashboard, charts, history tools, and mirrored control surface.

### Phase 6 - Polish And Release

Harden performance, accessibility, onboarding, QA, and packaging.

## Definition Of Success

- The notch surface opens reliably and feels fast on supported MacBook hardware.
- Users can complete their most common actions from the notch in seconds.
- The dashboard provides a clear, trustworthy view of tracked time and settings.
- The app looks modern and premium without relying on gradients or decorative excess.
- The architecture remains modular enough to evolve beyond the current tracker feature set.
- Adding a new dashboard section or service should not require rewriting the notch or core session engine.
