import { NotificationService } from "../notifications/NotificationService";
import { StorageService } from "../storage/StorageService";
import { TimerState } from "../storage/models";
import { TimerEngine } from "./TimerEngine";

export class BreakManager {
  private reminderTimeout: NodeJS.Timeout | undefined;

  private lastWorkStartMs: number | null = null;

  constructor(
    private readonly timerEngine: TimerEngine,
    private readonly storageService: StorageService,
    private readonly notificationService: NotificationService
  ) {}

  public async scheduleNextReminder(delayMinutes?: number): Promise<void> {
    const settings = await this.storageService.loadSettings();

    if (!settings.breakReminderEnabled) {
      this.cancelReminder();

      return;
    }

    const delayMs = Math.max(
      1,
      (delayMinutes ?? settings.breakReminderIntervalMin) * 60 * 1000
    );

    this.cancelReminder();

    this.reminderTimeout = setTimeout(async () => {
      const state = this.timerEngine.getState();

      if (state !== "working" && state !== "extended") {
        return;
      }

      const action = await this.notificationService.showInfoWithActions(
        "Time Tracker: You have been working for a while. Start a break?",
        ["Start Break", "Remind Later (+15 min)"]
      );

      if (action === "Start Break") {
        await this.timerEngine.startBreak();

        return;
      }

      if (action === "Remind Later (+15 min)") {
        await this.scheduleNextReminder(15);

        return;
      }

      await this.scheduleNextReminder();
    }, delayMs);
  }

  public cancelReminder(): void {
    if (!this.reminderTimeout) {
      return;
    }

    clearTimeout(this.reminderTimeout);
    this.reminderTimeout = undefined;
  }

  public async getBreakStats(date: string): Promise<number> {
    const dayRecord = await this.storageService.getDayRecord(date);

    return dayRecord.segments
      .filter((segment) => segment.type === "break")
      .reduce((total, segment) => {
        const end = segment.end ?? Date.now();
        const duration = Math.max(0, end - segment.start);

        return total + duration;
      }, 0);
  }

  public async handleStateChange(state: TimerState): Promise<void> {
    if (state === "working" || state === "extended") {
      if (this.lastWorkStartMs === null) {
        this.lastWorkStartMs = Date.now();
      }

      await this.scheduleNextReminder();

      return;
    }

    if (state === "on_break") {
      this.lastWorkStartMs = null;
      this.cancelReminder();

      return;
    }

    this.lastWorkStartMs = null;
    this.cancelReminder();
  }

  public dispose(): void {
    this.cancelReminder();
  }
}
