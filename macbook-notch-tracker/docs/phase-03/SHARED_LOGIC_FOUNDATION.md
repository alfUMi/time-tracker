# Phase 3 Shared Logic Foundation

## Purpose

This phase replaces the placeholder app core with a shared logic layer that survives restarts and can serve both the notch and dashboard surfaces.

## What Changed

- session storage now persists a full snapshot, including the active session and completed history
- settings storage now uses local JSON files instead of in-memory placeholders
- session models now support codable persistence and additive growth
- the session engine now persists every transition
- summary, history, and chart queries now live in shared logic instead of views

## Persistence Model

### Session Snapshot

The session store now persists:

- `schemaVersion`
- `activeSession`
- `sessionHistory`

This keeps the app restart-safe and gives future migrations a clear entry point.

### Settings

Settings are stored separately so app preferences can evolve without coupling them to session history shape.

## Query Layer

The shared engine now exposes:

- summary queries for `day`, `week`, and `month`
- filtered history queries
- chart-point generation for future Swift Charts views

## Why This Matters

- the dashboard no longer needs to compute business logic directly
- the notch and dashboard continue to share one source of truth
- future modules such as analytics, exports, or tags can build on the same query layer
- persistence is structured for additive schema changes

## Next Build Steps

- add editing and correction workflows with audit metadata
- expand filtering beyond state and search text
- introduce real local persistence migrations if schema versions change
- wire live timer updates into the UI
- replace placeholder notification and launch-at-login services with real platform implementations
