export type SegmentType = "work" | "break" | "idle";

export interface TimeSegment {
  start: number;

  end: number | null;

  type: SegmentType;
}

export interface DayRecord {
  date: string;

  segments: TimeSegment[];
}

export interface Settings {
  scheduleStart: string | null;

  scheduleStop: string | null;

  breakReminderEnabled: boolean;

  breakReminderIntervalMin: number;

  idleThresholdMin: number;
}

export type TimerState = "idle" | "working" | "on_break" | "extended";

export type StatsPeriod = "day" | "week" | "month";

export type WebviewMessage =
  | { type: "stateUpdate"; state: TimerState; elapsed: number }
  | { type: "statsData"; period: StatsPeriod; records: DayRecord[] }
  | { type: "settingsData"; settings: Settings };

export type ExtensionMessage =
  | { type: "start" }
  | { type: "stop" }
  | { type: "startBreak" }
  | { type: "endBreak" }
  | { type: "extend" }
  | { type: "requestStats"; period: StatsPeriod }
  | { type: "requestSettings" }
  | { type: "saveSettings"; settings: Settings };

export interface PersistedData {
  records: Record<string, DayRecord>;

  settings: Settings;
}

export const DEFAULT_SETTINGS: Settings = {
  scheduleStart: null,

  scheduleStop: null,

  breakReminderEnabled: true,

  breakReminderIntervalMin: 60,

  idleThresholdMin: 5
};
