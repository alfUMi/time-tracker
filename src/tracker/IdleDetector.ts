import * as vscode from "vscode";

import { TimerEngine } from "./TimerEngine";

export class IdleDetector {
  private readonly subscriptions: vscode.Disposable[] = [];

  private idleTimer: NodeJS.Timeout | undefined;

  private idleStartMs: number | null = null;

  private isActive = false;

  private activityQueue: Promise<void> = Promise.resolve();

  constructor(
    private readonly timerEngine: TimerEngine,
    private idleThresholdMin: number
  ) {}

  public updateThreshold(nextIdleThresholdMin: number): void {
    this.idleThresholdMin = nextIdleThresholdMin;

    if (this.isActive) {
      this.armIdleTimer();
    }
  }

  public activate(): void {
    if (this.isActive) {
      return;
    }

    this.isActive = true;
    this.attachListeners();
    this.armIdleTimer();
  }

  public deactivate(): void {
    this.isActive = false;
    this.idleStartMs = null;
    this.clearIdleTimer();

    while (this.subscriptions.length > 0) {
      const subscription = this.subscriptions.pop();

      subscription?.dispose();
    }
  }

  public dispose(): void {
    this.deactivate();
  }

  private attachListeners(): void {
    this.subscriptions.push(
      vscode.workspace.onDidChangeTextDocument(() => {
        this.onActivity();
      })
    );

    this.subscriptions.push(
      vscode.window.onDidChangeActiveTextEditor(() => {
        this.onActivity();
      })
    );

    this.subscriptions.push(
      vscode.window.onDidChangeTextEditorSelection(() => {
        this.onActivity();
      })
    );
  }

  private onActivity(): void {
    this.activityQueue = this.activityQueue
      .then(async () => {
        if (!this.isActive) {
          return;
        }

        const thresholdMs = this.getThresholdMs();
        const now = Date.now();
        const idleStart = this.idleStartMs;

        this.idleStartMs = null;
        this.armIdleTimer();

        if (idleStart === null) {
          return;
        }

        const idleDurationMs = now - idleStart;

        if (idleDurationMs < thresholdMs) {
          return;
        }

        await this.timerEngine.markIdle(idleStart, now);
        await this.timerEngine.stop();
      })
      .catch(() => {
        // Keep queue alive even if one activity handler fails.
      });
  }

  private armIdleTimer(): void {
    this.clearIdleTimer();

    const thresholdMs = this.getThresholdMs();

    this.idleTimer = setTimeout(() => {
      this.idleStartMs = Date.now();
    }, thresholdMs);
  }

  private clearIdleTimer(): void {
    if (!this.idleTimer) {
      return;
    }

    clearTimeout(this.idleTimer);
    this.idleTimer = undefined;
  }

  private getThresholdMs(): number {
    return Math.max(1, this.idleThresholdMin) * 60 * 1000;
  }
}
