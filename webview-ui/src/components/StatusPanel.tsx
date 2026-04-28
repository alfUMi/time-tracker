import { TimerState } from "../types";
import { TimerViewState } from "../hooks/useTimerState";

interface StatusPanelProps {
  state: TimerState;

  elapsed: number;

  viewState: TimerViewState;

  onStart: () => void;

  onStop: () => void;

  onStartBreak: () => void;

  onEndBreak: () => void;

  onExtend: () => void;
}

function formatElapsed(elapsedMs: number): string {
  const totalSeconds = Math.floor(elapsedMs / 1000);
  const seconds = `${totalSeconds % 60}`.padStart(2, "0");
  const minutes = `${Math.floor((totalSeconds / 60) % 60)}`.padStart(2, "0");
  const hours = `${Math.floor(totalSeconds / 3600)}`.padStart(2, "0");

  return `${hours}:${minutes}:${seconds}`;
}

function stateDotClass(state: TimerState): string {
  if (state === "working") {
    return "bg-[var(--color-accent-work)]";
  }

  if (state === "on_break") {
    return "bg-[var(--color-accent-break)]";
  }

  if (state === "extended") {
    return "bg-amber-400";
  }

  return "bg-[var(--color-accent-idle)]";
}

export function StatusPanel({
  state,
  elapsed,
  viewState,
  onStart,
  onStop,
  onStartBreak,
  onEndBreak,
  onExtend
}: StatusPanelProps): JSX.Element {
  return (
    <section className="rounded-[12px] border border-[var(--color-border)] bg-[var(--color-surface-raised)] p-4">
      <header className="mb-3 flex items-center gap-2 text-xs uppercase tracking-[0.12em] text-[var(--color-text-dim)]">
        <span className={`h-2.5 w-2.5 rounded-full ${stateDotClass(state)}`} />
        <span>{viewState.label}</span>
      </header>

      <p className="font-mono text-4xl tracking-tight">{formatElapsed(elapsed)}</p>

      <div className="mt-4 flex flex-wrap gap-2">
        <button className="btn" disabled={!viewState.canStart} onClick={onStart}>
          Start
        </button>

        <button className="btn" disabled={!viewState.canStop} onClick={onStop}>
          Stop
        </button>

        <button className="btn" disabled={!viewState.canStartBreak} onClick={onStartBreak}>
          Start Break
        </button>

        <button className="btn" disabled={!viewState.canEndBreak} onClick={onEndBreak}>
          End Break
        </button>

        <button className="btn" disabled={!viewState.canExtend} onClick={onExtend}>
          Extend Work
        </button>
      </div>
    </section>
  );
}
