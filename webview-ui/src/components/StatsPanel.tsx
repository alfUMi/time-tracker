import { DayRecord, StatsPeriod } from "../types";
import { SessionTable } from "./SessionTable";
import { StatsChart } from "./StatsChart";

interface StatsPanelProps {
  period: StatsPeriod;

  records: DayRecord[];

  onChangePeriod: (period: StatsPeriod) => void;
}

const PERIODS: StatsPeriod[] = ["day", "week", "month"];

export function StatsPanel({
  period,
  records,
  onChangePeriod
}: StatsPanelProps): JSX.Element {
  return (
    <section className="space-y-3">
      <div className="inline-flex rounded-full border border-[var(--color-border)] bg-[var(--color-surface-overlay)] p-1">
        {PERIODS.map((entry) => (
          <button
            key={entry}
            className={`rounded-full px-3 py-1 text-sm ${
              entry === period
                ? "bg-[var(--color-accent-muted)] text-[var(--color-text-primary)]"
                : "text-[var(--color-text-secondary)]"
            }`}
            onClick={() => {
              onChangePeriod(entry);
            }}
            type="button"
          >
            {entry}
          </button>
        ))}
      </div>

      <StatsChart records={records} />

      <SessionTable records={records} />
    </section>
  );
}
