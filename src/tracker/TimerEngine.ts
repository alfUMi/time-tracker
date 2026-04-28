import { EventEmitter } from "node:events";

import { StorageService } from "../storage/StorageService";
import { SegmentType, TimerState, TimeSegment } from "../storage/models";

type TimerEngineEvents = "stateChange" | "tick" | "scheduledStop";

export class TimerEngine {
  private readonly events = new EventEmitter();

  private operationQueue: Promise<void> = Promise.resolve();

  private tickInterval: NodeJS.Timeout | undefined;

  private midnightTimeout: NodeJS.Timeout | undefined;

  private state: TimerState = "idle";

  private activeSegmentStart: number | null = null;

  private activeSegmentDate: string | null = null;

  private activeSegmentType: SegmentType | null = null;

  constructor(private readonly storageService: StorageService) {}

  public getState(): TimerState {
    return this.state;
  }

  public getElapsedMs(): number {
    if (this.activeSegmentStart === null) {
      return 0;
    }

    return Math.max(0, Date.now() - this.activeSegmentStart);
  }

  public onStateChange(listener: (state: TimerState) => void): void {
    this.events.on("stateChange", listener);
  }

  public onTick(listener: (elapsedMs: number) => void): void {
    this.events.on("tick", listener);
  }

  public onScheduledStop(listener: () => void): void {
    this.events.on("scheduledStop", listener);
  }

  public async start(): Promise<void> {
    await this.runExclusive(async () => {
      if (this.state !== "idle") {
        return;
      }

      const startTime = Date.now();

      await this.openActiveSegment(startTime, "work");
      this.transitionTo("working");
      this.startTicking();
      this.scheduleMidnightRollover();
    });
  }

  public async stop(): Promise<void> {
    await this.runExclusive(async () => {
      if (this.state === "idle") {
        return;
      }

      const now = Date.now();

      await this.closeActiveSegment(now);

      this.activeSegmentStart = null;
      this.activeSegmentDate = null;
      this.activeSegmentType = null;
      this.stopTicking();
      this.clearMidnightRollover();
      this.transitionTo("idle");
    });
  }

  public async startBreak(): Promise<void> {
    await this.runExclusive(async () => {
      if (this.state !== "working" && this.state !== "extended") {
        return;
      }

      const now = Date.now();

      await this.closeActiveSegment(now);
      await this.openActiveSegment(now, "break");

      this.transitionTo("on_break");
      this.scheduleMidnightRollover();
    });
  }

  public async endBreak(): Promise<void> {
    await this.runExclusive(async () => {
      if (this.state !== "on_break") {
        return;
      }

      const now = Date.now();

      await this.closeActiveSegment(now);
      await this.openActiveSegment(now, "work");

      this.transitionTo("working");
      this.scheduleMidnightRollover();
    });
  }

  public extendWork(): void {
    if (this.state !== "working") {
      return;
    }

    this.transitionTo("extended");
  }

  public async markIdle(from: number, to: number): Promise<void> {
    await this.runExclusive(async () => {
      if (to <= from) {
        return;
      }

      const segment: TimeSegment = {
        start: from,
        end: to,
        type: "idle"
      };

      await this.storageService.saveSegment(this.toDateKey(from), segment);
    });
  }

  public emitScheduledStop(): void {
    this.events.emit("scheduledStop");
  }

  public async resumeFromOpenSegment(
    date: string,
    start: number,
    type: SegmentType
  ): Promise<void> {
    await this.runExclusive(async () => {
      if (type !== "work" && type !== "break") {
        return;
      }

      this.activeSegmentDate = date;
      this.activeSegmentStart = start;
      this.activeSegmentType = type;

      if (type === "break") {
        this.transitionTo("on_break");
      } else {
        this.transitionTo("working");
      }

      this.startTicking();
      this.scheduleMidnightRollover();
    });
  }

  public hasActiveSegment(): boolean {
    return this.activeSegmentStart !== null && this.activeSegmentDate !== null;
  }

  public getActiveSegmentStart(): number | null {
    return this.activeSegmentStart;
  }

  private startTicking(): void {
    this.stopTicking();

    this.tickInterval = setInterval(() => {
      this.events.emit("tick", this.getElapsedMs());
    }, 1000);
  }

  private scheduleMidnightRollover(): void {
    this.clearMidnightRollover();

    if (!this.hasActiveSegment()) {
      return;
    }

    const now = new Date();
    const nextMidnight = new Date(now);

    nextMidnight.setHours(24, 0, 0, 0);

    const delayMs = Math.max(1, nextMidnight.getTime() - now.getTime());

    this.midnightTimeout = setTimeout(() => {
      void this.runExclusive(async () => {
        await this.handleMidnightRollover(nextMidnight.getTime());
      });
    }, delayMs);
  }

  private clearMidnightRollover(): void {
    if (!this.midnightTimeout) {
      return;
    }

    clearTimeout(this.midnightTimeout);
    this.midnightTimeout = undefined;
  }

  private async handleMidnightRollover(nextMidnightMs: number): Promise<void> {
    if (!this.hasActiveSegment()) {
      return;
    }

    const currentType = this.activeSegmentType;

    if (currentType !== "work" && currentType !== "break") {
      return;
    }

    const closeAt = Math.max(nextMidnightMs - 1, this.activeSegmentStart ?? nextMidnightMs);

    await this.closeActiveSegment(closeAt);
    await this.openActiveSegment(nextMidnightMs, currentType);

    this.events.emit("tick", this.getElapsedMs());
    this.scheduleMidnightRollover();
  }

  private async openActiveSegment(
    startTimestampMs: number,
    type: SegmentType
  ): Promise<void> {
    const date = this.toDateKey(startTimestampMs);

    await this.storageService.saveSegment(date, {
      start: startTimestampMs,
      end: null,
      type
    });

    this.activeSegmentDate = date;
    this.activeSegmentStart = startTimestampMs;
    this.activeSegmentType = type;
  }

  private async closeActiveSegment(endTimestampMs: number): Promise<void> {
    if (
      this.activeSegmentDate === null ||
      this.activeSegmentStart === null ||
      endTimestampMs < this.activeSegmentStart
    ) {
      return;
    }

    await this.storageService.closeSegmentByStart(
      this.activeSegmentDate,
      this.activeSegmentStart,
      endTimestampMs
    );
  }

  private async runExclusive(task: () => Promise<void>): Promise<void> {
    const run = this.operationQueue.then(task);

    this.operationQueue = run.catch(() => {
      // Keep queue alive after failure.
    });

    return run;
  }

  private stopTicking(): void {
    if (!this.tickInterval) {
      return;
    }

    clearInterval(this.tickInterval);
    this.tickInterval = undefined;
  }

  private transitionTo(state: TimerState): void {
    this.state = state;
    this.events.emit("stateChange", this.state);
  }

  private toDateKey(timestampMs: number): string {
    const value = new Date(timestampMs);
    const year = value.getFullYear();
    const month = `${value.getMonth() + 1}`.padStart(2, "0");
    const day = `${value.getDate()}`.padStart(2, "0");

    return `${year}-${month}-${day}`;
  }
}
