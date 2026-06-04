# Design System

## Design Intent

The interface should feel like a polished native macOS utility:

- minimal
- premium
- readable
- solid-color driven
- calm rather than decorative

No gradients are used.

## Visual Personality

- near-black canvas
- layered surfaces with subtle separation
- one clean accent per meaning
- sharp iconography
- tabular timing and metrics
- restrained motion

## Color Tokens

### Core Surfaces

| Token | Value | Usage |
|---|---|---|
| `color.canvas` | `#111315` | App background |
| `color.surface` | `#181C20` | Standard cards and panels |
| `color.surfaceRaised` | `#20262B` | Hovered or prioritized surfaces |
| `color.surfaceMuted` | `#15191D` | Secondary group backgrounds |
| `color.border` | `rgba(255, 255, 255, 0.10)` | Default borders and dividers |

### Text

| Token | Value | Usage |
|---|---|---|
| `color.textPrimary` | `#F3F5F7` | Main text |
| `color.textSecondary` | `#9CA7B3` | Secondary text |
| `color.textMuted` | `#6F7A86` | Quiet labels and helper text |

### Semantic Accents

| Token | Value | Usage |
|---|---|---|
| `color.accentBlue` | `#4C8DFF` | Primary action and active state |
| `color.accentMint` | `#31C48D` | Positive status and success |
| `color.accentAmber` | `#F5B942` | Pause and warning |
| `color.accentRed` | `#F05D5E` | Stop, delete, destructive actions |

## Typography

### Families

- `SF Pro Display` for large headings
- `SF Pro Text` for body and labels
- `SF Mono` or tabular figures for timers, metrics, and durations

### Roles

| Role | Suggested Style |
|---|---|
| Hero timer | 32-40 pt, semibold, monospaced digits |
| Section title | 20-24 pt, semibold |
| Card title | 14-16 pt, semibold |
| Body | 13-15 pt, regular |
| Metadata | 11-12 pt, medium |

## Spacing

Use an 8-point rhythm.

| Token | Value |
|---|---|
| `space.4` | 4 |
| `space.8` | 8 |
| `space.12` | 12 |
| `space.16` | 16 |
| `space.24` | 24 |
| `space.32` | 32 |

## Corner Radius

| Token | Value | Usage |
|---|---|---|
| `radius.sm` | 8 | Small chips and compact controls |
| `radius.md` | 12 | Standard cards and fields |
| `radius.lg` | 16 | Larger panels and grouped surfaces |
| `radius.pill` | 999 | Chips and segmented controls |

## Border And Elevation

- use thin borders before heavy shadows
- use shadows only to separate active or floating surfaces
- avoid layered blur effects that reduce contrast

Suggested elevation model:

- base surface: no shadow, 1 px border
- raised surface: soft vertical shadow with low opacity
- overlay surface: slightly stronger shadow plus border

## Iconography

- use SF Symbols only
- keep stroke/weight consistent by hierarchy
- prefer outline icons for neutral actions
- use filled state only when it adds meaning

## Component Guidance

### Buttons

- one primary filled button per screen region
- secondary buttons use subtle borders
- danger buttons use red, but not as the default primary emphasis

### Chips

- use small rounded pills for state and short summaries
- pair icon and text when possible

### Cards

- group related content in cards with generous padding
- avoid excessive nested cards inside cards

### Section Containers

- dashboard sections should share one structural pattern so future modules can slot in without bespoke chrome
- section headers should support title, subtitle, and trailing actions in a consistent layout
- new modules should inherit the same spacing, radius, and border tokens as core modules

### Charts

- prefer bar and line charts
- keep fills solid
- keep grid lines subtle
- use accessible color contrast and direct labels when possible

## Motion

- standard transitions: 150-220 ms
- open/close transitions: 180-240 ms
- use opacity and transform instead of size animation
- reduced motion must remove bounce and long travel

## Accessibility Rules

- meet contrast targets for text and controls
- do not rely on color alone for state
- keep interactive targets at least 44 x 44 points
- preserve full keyboard access to all core controls
- ensure hover-triggered UI has fallback access paths

## Growth Rules

- add new visual patterns only when an existing component pattern cannot support the new use case
- keep semantic tokens generic enough to support future modules beyond time tracking
- prefer reusable section, card, chip, and toolbar primitives over one-off styling
- future dashboard modules should look related through shared spacing and hierarchy, not custom decoration

## Anti-Patterns

- gradients
- glowing neon effects
- mixed icon families
- dense toolbars with unclear priority
- decorative animation that slows quick actions
