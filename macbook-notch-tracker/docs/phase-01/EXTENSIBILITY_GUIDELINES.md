# Extensibility Guidelines

## Goal

Ensure the app can grow without forcing major rewrites to core state, navigation, or interface structure.

## Architectural Principles

- keep feature logic separate from surface logic
- keep notch and dashboard as consumers of shared actions
- keep platform services behind replaceable interfaces
- prefer additive models and migrations over rigid schemas
- design features as modules, not scattered edits across the codebase

## Feature Module Shape

A future feature should ideally define:

- its own models or view models
- its own service layer or adapters
- its own dashboard section or settings subsection
- its own optional persistence fields
- its own command entry points routed through shared app actions

## Where New Features Should Go

### Belongs In Shared Core

- session state
- global settings
- app-wide command routing
- persistence contracts
- notification and integration interfaces

### Belongs In A Feature Module

- analytics
- exports
- tags and categories
- calendar integrations
- focus tools
- experiments or beta capabilities

### Belongs In The Notch

- only high-frequency, low-risk, compact actions
- glanceable status connected to active work

### Stays Out Of The Notch

- multi-step workflows
- destructive management
- dense filters
- configuration-heavy features
- advanced analytics

## Navigation Rules

- use one stable dashboard navigation model from the start
- allow new sections to register themselves into that model
- avoid special-case navigation for each new feature
- keep section naming concise and scannable

## Persistence Rules

- prefer additive schema changes
- preserve backward compatibility where possible
- record migration boundaries clearly
- avoid tightly coupling stored shape to a single screen layout

## UI Rules

- new modules should inherit shared cards, headers, spacing, and actions
- use status chips and secondary entry points before adding more notch controls
- preserve one primary action per region even as new features are added

## Delivery Rule

Before adding a new feature, answer these questions:

- Does this belong in shared core or in a feature module?
- Does it need notch presence, or only dashboard presence?
- Can it reuse an existing visual and interaction pattern?
- Can it be added without changing the session engine?
- Can it be disabled or removed without destabilizing the rest of the app?
