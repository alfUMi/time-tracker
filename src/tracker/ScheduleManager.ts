import { Settings } from "../storage/models";
import { TimerEngine } from "./TimerEngine";

interface ScheduleCallbacks {
  onAutoStart: () => Promise<void>;

  onAutoStop: () => Promise<void>;
}

export class ScheduleManager {
  private startTimeout: NodeJS.Timeout | undefined;

  private stopTimeout: NodeJS.Timeout | undefined;

  private settings: Settings;

  constructor(
    initialSettings: Settings,
    private readonly timerEngine: TimerEngine,
    private readonly callbacks: ScheduleCallbacks
  ) {
    this.settings = initialSettings;
  }

  public start(): void {
    this.reschedule();
  }

  public updateSettings(settings: Settings): void {
    this.settings = settings;
    this.reschedule();
  }

  public cancelScheduledStop(): void {
    if (!this.stopTimeout) {
      return;
    }

    clearTimeout(this.stopTimeout);
    this.stopTimeout = undefined;
  }

  public dispose(): void {
    this.clearTimers();
  }

  private reschedule(): void {
    this.clearTimers();

    if (this.settings.scheduleStart) {
      const startTarget = this.getNextOccurrence(this.settings.scheduleStart);
      const startDelay = Math.max(0, startTarget.getTime() - Date.now());

      this.startTimeout = setTimeout(async () => {
        await this.callbacks.onAutoStart();
        this.reschedule();
      }, startDelay);
    }

    if (this.settings.scheduleStop) {
      const stopTarget = this.getNextOccurrence(this.settings.scheduleStop);
      const stopDelay = Math.max(0, stopTarget.getTime() - Date.now());

      this.stopTimeout = setTimeout(async () => {
        this.timerEngine.emitScheduledStop();
        await this.callbacks.onAutoStop();
        this.reschedule();
      }, stopDelay);
    }
  }

  private clearTimers(): void {
    if (this.startTimeout) {
      clearTimeout(this.startTimeout);
      this.startTimeout = undefined;
    }

    if (this.stopTimeout) {
      clearTimeout(this.stopTimeout);
      this.stopTimeout = undefined;
    }
  }

  private getNextOccurrence(clock: string): Date {
    const [hourText, minuteText] = clock.split(":");
    const hour = Number.parseInt(hourText ?? "0", 10);
    const minute = Number.parseInt(minuteText ?? "0", 10);

    const now = new Date();
    const target = new Date(now);

    target.setHours(hour, minute, 0, 0);

    if (target.getTime() <= now.getTime()) {
      target.setDate(target.getDate() + 1);
    }

    return target;
  }
}
