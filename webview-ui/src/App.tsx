import { useCallback, useEffect, useState } from "react";

import { SettingsPanel } from "./components/SettingsPanel";
import { StatsPanel } from "./components/StatsPanel";
import { StatusPanel } from "./components/StatusPanel";
import { useTimerState } from "./hooks/useTimerState";
import { useVSCodeMessage } from "./hooks/useVSCodeMessage";
import { DayRecord, Settings, StatsPeriod, TimerState, WebviewMessage } from "./types";
import { vscodeApi } from "./vscode";

export function App(): JSX.Element {
  const [state, setState] = useState<TimerState>("idle");

  const [elapsed, setElapsed] = useState<number>(0);

  const [period, setPeriod] = useState<StatsPeriod>("day");

  const [records, setRecords] = useState<DayRecord[]>([]);

  const [settings, setSettings] = useState<Settings | null>(null);

  const timerState = useTimerState(state);

  const onMessage = useCallback((message: WebviewMessage) => {
    if (message.type === "stateUpdate") {
      setState(message.state);
      setElapsed(message.elapsed);

      return;
    }

    if (message.type === "statsData") {
      setPeriod(message.period);
      setRecords(message.records);

      return;
    }

    if (message.type === "settingsData") {
      setSettings(message.settings);
    }
  }, []);

  useVSCodeMessage(onMessage);

  useEffect(() => {
    vscodeApi.postMessage({ type: "requestStats", period: "day" });

    vscodeApi.postMessage({ type: "requestSettings" });
  }, []);

  return (
    <main className="mx-auto max-w-6xl space-y-4 p-4">
      <div className="panel-fade">
        <StatusPanel
          state={state}
          elapsed={elapsed}
          viewState={timerState}
          onStart={() => {
            vscodeApi.postMessage({ type: "start" });
          }}
          onStop={() => {
            vscodeApi.postMessage({ type: "stop" });
          }}
          onStartBreak={() => {
            vscodeApi.postMessage({ type: "startBreak" });
          }}
          onEndBreak={() => {
            vscodeApi.postMessage({ type: "endBreak" });
          }}
          onExtend={() => {
            vscodeApi.postMessage({ type: "extend" });
          }}
        />
      </div>

      <div className="panel-fade">
        <StatsPanel
          period={period}
          records={records}
          onChangePeriod={(next) => {
            vscodeApi.postMessage({ type: "requestStats", period: next });
          }}
        />
      </div>

      <div className="panel-fade">
        <SettingsPanel
          settings={settings}
          onSave={(nextSettings) => {
            vscodeApi.postMessage({ type: "saveSettings", settings: nextSettings });
          }}
        />
      </div>
    </main>
  );
}
