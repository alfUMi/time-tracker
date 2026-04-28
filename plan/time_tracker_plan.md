# VSCode Time Tracker Extension — Development Plan

## Overview

Build a Visual Studio Code extension for tracking work time and break time directly inside the editor. The extension includes a React-powered dashboard panel styled with Tailwind CSS, configurable schedules, manual and automatic timer control, and a smart idle detection system.

---

## Tech Stack

- **Language:** TypeScript
- **Runtime:** Node.js (VSCode Extension Host)
- **UI:** VSCode Webview API + **React** + **Tailwind CSS** (bundled via Vite)
- **Charting:** Recharts (inside React webview)
- **Storage:** VSCode `globalState` + JSON file via `globalStorageUri` for persistent statistics
- **Extension API:** `vscode.window`, `vscode.workspace`, `vscode.commands`, `vscode.StatusBarItem`

---

## Project Structure

```
vscode-time-tracker/
├── src/
│   ├── extension.ts                # Entry point, extension activation
│   ├── tracker/
│   │   ├── TimerEngine.ts          # Core timer state machine
│   │   ├── BreakManager.ts         # Break control and reminders
│   │   ├── IdleDetector.ts         # Editor activity monitoring
│   │   └── ScheduleManager.ts      # Scheduled start/stop logic
│   ├── storage/
│   │   ├── StorageService.ts       # Storage abstraction layer
│   │   └── models.ts               # Data types: TimeSegment, DayRecord, Settings
│   ├── ui/
│   │   ├── DashboardPanel.ts       # Webview host panel (extension side)
│   │   └── StatusBar.ts            # Status bar item
│   └── notifications/
│       └── NotificationService.ts  # VSCode notification wrappers
├── webview-ui/                     # React app (compiled separately)
│   ├── src/
│   │   ├── main.tsx                # React entry point
│   │   ├── index.css               # Tailwind v4 entry: @import "tailwindcss", @theme tokens, @layer base
│   │   ├── App.tsx                 # Root component, message routing
│   │   ├── components/
│   │   │   ├── StatusPanel.tsx     # Current state + control buttons
│   │   │   ├── StatsPanel.tsx      # Day/Week/Month statistics
│   │   │   ├── StatsChart.tsx      # Recharts bar chart
│   │   │   ├── SessionTable.tsx    # Sessions list with timestamps
│   │   │   └── SettingsPanel.tsx   # Settings form
│   │   ├── hooks/
│   │   │   ├── useVSCodeMessage.ts # Receives messages from extension
│   │   │   └── useTimerState.ts    # Local timer state derived from messages
│   │   └── types.ts                # Shared types mirrored from models.ts
│   ├── package.json
│   ├── vite.config.ts
│   └── tsconfig.json
├── package.json
├── tsconfig.json
└── README.md
```

---

## Data Models

```typescript
// src/storage/models.ts

interface TimeSegment {
  start: number;          // Unix timestamp ms
  end: number | null;     // null if currently active
  type: "work" | "break" | "idle";  // idle segments are excluded from stats
}

interface DayRecord {
  date: string;           // "YYYY-MM-DD"
  segments: TimeSegment[];
}

interface Settings {
  scheduleStart: string | null;      // "09:00" or null
  scheduleStop: string | null;       // "18:00" or null
  breakReminderEnabled: boolean;
  breakReminderIntervalMin: number;  // e.g. 60 minutes
  idleThresholdMin: number;          // e.g. 5 minutes
}

type TimerState = "idle" | "working" | "on_break" | "extended";

// Messages passed from extension host to React webview
type WebviewMessage =
  | { type: "stateUpdate"; state: TimerState; elapsed: number }
  | { type: "statsData"; period: "day" | "week" | "month"; records: DayRecord[] }
  | { type: "settingsData"; settings: Settings };

// Messages passed from React webview to extension host
type ExtensionMessage =
  | { type: "start" }
  | { type: "stop" }
  | { type: "startBreak" }
  | { type: "endBreak" }
  | { type: "extend" }
  | { type: "requestStats"; period: "day" | "week" | "month" }
  | { type: "saveSettings"; settings: Settings };
```

---

## Modules

### 1. TimerEngine

Central state machine for timer management.

**States:**
- `idle` — timer is not running
- `working` — active work session in progress
- `on_break` — break in progress
- `extended` — work extended beyond scheduled stop; no planned end time

**Methods:**
- `start()` — begin a work session
- `stop()` — stop the session manually
- `startBreak()` — begin a break
- `endBreak()` — end the break and resume working
- `extendWork()` — cancel the scheduled stop and switch to `extended` mode
- `markIdle(from: number, to: number)` — record an idle segment (called by IdleDetector)

**Events (EventEmitter):**
- `onStateChange(state: TimerState)` — emitted on any state transition
- `onTick(elapsed: number)` — emitted every second while active, for UI updates
- `onScheduledStop()` — emitted when the scheduled stop time is reached

---

### 2. ScheduleManager

Handles automatic start and stop based on the configured schedule.

**Behavior:**
- Reads `settings.scheduleStart` and `settings.scheduleStop`
- Sets `setTimeout` calls aligned to the current day for auto-start and auto-stop
- On `scheduleStop` trigger: fires `TimerEngine.onScheduledStop`
- If the user clicks "Extend": cancels the stop timeout and transitions `TimerEngine` to `extended` mode
- In `extended` mode there is no planned stop — only manual stop or idle-triggered stop

---

### 3. IdleDetector

Monitors editor activity and detects inactivity. **Only active when TimerEngine is in `extended` mode.**

**Tracked VSCode events:**
- `vscode.workspace.onDidChangeTextDocument` — file edits
- `vscode.window.onDidChangeActiveTextEditor` — editor tab switches
- `vscode.window.onDidChangeTextEditorSelection` — cursor movements

**Algorithm:**
1. On every editor event, reset `idleTimer` to `idleThresholdMin` minutes
2. If `idleTimer` expires, record `idleStart = now`
3. On the next editor event after the timer has expired:
   - If elapsed time is less than the threshold — ignore (spurious gap)
   - If elapsed time exceeds the threshold — call `TimerEngine.markIdle(idleStart, now)` and stop the timer
4. Segments of type `idle` are never included in any statistics

---

### 4. BreakManager

Controls break flow and reminder scheduling.

**Reminders:**
- If `breakReminderEnabled = true` and `breakReminderIntervalMin` minutes have passed without a break, show a VSCode notification via `vscode.window.showInformationMessage`
- Notification buttons: "Start Break" and "Remind Later (+15 min)"

**Methods:**
- `scheduleNextReminder()` — schedule the next reminder based on settings
- `cancelReminder()` — cancel the pending reminder (e.g. when timer is stopped)
- `getBreakStats(date: string): number` — total break duration in ms for a given day

---

### 5. StorageService

Persistent data storage layer.

**Storage location:** JSON file at `vscode.ExtensionContext.globalStorageUri`

**Methods:**
- `saveSegment(date: string, segment: TimeSegment): void`
- `getDayRecord(date: string): DayRecord`
- `getWeekRecords(): DayRecord[]`
- `getMonthRecords(): DayRecord[]`
- `saveSettings(settings: Settings): void`
- `loadSettings(): Settings`

---

### 6. StatusBar

Always-visible indicator in the VSCode status bar.

**Displays:**
- State icon
- Elapsed time of the current active session (updated every second via `onTick`)
- Click opens the dashboard

**Examples:**
```
$(clock) 02:34:17 — Working
$(coffee) 00:12:05 — Break
$(circle-slash) Stopped
```

---

### 7. DashboardPanel — React + Tailwind Webview

The main UI, opened as a tab inside VSCode via the Webview API.

**Extension side (`DashboardPanel.ts`):**
- Creates and manages `vscode.WebviewPanel`
- Loads the compiled React bundle (`webview-ui/dist/index.js`) via `panel.webview.asWebviewUri`
- Listens to `panel.webview.onDidReceiveMessage` and routes commands to the appropriate module
- Pushes state updates to the webview via `panel.webview.postMessage`

**React app (`webview-ui/`):**

The `vscode` API object is acquired once via `acquireVsCodeApi()` at module level. All communication uses `postMessage` outbound and `window.addEventListener("message", ...)` inbound, abstracted behind `useVSCodeMessage.ts`.

**Components:**

`StatusPanel.tsx`
- Displays current timer state and elapsed time (received via `stateUpdate` messages)
- Renders context-aware control buttons: "Start" / "Stop", "Start Break" / "End Break", and "Extend Work" (shown when state is `extended` or a scheduled stop was reached)

`StatsPanel.tsx`
- Tab switcher: Day / Week / Month
- On tab change: sends `requestStats` message to extension and renders data from the `statsData` response
- Renders `StatsChart` and `SessionTable`

`StatsChart.tsx`
- Bar chart built with Recharts using `BarChart`, `Bar`, `XAxis`, `YAxis`, and `Tooltip`
- Displays work time and break time per day as grouped bars
- Idle time is filtered out before data is passed to the chart

`SessionTable.tsx`
- Table of individual work segments for the selected period
- Columns: Date, Start, End, Duration, Type

`SettingsPanel.tsx`
- Controlled React form with local state
- Sends `saveSettings` message on submit
- Fields: schedule start time, schedule stop time, break reminder toggle, reminder interval in minutes, idle threshold in minutes

**Message flow example:**
```
User clicks "Start Break" in React UI
  → postMessage({ type: "startBreak" })
    → DashboardPanel.onDidReceiveMessage
      → BreakManager.startBreak()
        → TimerEngine emits onStateChange("on_break")
          → DashboardPanel.postMessage({ type: "stateUpdate", state: "on_break", elapsed })
            → React useVSCodeMessage hook updates state
              → StatusPanel re-renders with break UI
```

---

## Tailwind CSS Setup

Tailwind CSS v4 removes `tailwind.config.ts` entirely. All theme customisation — colors, fonts, animations, and custom utilities — is declared directly in the main CSS file using `@theme` and `@layer`. No separate config file is needed.

### Installation

```bash
cd webview-ui
npm install -D tailwindcss @tailwindcss/vite
```

Add the Tailwind Vite plugin to `vite.config.ts`:

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

### index.css

This single file replaces both `tailwind.config.ts` and the old `@tailwind` directives. The `@import "tailwindcss"` line bootstraps the framework; `@theme` declares all design tokens; `@layer base` sets global resets.

```css
@import url("https://fonts.googleapis.com/css2?family=DM+Mono:wght@400;500&family=DM+Sans:wght@400;500;600&display=swap");
@import "tailwindcss";

@theme {
  /* Fonts */
  --font-display: "DM Mono", monospace;
  --font-body:    "DM Sans", sans-serif;

  /* Surface palette */
  --color-surface:         #0f1117;
  --color-surface-raised:  #161b27;
  --color-surface-overlay: #1e2535;

  /* State accents */
  --color-accent-work:      #4ade80;
  --color-accent-work-glow: rgba(74, 222, 128, 0.25);
  --color-accent-break:     #60a5fa;
  --color-accent-idle:      #6b7280;
  --color-accent-muted:     #374151;

  /* Text */
  --color-text-primary:   #f1f5f9;
  --color-text-secondary: #94a3b8;
  --color-text-dim:       #475569;

  /* Border */
  --color-border: rgba(255, 255, 255, 0.07);

  /* Border radius */
  --radius-card: 12px;
  --radius-pill: 999px;

  /* Shadows */
  --shadow-card: 0 1px 3px 0 rgba(0,0,0,0.3), 0 0 0 1px var(--color-border);
  --shadow-glow: 0 0 16px 2px var(--color-accent-work-glow);

  /* Keyframes */
  --animate-pulse-ring: pulse-ring 2s ease-in-out infinite;
  --animate-fade-in:    fade-in 0.25s ease forwards;
  --animate-tick:       tick 1s step-start infinite;

  @keyframes pulse-ring {
    0%, 100% { opacity: 0.6; transform: scale(1); }
    50%       { opacity: 0;   transform: scale(1.5); }
  }

  @keyframes fade-in {
    from { opacity: 0; transform: translateY(6px); }
    to   { opacity: 1; transform: translateY(0); }
  }

  @keyframes tick {
    0%, 100% { opacity: 1; }
    50%      { opacity: 0.3; }
  }
}

@layer base {
  * { box-sizing: border-box; }
  body {
    background-color: var(--color-surface);
    color: var(--color-text-primary);
    font-family: var(--font-body);
    font-size: 14px;
    margin: 0;
  }
}
```

---

## Design System

### Aesthetic Direction

**Tone:** Refined dark utility — minimal, purposeful, precise. Inspired by terminal dashboards and developer tooling. Nothing decorative unless it carries meaning. Every element earns its place.

**Visual Language:**
- Deep near-black backgrounds (`#0f1117`) with subtle surface layering — not flat, but not heavy
- A single accent per state: green for work, blue for break, grey for idle
- Monospace font (`DM Mono`) for all time values and data; humanist sans (`DM Sans`) for labels and UI text
- Sharp, clean cards with a 1px border-glow (`rgba(255,255,255,0.07)`) instead of heavy box shadows
- Micro-animations that confirm state changes rather than distract: a slow pulsing ring around the active indicator, a subtle fade-in on panel transitions

### Key UI Patterns

**Timer Display (`StatusPanel`):**
- Large monospace clock (`text-5xl font-display tracking-tight`) as the visual anchor
- State indicator: a small filled circle with a pulsing ring when active (`animate-pulse_ring`), coloured by state
- Buttons are outlined, not filled, by default; the primary action (Start/Stop) becomes filled with the state colour on hover
- The "Extend Work" button appears as a subtle pill with a dashed border — visually distinct from primary actions

**Stats Chart (`StatsChart`):**
- Recharts `BarChart` with rounded bars (`radius={[4,4,0,0]}`)
- Work bars in `accent-work`, break bars in `accent-break`, both at 60% opacity unless hovered
- Custom `Tooltip` styled to match the surface palette — dark background, sharp border, DM Mono values
- No grid lines on Y axis; only a faint baseline on X axis

**Cards:**
- All panels sit in cards with `rounded-card bg-surface-raised shadow-card`
- Section headers use `text-xs uppercase tracking-widest text-text-dim font-medium` — quiet but structured
- Inputs: `bg-surface border border-border rounded-lg px-3 py-2 text-text-primary focus:outline-none focus:ring-1 focus:ring-accent-work/50` — minimal, with a green focus ring tied to the work accent

**Tab Switcher (Day / Week / Month):**
- Pill-style switcher: `bg-surface-overlay rounded-pill p-1 flex gap-1`
- Active tab: `bg-accent-muted text-text-primary`, inactive: `text-text-dim hover:text-text-secondary`
- Transition: `transition-colors duration-150`

**Session Table:**
- Clean `table-fixed w-full` with `text-sm` body and `text-xs text-text-dim uppercase tracking-wider` column headers
- Alternating row backgrounds: `even:bg-surface-raised`
- Type badge: inline pill coloured by segment type — green for work, blue for break

**Settings Form:**
- Two-column grid layout for inputs: `grid grid-cols-2 gap-4`
- Toggle (break reminder): custom-styled using a hidden checkbox + a `div` pill with `transition-all`
- Save button: full-width, filled with `accent-work`, text in deep surface colour — the only solid-colour button in the UI

---

## Commands

Register in `package.json` under `contributes.commands`:

| Command ID | Title |
|---|---|
| `timeTracker.start` | Time Tracker: Start Working |
| `timeTracker.stop` | Time Tracker: Stop Working |
| `timeTracker.startBreak` | Time Tracker: Start Break |
| `timeTracker.endBreak` | Time Tracker: End Break |
| `timeTracker.extend` | Time Tracker: Extend Work Session |
| `timeTracker.openDashboard` | Time Tracker: Open Dashboard |

---

## Development Phases

### Phase 1 — Core Timer (MVP)
1. Initialize the extension project with `tsconfig.json` and `package.json`
2. Implement `models.ts` and `StorageService.ts`
3. Implement `TimerEngine.ts` — start, stop, state transitions, EventEmitter
4. Implement `StatusBar.ts` — basic status indicator with tick updates
5. Register `start` / `stop` commands in `extension.ts`
6. Verify segment persistence: write and read back from JSON storage

### Phase 2 — Breaks and Schedule
1. Implement `BreakManager.ts` — start/stop break, getBreakStats, reminder scheduling
2. Implement `ScheduleManager.ts` — auto-start and auto-stop using setTimeout aligned to wall clock
3. Implement `NotificationService.ts` — break reminders with action buttons
4. Register `startBreak` / `endBreak` commands
5. Update `StatusBar` to reflect break state

### Phase 3 — Extend and Idle Detection
1. Implement "Extend" logic in `TimerEngine` — transition to `extended`, cancel scheduled stop
2. Implement `IdleDetector.ts` — subscribe to editor events, manage idle timer
3. Activate `IdleDetector` only on transition to `extended` state; deactivate on stop
4. Record `idle` segments and confirm they are excluded from all duration calculations
5. Test the full scenario: working → scheduled stop fires → user extends → idle threshold exceeded → auto-stop

### Phase 4 — React Dashboard
1. Initialize `webview-ui/` as a Vite + React + TypeScript project
2. Install Tailwind CSS v4 with `@tailwindcss/vite`; add the plugin to `vite.config.ts`; no separate config file needed
3. Configure Vite to output a single-file bundle (`dist/index.js`) compatible with VSCode webview CSP
4. Set up the design system: CSS custom properties in `index.css`, font imports, Tailwind theme extension
5. Implement `DashboardPanel.ts` — create webview panel, load bundle, wire message handlers
6. Implement `useVSCodeMessage.ts` and `useTimerState.ts` hooks
7. Build `StatusPanel.tsx` — large monospace clock, state indicator with pulse ring, control buttons
8. Build `StatsPanel.tsx` — pill tab switcher, `requestStats` / `statsData` message cycle
9. Build `StatsChart.tsx` — Recharts bar chart with custom tooltip and rounded bars
10. Build `SessionTable.tsx` — typed segment rows with colour-coded type badges
11. Build `SettingsPanel.tsx` — two-column form, custom toggle, green save button
12. Connect all components end-to-end through `App.tsx`

### Phase 5 — Polish and Edge Cases
1. Handle VSCode restart: detect orphaned active segments on activation and prompt the user to close them
2. Handle midnight rollover: split active segments at day boundaries automatically
3. Validate settings on save (stop time must be after start time; thresholds must be positive numbers)
4. Add `animate-fade_in` on panel/tab transitions for smooth content switching
5. Write `README.md` with setup instructions and feature overview
6. Profile editor event subscriptions to confirm no measurable impact on typing performance

---

## Edge Cases

| Situation | Resolution |
|---|---|
| VSCode closed during active session | On next activation: if the last segment has `end = null` and significant time has passed, show a dialog prompting the user to close the previous session |
| Midnight rollover (e.g. working 23:00–01:00) | Automatically close the segment at 23:59:59 and open a new one at 00:00:00 the next day |
| Multiple VSCode windows open | Use `globalState` as single source of truth; other windows read state but do not write conflicting data |
| User manually stops while in `extended` mode | Deactivate `IdleDetector`, finalize the segment normally, transition to `idle` |
| Break reminder fires while idle | If `IdleDetector` has already stopped the timer, suppress the break reminder |

---

## Key Implementation Notes

- Store all timestamps as **Unix ms** (`Date.now()`); convert to human-readable strings only in the UI layer
- `idle` segments are persisted in `DayRecord.segments` for auditability but are filtered out before any duration calculation in `StorageService` query methods
- `TimerEngine` is the single source of truth for timer state; all other modules react to its events and never hold their own copy of the state
- The React webview has no direct access to the VSCode API — all logic lives in the extension host; the webview only renders data and sends command messages
- Use `vscode.workspace.onDidChangeConfiguration` to react to settings changes without requiring an extension restart
- Bundle the React app separately with Vite; reference the output file in `DashboardPanel.ts` via `panel.webview.asWebviewUri` to comply with the VSCode webview Content Security Policy
- Tailwind's CSS output must be inlined or bundled into the single Vite output file — external stylesheet links are blocked by the webview CSP; configure Vite to inject styles into the JS bundle or use a `<style>` tag in `index.html` that Vite inlines at build time