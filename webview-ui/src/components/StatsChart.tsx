import { DayRecord } from "../types";
import {
  Bar,
  BarChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis
} from "recharts";

interface StatsChartProps {
  records: DayRecord[];
}

function toHours(ms: number): number {
  return Number((ms / 3_600_000).toFixed(2));
}

function dayTotals(record: DayRecord): { workMs: number; breakMs: number } {
  return record.segments.reduce(
    (accumulator, segment) => {
      if (segment.type === "idle") {
        return accumulator;
      }

      const end = segment.end ?? Date.now();
      const duration = Math.max(0, end - segment.start);

      if (segment.type === "work") {
        return { ...accumulator, workMs: accumulator.workMs + duration };
      }

      return { ...accumulator, breakMs: accumulator.breakMs + duration };
    },
    { workMs: 0, breakMs: 0 }
  );
}

export function StatsChart({ records }: StatsChartProps): JSX.Element {
  if (records.length === 0) {
    return (
      <div className="rounded-[12px] border border-[var(--color-border)] bg-[var(--color-surface-raised)] p-4 text-sm text-[var(--color-text-secondary)]">
        No records yet.
      </div>
    );
  }

  const chartData = records.map((record) => {
    const totals = dayTotals(record);

    return {
      date: record.date,
      work: toHours(totals.workMs),
      break: toHours(totals.breakMs)
    };
  });

  return (
    <div className="rounded-[12px] border border-[var(--color-border)] bg-[var(--color-surface-raised)] p-4">
      <p className="mb-3 text-xs uppercase tracking-[0.12em] text-[var(--color-text-dim)]">
        Daily Totals (hours)
      </p>

      <div className="h-[260px]">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={chartData}>
            <XAxis dataKey="date" tick={{ fill: "#94a3b8", fontSize: 12 }} />

            <YAxis tick={{ fill: "#94a3b8", fontSize: 12 }} />

            <Tooltip
              contentStyle={{
                background: "#161b27",
                border: "1px solid rgba(255,255,255,0.07)"
              }}
            />

            <Bar dataKey="work" fill="#4ade80" radius={[4, 4, 0, 0]} />

            <Bar dataKey="break" fill="#60a5fa" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
