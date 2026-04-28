import * as fs from "node:fs/promises";
import * as path from "node:path";

import * as vscode from "vscode";

import {
  DayRecord,
  DEFAULT_SETTINGS,
  PersistedData,
  Settings,
  TimeSegment
} from "./models";

const DATA_FILE_NAME = "time-tracker-data.json";

export interface OpenSegmentRecord {
  date: string;

  segment: TimeSegment;
}

export class StorageService {
  private readonly dataFilePath: string;

  constructor(private readonly context: vscode.ExtensionContext) {
    this.dataFilePath = path.join(context.globalStorageUri.fsPath, DATA_FILE_NAME);
  }

  public async initialize(): Promise<void> {
    await fs.mkdir(this.context.globalStorageUri.fsPath, { recursive: true });

    const exists = await this.fileExists(this.dataFilePath);

    if (!exists) {
      await this.writeData({
        records: {},
        settings: DEFAULT_SETTINGS
      });
    }
  }

  public async saveSegment(date: string, segment: TimeSegment): Promise<void> {
    const data = await this.readData();
    const dayRecord = data.records[date] ?? { date, segments: [] };

    dayRecord.segments.push(segment);
    data.records[date] = dayRecord;

    await this.writeData(data);
  }

  public async updateLastOpenSegment(
    date: string,
    updater: (segment: TimeSegment) => TimeSegment
  ): Promise<TimeSegment | null> {
    const data = await this.readData();
    const dayRecord = data.records[date];

    if (!dayRecord || dayRecord.segments.length === 0) {
      return null;
    }

    for (let index = dayRecord.segments.length - 1; index >= 0; index -= 1) {
      const current = dayRecord.segments[index];

      if (current.end === null) {
        const updated = updater(current);
        dayRecord.segments[index] = updated;

        await this.writeData(data);

        return updated;
      }
    }

    return null;
  }

  public async closeSegmentByStart(
    date: string,
    start: number,
    end: number
  ): Promise<boolean> {
    const data = await this.readData();
    const dayRecord = data.records[date];

    if (!dayRecord || dayRecord.segments.length === 0) {
      return false;
    }

    for (let index = dayRecord.segments.length - 1; index >= 0; index -= 1) {
      const current = dayRecord.segments[index];

      if (current.start === start && current.end === null) {
        dayRecord.segments[index] = {
          ...current,
          end
        };

        await this.writeData(data);

        return true;
      }
    }

    return false;
  }

  public async getOpenSegments(): Promise<OpenSegmentRecord[]> {
    const data = await this.readData();
    const openSegments: OpenSegmentRecord[] = [];

    for (const [date, record] of Object.entries(data.records)) {
      for (const segment of record.segments) {
        if (segment.end === null) {
          openSegments.push({
            date,
            segment
          });
        }
      }
    }

    return openSegments.sort(
      (left, right) => left.segment.start - right.segment.start
    );
  }

  public async getDayRecord(date: string): Promise<DayRecord> {
    const data = await this.readData();

    return data.records[date] ?? { date, segments: [] };
  }

  public async getWeekRecords(): Promise<DayRecord[]> {
    const today = new Date();
    const start = new Date(today);

    start.setDate(today.getDate() - 6);
    start.setHours(0, 0, 0, 0);

    return this.getRecordsFromDate(start);
  }

  public async getMonthRecords(): Promise<DayRecord[]> {
    const today = new Date();
    const start = new Date(today.getFullYear(), today.getMonth(), 1);

    start.setHours(0, 0, 0, 0);

    return this.getRecordsFromDate(start);
  }

  public async saveSettings(settings: Settings): Promise<void> {
    const data = await this.readData();
    data.settings = settings;

    await this.writeData(data);
  }

  public async loadSettings(): Promise<Settings> {
    const data = await this.readData();

    return data.settings;
  }

  private async getRecordsFromDate(startDate: Date): Promise<DayRecord[]> {
    const data = await this.readData();
    const startDateString = this.toDateKey(startDate);

    return Object.values(data.records)
      .filter((record) => record.date >= startDateString)
      .sort((left, right) => left.date.localeCompare(right.date));
  }

  private toDateKey(value: Date): string {
    const year = value.getFullYear();
    const month = `${value.getMonth() + 1}`.padStart(2, "0");
    const day = `${value.getDate()}`.padStart(2, "0");

    return `${year}-${month}-${day}`;
  }

  private async readData(): Promise<PersistedData> {
    await this.initialize();

    const raw = await fs.readFile(this.dataFilePath, "utf8");
    const parsed = JSON.parse(raw) as Partial<PersistedData>;

    return {
      records: parsed.records ?? {},
      settings: parsed.settings ?? DEFAULT_SETTINGS
    };
  }

  private async writeData(data: PersistedData): Promise<void> {
    const payload = JSON.stringify(data, null, 2);

    await fs.writeFile(this.dataFilePath, payload, "utf8");
  }

  private async fileExists(filePath: string): Promise<boolean> {
    try {
      await fs.access(filePath);

      return true;
    } catch {
      return false;
    }
  }
}
