import { useMemo } from "react";

import { TimerState } from "../types";

export interface TimerViewState {
  label: string;

  canStart: boolean;

  canStop: boolean;

  canStartBreak: boolean;

  canEndBreak: boolean;

  canExtend: boolean;
}

export function useTimerState(state: TimerState): TimerViewState {
  return useMemo(() => {
    if (state === "idle") {
      return {
        label: "Stopped",
        canStart: true,
        canStop: false,
        canStartBreak: false,
        canEndBreak: false,
        canExtend: false
      };
    }

    if (state === "on_break") {
      return {
        label: "On Break",
        canStart: false,
        canStop: true,
        canStartBreak: false,
        canEndBreak: true,
        canExtend: false
      };
    }

    if (state === "extended") {
      return {
        label: "Extended",
        canStart: false,
        canStop: true,
        canStartBreak: true,
        canEndBreak: false,
        canExtend: false
      };
    }

    return {
      label: "Working",
      canStart: false,
      canStop: true,
      canStartBreak: true,
      canEndBreak: false,
      canExtend: true
    };
  }, [state]);
}
