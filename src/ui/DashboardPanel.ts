import * as vscode from "vscode";

import { StorageService } from "../storage/StorageService";
import {
  ExtensionMessage,
  Settings,
  StatsPeriod,
  WebviewMessage
} from "../storage/models";
import { TimerEngine } from "../tracker/TimerEngine";

interface DashboardPanelOptions {
  extensionUri: vscode.Uri;

  timerEngine: TimerEngine;

  storageService: StorageService;

  onExtendRequested: () => void;

  onSettingsSaved: (settings: Settings) => void;
}

export class DashboardPanel {
  private panel: vscode.WebviewPanel | undefined;

  constructor(private readonly options: DashboardPanelOptions) {}

  public open(): void {
    if (this.panel) {
      this.panel.reveal(vscode.ViewColumn.One);
      this.pushState();

      return;
    }

    this.panel = vscode.window.createWebviewPanel(
      "timeTrackerDashboard",
      "Time Tracker",
      vscode.ViewColumn.One,
      {
        enableScripts: true,

        localResourceRoots: [
          vscode.Uri.joinPath(this.options.extensionUri, "webview-ui", "dist")
        ]
      }
    );

    this.panel.webview.html = this.getHtml(this.panel.webview);

    this.panel.webview.onDidReceiveMessage((message: ExtensionMessage) => {
      void this.handleMessage(message);
    });

    this.panel.onDidDispose(() => {
      this.panel = undefined;
    });

    this.pushState();
    void this.pushSettings();
    void this.pushStats("day");
  }

  public refresh(): void {
    this.pushState();
  }

  private pushState(): void {
    if (!this.panel) {
      return;
    }

    this.postMessage({
      type: "stateUpdate",
      state: this.options.timerEngine.getState(),
      elapsed: this.options.timerEngine.getElapsedMs()
    });
  }

  private async pushStats(period: StatsPeriod): Promise<void> {
    let records;

    if (period === "day") {
      records = [
        await this.options.storageService.getDayRecord(this.toDateKey(new Date()))
      ];
    } else if (period === "week") {
      records = await this.options.storageService.getWeekRecords();
    } else {
      records = await this.options.storageService.getMonthRecords();
    }

    this.postMessage({
      type: "statsData",
      period,
      records
    });
  }

  private async pushSettings(): Promise<void> {
    const settings = await this.options.storageService.loadSettings();

    this.postMessage({
      type: "settingsData",
      settings
    });
  }

  private postMessage(message: WebviewMessage): void {
    if (!this.panel) {
      return;
    }

    void this.panel.webview.postMessage(message);
  }

  private async handleMessage(message: ExtensionMessage): Promise<void> {
    if (message.type === "start") {
      await this.options.timerEngine.start();

      return;
    }

    if (message.type === "stop") {
      await this.options.timerEngine.stop();

      return;
    }

    if (message.type === "startBreak") {
      await this.options.timerEngine.startBreak();

      return;
    }

    if (message.type === "endBreak") {
      await this.options.timerEngine.endBreak();

      return;
    }

    if (message.type === "extend") {
      this.options.onExtendRequested();

      return;
    }

    if (message.type === "requestSettings") {
      await this.pushSettings();

      return;
    }

    if (message.type === "requestStats") {
      await this.pushStats(message.period);

      return;
    }

    if (message.type === "saveSettings") {
      const validationError = this.validateSettings(message.settings);

      if (validationError) {
        await vscode.window.showWarningMessage(
          `Time Tracker: ${validationError}`
        );

        return;
      }

      await this.options.storageService.saveSettings(message.settings);
      this.options.onSettingsSaved(message.settings);
      await this.pushSettings();
    }
  }

  private getHtml(webview: vscode.Webview): string {
    const nonce = this.createNonce();
    const scriptUri = webview.asWebviewUri(
      vscode.Uri.joinPath(this.options.extensionUri, "webview-ui", "dist", "index.js")
    );

    return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta
      http-equiv="Content-Security-Policy"
      content="default-src 'none'; img-src ${webview.cspSource} https:; script-src 'nonce-${nonce}'; style-src ${webview.cspSource} 'unsafe-inline';"
    />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Time Tracker</title>
  </head>
  <body>
    <div id="root"></div>
    <script nonce="${nonce}" type="module" src="${scriptUri}"></script>
  </body>
</html>`;
  }

  private toDateKey(value: Date): string {
    const year = value.getFullYear();
    const month = `${value.getMonth() + 1}`.padStart(2, "0");
    const day = `${value.getDate()}`.padStart(2, "0");

    return `${year}-${month}-${day}`;
  }

  private createNonce(): string {
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    let value = "";

    for (let index = 0; index < 24; index += 1) {
      value += alphabet[Math.floor(Math.random() * alphabet.length)];
    }

    return value;
  }

  private validateSettings(settings: Settings): string | null {
    if (settings.breakReminderIntervalMin <= 0) {
      return "Break reminder interval must be greater than zero.";
    }

    if (settings.idleThresholdMin <= 0) {
      return "Idle threshold must be greater than zero.";
    }

    if (settings.scheduleStart && settings.scheduleStop) {
      const startMinutes = this.toMinutes(settings.scheduleStart);
      const stopMinutes = this.toMinutes(settings.scheduleStop);

      if (stopMinutes <= startMinutes) {
        return "Schedule stop time must be after schedule start time.";
      }
    }

    return null;
  }

  private toMinutes(clock: string): number {
    const [hourText, minuteText] = clock.split(":");
    const hour = Number.parseInt(hourText ?? "0", 10);
    const minute = Number.parseInt(minuteText ?? "0", 10);

    return hour * 60 + minute;
  }
}
