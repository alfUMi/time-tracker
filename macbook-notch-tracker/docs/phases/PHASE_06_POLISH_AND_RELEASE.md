# Phase 6 - Polish And Release

## Objective

Refine the product until it feels reliable, accessible, and ready for daily use.

This phase converts a working app into a polished macOS utility.

## Scope

- improve accessibility and motion quality
- harden edge cases and hardware behavior
- tune performance
- prepare onboarding and release materials

## Work Items

### Quality And Accessibility

- verify VoiceOver labels and focus order
- verify reduced-motion behavior
- verify color contrast in light and dark appearances if both are supported
- ensure hover is never the only path to important features

### Edge Cases

- test multiple displays
- test lid-open and lid-closed scenarios on MacBook hardware
- test sleep, wake, app relaunch, and interrupted sessions
- define behavior when notifications are denied

### Performance

- keep overlay reveal responsive
- reduce unnecessary timer and query work
- test long history datasets for dashboard smoothness

### Release Preparation

- write onboarding copy
- prepare empty states and error states
- document known constraints
- package the app for internal testing or distribution

## Deliverables

- QA checklist
- edge-case handling notes
- onboarding content
- release candidate scope

## Exit Criteria

- critical flows work on supported MacBook hardware
- no blocker issues remain for notch reveal, dashboard access, or data integrity
- the app feels fast and visually cohesive
- first-run behavior is understandable without external explanation

## Risks To Watch

- late-stage hardware-specific bugs
- accessibility fixes being deferred too long
- packaging decisions changing too close to release
