# Interaction Spec

## Goal

Define how the notch and dashboard behave before visual implementation begins.

## Access Paths

The app must be reachable through:

- notch hover trigger
- menu bar item
- keyboard shortcut
- dashboard reopen behavior after app launch

Hover improves convenience.

It does not replace standard access.

## Notch Reveal Behavior

### Trigger Region

- position a narrow invisible activation zone at the top center of the built-in display
- the region should be forgiving enough to hit intentionally without pixel-perfect movement
- the region should not interfere with standard menu bar usage

### Open Timing

- hover delay target: 100-140 ms
- reveal animation target: 180-220 ms
- use opacity and vertical offset only

### Close Timing

- pointer leaving the activation area alone should not close immediately if the pointer is moving into the notch surface
- close delay target: 180-260 ms
- if the pointer leaves the notch and no control holds focus, dismiss gracefully

### Persistence Rules

- keep the notch open while pointer is inside
- keep the notch open while a control inside has keyboard focus
- close when pointer leaves and focus is lost
- close immediately on Escape

## Notch State Behavior

### Idle

- primary emphasis on start action
- supporting text explains readiness
- no crowded historical data

### Running

- primary emphasis on stop action
- secondary actions for pause and break
- current timer remains the visual anchor

### Paused

- primary emphasis on resume action
- stop remains available but visually secondary

### Break

- primary emphasis on end break
- show break elapsed time
- optionally show last active task or session label

## Dashboard Behavior

### Window

- opens as a standard desktop window
- restores previous size and position
- should be fully usable without the notch
- should support additive sections without changing core window behavior

### Navigation

- use a simple left sidebar or segmented top navigation
- keep sections shallow in version 1
- keep current session information visible near the top of the overview
- choose a navigation structure that can grow to include future sections such as insights, exports, and integrations
- avoid navigation patterns that require redesign when new modules are added

### Editing

- session edits happen in context or in a focused sheet
- destructive actions require confirmation
- support undo for session deletion or correction when possible

## Feedback Rules

- every control press gets visible feedback within 100 ms
- loading or save actions should expose a visible busy or success state
- state changes should update both surfaces immediately
- feature-specific feedback should still use shared patterns for toasts, confirmation, and disabled states

## Keyboard And Accessibility

- Tab order should move logically across visible controls
- Escape closes the notch
- keyboard shortcut opens dashboard even when hover is unavailable
- VoiceOver labels should describe both action and current state where relevant

## Extensibility Interaction Rules

- new features should reuse existing action patterns before inventing new ones
- new notch-visible functionality should enter as passive status first, then become actionable only if usage justifies it
- feature modules with deep configuration should open in dashboard sections or sheets, not in the notch
- shared state changes must propagate to both surfaces through one action path

## Edge Cases

- if the built-in display is inactive, hide notch behavior and rely on fallback access
- if the dashboard is already open, the notch open action should focus the existing window instead of duplicating it
- if notifications are disabled, settings should clearly show that reminder behavior is limited
- if future modules are unavailable or disabled, the dashboard should hide or disable them cleanly without breaking the base navigation
