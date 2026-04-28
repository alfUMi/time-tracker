import { FormEvent, useEffect, useState } from "react";

import { Settings } from "../types";

interface SettingsPanelProps {
  settings: Settings | null;

  onSave: (settings: Settings) => void;
}

export function SettingsPanel({ settings, onSave }: SettingsPanelProps): JSX.Element {
  const [form, setForm] = useState<Settings>({
    scheduleStart: null,
    scheduleStop: null,
    breakReminderEnabled: true,
    breakReminderIntervalMin: 60,
    idleThresholdMin: 5
  });

  useEffect(() => {
    if (!settings) {
      return;
    }

    setForm(settings);
  }, [settings]);

  function onSubmit(event: FormEvent<HTMLFormElement>): void {
    event.preventDefault();
    onSave(form);
  }

  return (
    <section className="rounded-[12px] border border-[var(--color-border)] bg-[var(--color-surface-raised)] p-4">
      <p className="mb-3 text-xs uppercase tracking-[0.12em] text-[var(--color-text-dim)]">
        Settings
      </p>

      <form className="grid grid-cols-2 gap-3" onSubmit={onSubmit}>
        <label className="field">
          <span>Schedule Start</span>
          <input
            type="time"
            value={form.scheduleStart ?? ""}
            onChange={(event) => {
              setForm((previous) => ({
                ...previous,
                scheduleStart: event.target.value || null
              }));
            }}
          />
        </label>

        <label className="field">
          <span>Schedule Stop</span>
          <input
            type="time"
            value={form.scheduleStop ?? ""}
            onChange={(event) => {
              setForm((previous) => ({
                ...previous,
                scheduleStop: event.target.value || null
              }));
            }}
          />
        </label>

        <label className="field">
          <span>Reminder Interval (min)</span>
          <input
            type="number"
            min={1}
            value={form.breakReminderIntervalMin}
            onChange={(event) => {
              setForm((previous) => ({
                ...previous,
                breakReminderIntervalMin: Number.parseInt(event.target.value || "1", 10)
              }));
            }}
          />
        </label>

        <label className="field">
          <span>Idle Threshold (min)</span>
          <input
            type="number"
            min={1}
            value={form.idleThresholdMin}
            onChange={(event) => {
              setForm((previous) => ({
                ...previous,
                idleThresholdMin: Number.parseInt(event.target.value || "1", 10)
              }));
            }}
          />
        </label>

        <label className="col-span-2 flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={form.breakReminderEnabled}
            onChange={(event) => {
              setForm((previous) => ({
                ...previous,
                breakReminderEnabled: event.target.checked
              }));
            }}
          />
          Break reminders enabled
        </label>

        <button className="btn col-span-2" type="submit">
          Save Settings
        </button>
      </form>
    </section>
  );
}
