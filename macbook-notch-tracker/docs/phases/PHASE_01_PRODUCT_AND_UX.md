# Phase 1 - Product And UX Blueprint

## Objective

Turn the idea into a precise product definition before implementation starts.

This phase answers what belongs in the notch, what belongs in the dashboard, and how both surfaces stay coherent.

## Scope

- define the primary user flows
- list controls available in the notch
- list controls available in the dashboard
- define the data hierarchy for overview, history, and settings
- establish the design system and interaction rules
- define product-level growth rules so future features fit without redesigning the app shell

## Work Items

### Product Definition

- confirm the core app purpose and target user
- define the MVP feature set
- define non-goals to prevent scope creep
- define future expansion categories and how they attach to the product

### Interaction Mapping

- map the hover reveal behavior from trigger to dismiss
- define fallback access through menu bar and keyboard shortcut
- document the transition from notch action to dashboard action

### Information Architecture

- outline dashboard sections: overview, active session, history, insights, settings
- define which metrics appear in the notch versus the dashboard
- define editing and correction flows for logged sessions
- define a navigation model that can accept new sections later without rework

### Design System

- finalize semantic color tokens with no gradients
- choose type roles for timer, headings, labels, and dense data
- define corner radius, spacing scale, border opacity, and shadow rules
- lock the icon family to SF Symbols
- define rules for adding new cards, controls, and dashboard modules without visual drift

## Deliverables

- product brief
- control matrix for notch and dashboard
- low-fidelity wireframes
- visual style guide with color and typography tokens
- motion and interaction notes for hover, open, close, and state changes
- extensibility guidelines for future modules and sections

## Implementation Outputs

The first development pass for this phase is now captured in:

- `docs/phase-01/README.md`
- `docs/phase-01/PRODUCT_BRIEF.md`
- `docs/phase-01/CONTROL_MATRIX.md`
- `docs/phase-01/LOW_FIDELITY_WIREFRAMES.md`
- `docs/phase-01/DESIGN_SYSTEM.md`
- `docs/phase-01/INTERACTION_SPEC.md`
- `docs/phase-01/EXTENSIBILITY_GUIDELINES.md`

## Exit Criteria

- every core action has an assigned surface
- notch layout fits a compact width without crowding
- dashboard layout is approved at a structural level
- the visual language is clear enough to build without re-deciding basics later
- future modules have a defined place in navigation, commands, and styling rules

## Risks To Watch

- overloading the notch with too many controls
- making hover the only viable access path
- mixing decorative styling with utility-first goals
