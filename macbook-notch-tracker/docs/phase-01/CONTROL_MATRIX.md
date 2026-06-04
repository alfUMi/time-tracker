# Control Matrix

## Principle

Controls appear in both surfaces when they are high-frequency or state-critical.

The notch is optimized for immediacy.

The dashboard is optimized for completeness.

Future features should default to the dashboard unless they are frequent enough, safe enough, and compact enough to deserve notch placement.

## Shared Controls

| Control | Notch | Dashboard | Notes |
|---|---|---|---|
| Start session | Yes | Yes | Primary action when idle |
| Stop session | Yes | Yes | Primary action when running |
| Pause session | Yes | Yes | Available when running |
| Resume session | Yes | Yes | Available when paused |
| Start break | Yes | Yes | Available when running |
| End break | Yes | Yes | Available when on break |
| Open dashboard | Yes | N/A | Secondary action in notch |
| Open from menu bar | Indirect | Indirect | Fallback access path |
| Keyboard shortcut launch | Indirect | Indirect | Fallback access path |

## Notch-Only Or Notch-Priority Controls

| Control | Why It Belongs Here |
|---|---|
| Current timer glance | Highest-frequency information |
| Current state chip | Must be readable in one glance |
| Quick current task display | Useful without taking extra space if short |
| Small today summary chips | Helpful context without deep navigation |

## Dashboard-Primary Controls

| Control | Why It Belongs Here |
|---|---|
| Session history editing | Requires more space and confirmation |
| Delete or correct session | Potentially destructive |
| Date range filters | Better suited to a full window |
| Charts and summaries | Requires richer layout |
| Settings and preferences | Low-frequency but high-importance |
| Notification and launch behavior | System-level controls belong in full settings |

## Future Feature Placement Rules

| Feature Type | Default Surface | Promotion Rule |
|---|---|---|
| Analytics and reports | Dashboard | Never move full analytics into notch |
| Integrations | Dashboard | Surface only status or shortcut entry in notch |
| Tags, projects, metadata | Dashboard | Show active value in notch only if compact |
| Exports and automation | Dashboard | Keep out of notch unless a single safe shortcut emerges |
| Experiments or beta tools | Dashboard | Graduate to shared controls only after usage proves it |

## Surface Rules

### Notch Rules

- maximum one primary action at a time
- no more than 4 direct action controls visible in the compact row
- destructive or risky actions stay out of the notch
- text should be short enough to avoid wrapping in the compact layout
- future features should prefer status chips or entry points over adding more direct controls

### Dashboard Rules

- current session controls remain visible without scrolling too far
- destructive actions require confirmation
- edit flows should support undo where possible
- filters and settings should use full labels, not icon-only affordances
- new modules should appear as additive sections, not as bespoke floating panels with their own navigation model

## State-Based Visibility

| State | Primary Notch Action | Secondary Notch Actions | Dashboard Highlight |
|---|---|---|---|
| Idle | Start | Open dashboard | Empty-state guidance |
| Running | Stop | Pause, Break, Open dashboard | Current session panel |
| Paused | Resume | Stop, Open dashboard | Resume-focused current session card |
| On break | End break | Stop, Open dashboard | Break state with elapsed break time |

## Accessibility Notes

- every icon-only control must have a text label or accessibility label
- hover reveal cannot be the only way to reach a control
- keyboard focus order should match visual order
- current state must be communicated through text and icon, not color alone

## Growth Guardrails

- adding a new feature should not push the notch beyond its compact layout rules
- if a feature introduces multi-step flow, it belongs in the dashboard
- if a feature is destructive, administrative, or low-frequency, it belongs in the dashboard
- if a feature only needs glanceable status, expose a chip or summary before exposing a new control
