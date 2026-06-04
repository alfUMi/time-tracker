# Dynamic Island Full Rewrite Report

## Scope

This document follows the mandatory first step from `plans/dynamic-island.md`.

It does not propose incremental fixes.

It treats the current Dynamic Island system as failed and identifies what must be deleted and what must replace it.

No replacement source implementation is introduced in this step.

## Executive Summary

The current Dynamic Island implementation is still architecturally incompatible with the required result.

Even after the recent top-strip rewrite, the system still fails the new hard requirements because it:

- uses hardcoded geometry
- approximates notch behavior instead of inheriting notch geometry
- renders a pill-like closed state instead of an actual notch-like silhouette
- uses a detached overlay rendering plane that remains conceptually separate from the notch
- swaps semantic states through different framed layouts instead of continuously morphing one geometry engine

Under the new plan, this means the current island system must be deleted and rebuilt from scratch.

## Current System Review

### Current Window System

The active island window system lives in [OverlayPreviewController.swift](file:///Users/envis/projects/time-tracker/macbook-notch-tracker/Sources/MacBookNotchTracker/Platform/Windowing/OverlayPreviewController.swift).

It currently uses:

- a dedicated transparent borderless `NSWindow`
- a top-strip overlay window spanning the upper screen area
- a persistent SwiftUI renderer hosted in `NSHostingView`

This is better than the earlier floating panel, but it still fails the new requirements.

Why:

- the overlay remains an independent detached rendering surface
- the notch is still simulated within that surface
- the island does not literally inherit the physical notch geometry

Under the new spec, the user must initially believe they are looking at the notch itself.

The current system still looks like software drawn in the notch area.

### Current Positioning System

The current geometry engine lives in [NotchGeometry.swift](file:///Users/envis/projects/time-tracker/macbook-notch-tracker/Sources/MacBookNotchTracker/Platform/Windowing/NotchGeometry.swift).

It computes:

- `topStripFrame`
- `anchorX`
- `closedLayout`
- `compactLayout`
- `expandedLayout`

This is currently derived from:

- `screen.frame`
- `screen.safeAreaInsets.top`
- hardcoded sizes
- hardcoded top offsets
- hardcoded hover sizes
- hardcoded corner radii

This directly violates the new requirements:

- hardcoded offsets are forbidden
- hardcoded coordinates are forbidden
- magic numbers are forbidden

The current system is therefore architecturally disqualified by the plan itself.

### Current Notch Geometry

The closed state is currently rendered by [NotchPreviewView.swift](file:///Users/envis/projects/time-tracker/macbook-notch-tracker/Sources/MacBookNotchTracker/Features/Notch/NotchPreviewView.swift).

Its closed state is effectively:

- a rounded black capsule
- with a soft highlight strip
- centered inside the overlay

This fails the notch requirements because the closed state must:

- touch the top edge of the display
- have no visible gap
- have no floating effect
- not be a capsule
- not be a pill shape

The current closed state is explicitly a pill-like software object.

That alone means the current renderer cannot be kept.

### Current Animation Behavior

The system uses state-based layout switching:

- hidden
- closed
- compact
- expanded

The island view remains persistent, but the renderer still changes between different framed layouts and content configurations.

Why this fails:

- it is still layout switching, not true shape interpolation
- width, height, and corner radius are switched from state snapshots
- content visibility is state-dependent rather than mask-driven and geometry-driven

The plan requires a dedicated shape system with continuous morphing.

The current implementation still behaves like a software component transitioning between view presets.

### Current Notch Integration Failure

The current system treats the notch as a reference point.

The new plan requires the notch to be the object itself.

That difference is critical.

Current behavior:

- find built-in display
- compute center anchor
- place software island at that anchor

Required behavior:

- derive the closed shape from notch geometry
- preserve that exact top edge and silhouette
- morph that exact geometry into compact and expanded island states

The current system does not have a true notch silhouette model.

Therefore it cannot make the notch appear interactive.

## Architectural Decisions That Cause Failure

### 1. Detached Overlay Plane

The overlay is still its own surface.

Why it fails:

- the island is rendered onto a software layer that exists independently of the notch
- the user can still perceive a software object occupying the notch region

Effect:

- detached overlay feeling
- software-first perception

### 2. Hardcoded Geometry Tables

`NotchGeometryResolver` uses fixed constants for:

- sizes
- top offsets
- hover regions
- corner radii

Why it fails:

- geometry is not derived from notch structure
- it is derived from guessed dimensions

Effect:

- incorrect closed state
- incorrect alignment
- fake notch behavior

### 3. Capsule-Based Closed State

The closed renderer uses a rounded rectangle / capsule-like body.

Why it fails:

- the physical MacBook notch is not a pill floating below the screen edge
- it is fused into the top edge of the display

Effect:

- immediate software appearance
- user instantly distinguishes the island from the notch

### 4. Snapshot State Rendering

The current system selects from state-specific snapshots and layouts.

Why it fails:

- the plan explicitly forbids component replacement and requires geometry morphing

Effect:

- transitions feel like UI state changes instead of notch transformation

### 5. Approximate Anchor Model

The notch is modeled as:

- built-in screen center
- safe area inset
- guessed strip depth

Why it fails:

- that is not notch geometry
- it is only a convenient approximation

Effect:

- no guarantee that the top edge truly fuses with the notch
- no guarantee that the closed state is indistinguishable from hardware

### 6. Software Interaction Region

The hover and click regions are still explicit transparent regions in the overlay.

Why it fails:

- interaction belongs to software rectangles, not to notch-derived geometry

Effect:

- hidden software box behavior
- detached overlay semantics

## Components That Must Be Deleted

The following components should be deleted entirely, not adapted.

### `Sources/MacBookNotchTracker/Platform/Windowing/OverlayPreviewController.swift`

Why delete it:

- it owns the current detached overlay architecture
- it still treats the island as content on a software window plane
- it hardwires a top-strip overlay strategy that is still approximation-based

What replaces it:

- `IslandSceneController`
- `IslandSurfaceWindowController`
- `DisplaySceneRegistry`

### `Sources/MacBookNotchTracker/Platform/Windowing/NotchGeometry.swift`

Why delete it:

- it is built entirely around magic numbers
- it defines fake notch-like layouts rather than deriving a notch silhouette

What replaces it:

- `NotchShapeModel`
- `NotchShapeResolver`
- `IslandGeometryEngine`
- `IslandMorphLayout`

### `Sources/MacBookNotchTracker/Features/Notch/NotchPreviewView.swift`

Why delete it:

- closed state is visibly a software pill
- it renders discrete software states
- it does not render a notch-derived silhouette

What replaces it:

- `IslandRendererView`
- `IslandShapeRenderer`
- `IslandContentMaskLayer`

### `Sources/MacBookNotchTracker/Features/Notch/NotchOverlayCoordinator.swift`

Why delete it:

- it models presentation state transitions only
- it does not own geometric morph semantics
- it does not model notch identity or outside-click collapse behavior robustly enough for the new system

What replaces it:

- `IslandStateMachine`
- `IslandInteractionController`
- `IslandIdleController`

### `Sources/MacBookNotchTracker/Core/Services/ServiceProtocols.swift`

Delete specifically:

- `OverlayPresentationState`
- `OverlayControlling`

Why delete them:

- they encode the old overlay abstraction
- they are too shallow for a full island scene system

What replaces them:

- `IslandSceneState`
- `IslandSceneControlling`
- `IslandLayoutSnapshot`
- `IslandRuntimeContext`

### `Sources/MacBookNotchTracker/App/AppContainer.swift`

Delete specifically:

- current island synchronization path
- current overlay controller wiring

Why delete them:

- the container should not directly map app state into overlay implementation details
- it should publish intent, not control scene topology

What replaces them:

- `IslandSystem` registered as a dedicated subsystem
- container only publishes app/session state and high-level user intents

### `Sources/MacBookNotchTracker/App/MacBookNotchTrackerApp.swift`

Delete specifically:

- overlay installation from dashboard `.task`

Why delete it:

- island scene lifecycle should not depend on dashboard composition

What replaces it:

- dedicated app bootstrap that starts island services before user-facing scenes render

## Full Replacement Architecture

## 1. Window Architecture

### Goal

Use a rendering surface that is never perceived as a window.

### New Components

- `IslandSurfaceWindowController`
- `IslandSurfaceWindow`
- `DisplaySceneRegistry`

### Design

- Create one borderless transparent surface window for each supported target display.
- The surface window is fixed to the top display edge.
- The surface window is not the visible object.
- The surface window never visually expands or collapses.
- It only hosts a geometry-driven compositor layer.

### Important Difference From Current System

The current system uses a software top strip plus a software island inside it.

The new system uses a stable invisible surface and one morphing notch-derived object.

## 2. Geometry Architecture

### Goal

Replace hardcoded layout snapshots with a real notch geometry engine.

### New Components

- `NotchShapeModel`
- `NotchShapeResolver`
- `IslandGeometryEngine`
- `IslandMorphGeometry`

### Design

The engine should produce:

- `notchClosedShape`
- `compactShape`
- `expandedShape`
- hit regions
- content masks
- anchor points

Every geometry output must be derived from:

- active display
- menu bar region
- top edge
- notch position

The closed shape must literally share the same top-edge attachment model as the physical notch.

No guessed pill geometry is allowed.

## 3. Rendering Architecture

### Goal

Render one persistent object that appears to be the notch.

### New Components

- `IslandRendererView`
- `IslandShapeRenderer`
- `IslandContentRenderer`
- `IslandMaskRenderer`

### Design

- Keep one renderer alive at all times.
- The closed state draws the notch-derived shape only.
- The compact and expanded states morph the same shape object.
- Content is clipped and revealed by geometry masks instead of swapping separate views.

### Forbidden Patterns

- one view for closed
- another view for compact
- another view for expanded
- replacing the object during transitions

## 4. Animation Architecture

### Goal

Animate shape evolution, not UI appearance.

### New Components

- `IslandMorphAnimator`
- `IslandTransitionState`
- `IslandSpringProfile`

### Design

Animate:

- outline control points
- width
- height
- curvature
- content mask bounds
- inner layout offsets

Do not animate:

- software panel reveal
- card drop
- sheet open
- popup fade

The animation must read as physical transformation of the notch silhouette.

## 5. Interaction Architecture

### Goal

Make the island spend most of its time in notch state and respond subtly.

### New Components

- `IslandInteractionController`
- `IslandHoverController`
- `IslandOutsideClickController`
- `IslandIdleTimeoutController`

### Design

Hover:

- slight response
- optional compact state

Click:

- expand from the existing notch shape

Outside click:

- collapse back to notch

Idle timeout:

- collapse back to notch

Interaction regions must be derived from notch geometry, not arbitrary transparent rectangles.

## 6. App Integration Architecture

### Goal

Keep the island system independent from dashboard scene lifecycle.

### New Components

- `IslandSystem`
- `IslandSceneBootstrapper`
- `IslandStatePublisher`

### Design

- App bootstrap creates the island system early.
- Dashboard and menu bar publish commands and session updates.
- Island runtime consumes state and interaction intent.
- Window lifecycle is not owned by the dashboard scene.

## Validation Against The New Plan

The current implementation fails these checks:

1. Does the closed state touch the top edge of the display?
   - No, not in a true notch-derived way.
2. Does the closed state visually match the notch?
   - No, it is a software pill.
3. Can the user distinguish the notch from the software?
   - Yes, immediately.
4. Does expansion originate from the notch?
   - Only approximately, not geometrically.
5. Does the island spend most of its time collapsed?
   - Partially, but the collapsed state is still incorrect.
6. Does any part of the UI resemble a floating panel?
   - Yes, conceptually and visually it remains a detached software object.

## Final Decision

The current Dynamic Island subsystem must be deleted.

It should not be improved.

It should not be refactored.

It should not be tuned.

It should be replaced with a new system built around:

- a stable invisible rendering surface
- a notch-derived geometry engine
- a single persistent shape renderer
- continuous geometric morphing
- interaction and collapse behavior centered on notch identity

Only after this deletion-level redesign is accepted should replacement source code be written.
