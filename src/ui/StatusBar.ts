import * as vscode from "vscode";

import { TimerEngine } from "../tracker/TimerEngine";

export class StatusBar {
  private readonly item: vscode.StatusBarItem;

  constructor(private readonly timerEngine: TimerEngine) {
    this.item = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    this.item.command = "timeTracker.openDashboard";

    this.timerEngine.onStateChange(() => {
      this.render();
    });

    this.timerEngine.onTick(() => {
      this.render();
    });
  }

  public show(): void {
    this.render();
    this.item.show();
  }

  public dispose(): void {
    this.item.dispose();
  }

  private render(): void {
    const state = this.timerEngine.getState();
    const elapsed = this.formatElapsed(this.timerEngine.getElapsedMs());

    if (state === "idle") {
      this.item.text = "$(circle-slash) Stopped";
      this.item.tooltip = "Time Tracker is stopped.";

      return;
    }

    if (state === "on_break") {
      this.item.text = `$(coffee) ${elapsed} - Break`;
      this.item.tooltip = "Break timer is active.";

      return;
    }

    if (state === "extended") {
      this.item.text = `$(watch) ${elapsed} - Extended`;
      this.item.tooltip = "Extended work session is active.";

      return;
    }

    this.item.text = `$(clock) ${elapsed} - Working`;
    this.item.tooltip = "Work timer is active.";
  }

  private formatElapsed(elapsedMs: number): string {
    const totalSeconds = Math.floor(elapsedMs / 1000);
    const seconds = `${totalSeconds % 60}`.padStart(2, "0");
    const minutes = `${Math.floor((totalSeconds / 60) % 60)}`.padStart(2, "0");
    const hours = `${Math.floor(totalSeconds / 3600)}`.padStart(2, "0");

    return `${hours}:${minutes}:${seconds}`;
  }
}
