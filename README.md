# Time Tracker VSCode Extension

Time Tracker is a Visual Studio Code extension for tracking working time, breaks, and idle periods directly inside the editor.

## Features

- Work session start and stop commands.

- Break session start and end commands.

- Extend flow after scheduled stop.

- Idle detection in extended mode with auto-stop and idle segment logging.

- Persistent storage for segments and settings in extension global storage.

- Status bar timer state indicator.

- React webview dashboard with:
  - live state and controls
  - day/week/month stats
  - session table
  - settings form

- Restart recovery for orphaned open sessions.

- Midnight rollover split for active sessions across day boundaries.

## Project Structure

```text
src/
  extension.ts
  storage/
  tracker/
  ui/
  notifications/
webview-ui/
  src/
```

## Development Setup

1. Install root dependencies:

```bash
npm install
```

2. Install webview UI dependencies:

```bash
cd webview-ui
npm install
```

3. Build the webview bundle before opening dashboard:

```bash
cd webview-ui
npm run build
```

4. Compile extension TypeScript:

```bash
npm run compile
```

5. Press `F5` in VSCode to launch an Extension Development Host.

## Commands

- `timeTracker.start`
- `timeTracker.stop`
- `timeTracker.startBreak`
- `timeTracker.endBreak`
- `timeTracker.extend`
- `timeTracker.openDashboard`

## Notes

- Timestamps are persisted as Unix milliseconds.

- Idle segments are stored for auditability and are excluded from work/break totals.

- Dashboard expects `webview-ui/dist/index.js` to exist.
