import * as vscode from "vscode";

import { NotificationService } from "./notifications/NotificationService";
import { StorageService } from "./storage/StorageService";
import { BreakManager } from "./tracker/BreakManager";
import { IdleDetector } from "./tracker/IdleDetector";
import { ScheduleManager } from "./tracker/ScheduleManager";
import { TimerEngine } from "./tracker/TimerEngine";
import { DashboardPanel } from "./ui/DashboardPanel";
import { QuickTimerViewProvider } from "./ui/QuickTimerViewProvider";
import { StatusBar } from "./ui/StatusBar";

export async function activate(context: vscode.ExtensionContext): Promise<void> {
  const storageService = new StorageService(context);

  await storageService.initialize();

  const settings = await storageService.loadSettings();
  const timerEngine = new TimerEngine(storageService);
  const notificationService = new NotificationService();
  const breakManager = new BreakManager(timerEngine, storageService, notificationService);
  const idleDetector = new IdleDetector(timerEngine, settings.idleThresholdMin);
  const statusBar = new StatusBar(timerEngine);
  const scheduleManager = new ScheduleManager(settings, timerEngine, {
    onAutoStart: async () => {
      await timerEngine.start();
    },
    onAutoStop: async () => {
      const choice = await notificationService.showWarningWithActions(
        "Time Tracker: Scheduled stop time reached.",
        ["Stop Working", "Extend Work"]
      );

      if (choice === "Extend Work") {
        scheduleManager.cancelScheduledStop();
        timerEngine.extendWork();

        return;
      }

      await timerEngine.stop();
    }
  });
  const dashboardPanel = new DashboardPanel({
    extensionUri: context.extensionUri,
    timerEngine,
    storageService,
    onExtendRequested: () => {
      scheduleManager.cancelScheduledStop();
      timerEngine.extendWork();
    },
    onSettingsSaved: (nextSettings) => {
      scheduleManager.updateSettings(nextSettings);
      idleDetector.updateThreshold(nextSettings.idleThresholdMin);
    }
  });
  const quickTimerViewProvider = new QuickTimerViewProvider({
    timerEngine,
    onExtendRequested: () => {
      scheduleManager.cancelScheduledStop();
      timerEngine.extendWork();
    },
    onOpenDashboard: () => {
      dashboardPanel.open();
    }
  });

  timerEngine.onStateChange((state) => {
    dashboardPanel.refresh();
    quickTimerViewProvider.refresh();
    void breakManager.handleStateChange(state);

    if (state === "extended") {
      idleDetector.activate();

      return;
    }

    idleDetector.deactivate();
  });

  timerEngine.onTick(() => {
    dashboardPanel.refresh();
    quickTimerViewProvider.refresh();
  });

  await recoverOpenSegment(storageService, timerEngine, notificationService);

  statusBar.show();
  scheduleManager.start();

  void breakManager.handleStateChange(timerEngine.getState());
  quickTimerViewProvider.refresh();

  context.subscriptions.push(
    statusBar,
    vscode.window.registerWebviewViewProvider(
      QuickTimerViewProvider.viewType,
      quickTimerViewProvider
    ),
    vscode.commands.registerCommand("timeTracker.start", async () => {
      await timerEngine.start();
    }),
    vscode.commands.registerCommand("timeTracker.stop", async () => {
      await timerEngine.stop();
    }),
    vscode.commands.registerCommand("timeTracker.startBreak", async () => {
      await timerEngine.startBreak();
    }),
    vscode.commands.registerCommand("timeTracker.endBreak", async () => {
      await timerEngine.endBreak();
    }),
    vscode.commands.registerCommand("timeTracker.extend", () => {
      scheduleManager.cancelScheduledStop();
      timerEngine.extendWork();
    }),
    vscode.commands.registerCommand("timeTracker.openDashboard", () => {
      dashboardPanel.open();
    }),
    {
      dispose: () => {
        breakManager.dispose();
      }
    },
    {
      dispose: () => {
        idleDetector.dispose();
      }
    },
    {
      dispose: () => {
        scheduleManager.dispose();
      }
    }
  );
}

export function deactivate(): void {}

const RECOVERY_PROMPT_THRESHOLD_MS = 5 * 60 * 1000;

async function recoverOpenSegment(
  storageService: StorageService,
  timerEngine: TimerEngine,
  notificationService: NotificationService
): Promise<void> {
  const openSegments = await storageService.getOpenSegments();

  if (openSegments.length === 0) {
    return;
  }

  const latest = openSegments[openSegments.length - 1];
  const staleSegments = openSegments.slice(0, -1);

  for (const stale of staleSegments) {
    await storageService.closeSegmentByStart(
      stale.date,
      stale.segment.start,
      Date.now()
    );
  }

  const elapsedSinceStart = Date.now() - latest.segment.start;
  const shouldPrompt = elapsedSinceStart >= RECOVERY_PROMPT_THRESHOLD_MS;

  if (shouldPrompt) {
    const action = await notificationService.showWarningWithActions(
      "Time Tracker: Previous session appears to still be open.",
      ["Close Previous Session", "Resume Session"]
    );

    if (action === "Close Previous Session") {
      await storageService.closeSegmentByStart(
        latest.date,
        latest.segment.start,
        Date.now()
      );

      return;
    }
  }

  if (latest.segment.type === "work" || latest.segment.type === "break") {
    await timerEngine.resumeFromOpenSegment(
      latest.date,
      latest.segment.start,
      latest.segment.type
    );
  }
}
