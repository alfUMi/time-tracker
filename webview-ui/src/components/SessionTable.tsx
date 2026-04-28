import { DayRecord, TimeSegment } from "../types";

interface SessionTableProps {
  records: DayRecord[];
}

function formatDateTime(timestamp: number): string {
  return new Date(timestamp).toLocaleString();
}

function formatDuration(start: number, end: number | null): string {
  const resolvedEnd = end ?? Date.now();
  const durationMs = Math.max(0, resolvedEnd - start);
  const totalSeconds = Math.floor(durationMs / 1000);
  const seconds = `${totalSeconds % 60}`.padStart(2, "0");
  const minutes = `${Math.floor((totalSeconds / 60) % 60)}`.padStart(2, "0");
  const hours = `${Math.floor(totalSeconds / 3600)}`.padStart(2, "0");

  return `${hours}:${minutes}:${seconds}`;
}

function flattened(records: DayRecord[]): Array<TimeSegment & { date: string }> {
  return records.flatMap((record) =>
    record.segments.map((segment) => ({
      ...segment,
      date: record.date
    }))
  );
}

export function SessionTable({ records }: SessionTableProps): JSX.Element {
  const rows = flattened(records);

  return (
    <section className="rounded-[12px] border border-[var(--color-border)] bg-[var(--color-surface-raised)] p-4">
      <p className="mb-3 text-xs uppercase tracking-[0.12em] text-[var(--color-text-dim)]">
        Sessions
      </p>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[740px] table-fixed text-sm">
          <thead className="text-left text-xs uppercase tracking-[0.1em] text-[var(--color-text-dim)]">
            <tr>
              <th className="pb-2">Date</th>
              <th className="pb-2">Start</th>
              <th className="pb-2">End</th>
              <th className="pb-2">Duration</th>
              <th className="pb-2">Type</th>
            </tr>
          </thead>

          <tbody>
            {rows.map((segment, index) => (
              <tr key={`${segment.date}-${segment.start}-${index}`} className="border-t border-[var(--color-border)]">
                <td className="py-2 font-mono text-[var(--color-text-secondary)]">{segment.date}</td>

                <td className="py-2">{formatDateTime(segment.start)}</td>

                <td className="py-2">
                  {segment.end === null ? "Active" : formatDateTime(segment.end)}
                </td>

                <td className="py-2 font-mono">{formatDuration(segment.start, segment.end)}</td>

                <td className="py-2">
                  <span className="rounded-full border border-[var(--color-border)] px-2 py-0.5 text-xs">
                    {segment.type}
                  </span>
                </td>
              </tr>
            ))}

            {rows.length === 0 ? (
              <tr>
                <td className="py-4 text-[var(--color-text-secondary)]" colSpan={5}>
                  No sessions available.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </section>
  );
}
