# Low-Fidelity Wireframes

## Notes

These wireframes define structure, not final visuals.

They intentionally keep the layout simple so the implementation team can preserve hierarchy while refining styling later.

## 1. Notch - Idle State

```text
┌──────────────────────────────────────────────────────────────┐
│  [icon]  Not Tracking                    [Open Dashboard]   │
│                                                              │
│  Ready to start a focus session.                             │
│                                                              │
│  [ Start Session ]                                           │
└──────────────────────────────────────────────────────────────┘
```

## 2. Notch - Active State

```text
┌──────────────────────────────────────────────────────────────┐
│  [state dot]  Working                     [Open Dashboard]   │
│                                                              │
│  02:14:38                                                    │
│  Current task: Deep Work                                     │
│                                                              │
│  [ Stop ]   [ Pause ]   [ Break ]                            │
│                                                              │
│  Today: 5h 20m   Sessions: 3                                 │
└──────────────────────────────────────────────────────────────┘
```

## 3. Notch - Break State

```text
┌──────────────────────────────────────────────────────────────┐
│  [state dot]  On Break                    [Open Dashboard]   │
│                                                              │
│  00:12:04                                                    │
│  Last task: Deep Work                                        │
│                                                              │
│  [ End Break ]   [ Stop Session ]                            │
│                                                              │
│  Back in: reminder optional                                  │
└──────────────────────────────────────────────────────────────┘
```

## 4. Dashboard - Overview

```text
┌───────────────────────────────────────────────────────────────────────────┐
│  MacBook Notch Tracker                    [Current State] [Settings]     │
├───────────────────────────────────────────────────────────────────────────┤
│  Sidebar / Sections       |  Overview                                    │
│                           |                                               │
│  - Overview               |  [ Today ]  [ This Week ]  [ This Month ]    │
│  - History                |                                               │
│  - Insights               |  [Total Time] [Break Time] [Sessions]        │
│  - Settings               |                                               │
│                           |  [ Activity Chart / Trend ]                   │
│                           |                                               │
│                           |  [ Current Session Card ]                     │
└───────────────────────────────────────────────────────────────────────────┘
```

## 5. Dashboard - History

```text
┌───────────────────────────────────────────────────────────────────────────┐
│  History                                                                 │
├───────────────────────────────────────────────────────────────────────────┤
│  Filters: [ Date Range ] [ State ] [ Task ] [ Search ]                   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ Date       Start   End     Duration   State     Task     Actions   │  │
│  │ 06/02      09:00   11:30   2h 30m     Work      Deep     Edit      │  │
│  │ 06/02      11:30   11:45   15m        Break     -        Edit      │  │
│  │ 06/02      11:45   13:00   1h 15m     Work      Admin    Edit      │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│                                            [ Edit ] [ Delete ]            │
└───────────────────────────────────────────────────────────────────────────┘
```

## 6. Dashboard - Settings

```text
┌───────────────────────────────────────────────────────────────────────────┐
│  Settings                                                                │
├───────────────────────────────────────────────────────────────────────────┤
│  Launch                                                                   │
│  [x] Launch at login                                                      │
│                                                                           │
│  Notch                                                                     │
│  Reveal delay          [ 120 ms ]                                         │
│  Close delay           [ 220 ms ]                                         │
│  [x] Keep dashboard shortcut visible                                      │
│                                                                           │
│  Notifications                                                             │
│  [x] Break reminders                                                      │
│  Reminder interval     [ 60 min ]                                         │
│                                                                           │
│  [ Save Settings ]                                                        │
└───────────────────────────────────────────────────────────────────────────┘
```

## Layout Guidance

- keep the notch centered and compact
- keep the dashboard wide enough for charts and history without crowding
- keep primary actions near current state information
- avoid deep nesting of controls in the first version
- keep dashboard navigation extensible so future sections such as exports or integrations can be added without replacing the overall shell
