# Product Brief

## Product Name

MacBook Notch Tracker

## Product Concept

MacBook Notch Tracker is a native macOS time-tracking utility designed around two complementary surfaces:

- a hover-activated notch interface for quick actions
- a full dashboard window for details, history, insights, and settings

The product keeps the speed of a lightweight utility while feeling premium and native to modern MacBook hardware.

## Problem

Time tracking tools often force users into one of two bad patterns:

- they are too hidden, so quick actions take too many steps
- they are too heavy, so the interface interrupts focus instead of supporting it

This product solves that by separating fast interaction from deep management.

The notch handles immediate actions.

The dashboard handles context, correction, and analysis.

## Target User

Primary user:

- solo MacBook user
- works in focused sessions
- wants quick access without leaving the current task
- values design quality and native-feeling interactions

Secondary user:

- productivity-minded user who wants clear session history
- wants reminders, summaries, and easy corrections

## Core Value Proposition

Track work with almost no friction.

Open the notch, control the current session instantly, then open the dashboard only when deeper review or setup is needed.

## Product Principles

- fast before feature-heavy
- calm and premium instead of flashy
- native macOS feel over novelty
- hover can enhance access, but never be the only path
- data must feel trustworthy and editable
- future features must attach to stable architecture instead of forcing full-surface rewrites

## MVP Features

- one active session at a time
- start, stop, pause, resume, and break controls
- hover-triggered notch access on the built-in display
- dashboard with current session, history, and summary views
- local persistence for sessions and settings
- launch at login
- reminders and notifications
- menu bar and keyboard fallback access

## Extensibility Direction

The app should be built as a long-lived product, not as a one-off utility shell.

That means:

- the current tracker feature set is the first module, not the final shape of the app
- future capabilities should plug into shared state, navigation, and persistence contracts
- the notch stays compact even as the dashboard grows
- new dashboard sections should be additive, not disruptive

Examples of future modules:

- tags and categories
- richer analytics
- export tools
- calendar or focus integrations
- widgets or companion surfaces

## Non-Goals

- collaboration
- cloud sync
- team reporting
- plugin ecosystem
- excessive theming

## Main Surfaces

### Notch Surface

Purpose:

- instant control
- glanceable status
- low-friction navigation into the dashboard

Success criteria:

- opens quickly
- never feels crowded
- exposes only the highest-frequency actions
- remains compact even when future capabilities are added elsewhere in the product

### Dashboard Surface

Purpose:

- trusted record of time
- detailed review
- settings and system behavior management

Success criteria:

- easy to scan
- easy to edit
- clearly more capable than the notch without duplicating all of its compactness constraints
- structured so new sections can be added without redesigning the whole window

## User Stories

- As a user, I want to start a session from the notch in one action.
- As a user, I want to see my current timer without opening a large window.
- As a user, I want to pause or start a break from the same quick surface.
- As a user, I want to open a full dashboard when I need history or settings.
- As a user, I want both surfaces to stay in sync so I trust the current state.
- As a user, I want a keyboard or menu bar fallback if hover is inconvenient.

## Success Metrics

- time to start a session from idle stays under 2 seconds
- most common controls are accessible from the notch without opening the dashboard
- users can understand current state within 1 glance
- history corrections take place inside the dashboard without confusion

## Open Product Questions

- Should the notch allow quick task labeling in MVP, or only show the active task?
- Should pause and break both exist in MVP, or should break cover both needs?
- Should the dashboard use a sidebar layout or a single-scroll overview layout in version 1?
- Which future module categories should be reserved in the dashboard navigation from the beginning?
