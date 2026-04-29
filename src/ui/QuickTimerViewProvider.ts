import * as vscode from "vscode";

import { TimerEngine } from "../tracker/TimerEngine";

interface QuickTimerViewProviderOptions {
  timerEngine: TimerEngine;

  onExtendRequested: () => void;

  onOpenDashboard: () => void;
}

type QuickViewInboundMessage =
  | { type: "start" }
  | { type: "stop" }
  | { type: "startBreak" }
  | { type: "endBreak" }
  | { type: "extend" }
  | { type: "openDashboard" };

type QuickViewOutboundMessage = {
  type: "stateUpdate";
  state: "idle" | "working" | "on_break" | "extended";
  elapsed: number;
};

export class QuickTimerViewProvider implements vscode.WebviewViewProvider {
  public static readonly viewType = "timeTracker.quickTimerView";

  private view: vscode.WebviewView | undefined;

  constructor(private readonly options: QuickTimerViewProviderOptions) {}

  public resolveWebviewView(webviewView: vscode.WebviewView): void {
    this.view = webviewView;

    webviewView.webview.options = {
      enableScripts: true
    };

    webviewView.webview.html = this.getHtml(webviewView.webview);

    webviewView.webview.onDidReceiveMessage((message: QuickViewInboundMessage) => {
      void this.handleMessage(message);
    });

    this.refresh();
  }

  public refresh(): void {
    if (!this.view) {
      return;
    }

    const payload: QuickViewOutboundMessage = {
      type: "stateUpdate",
      state: this.options.timerEngine.getState(),
      elapsed: this.options.timerEngine.getElapsedMs()
    };

    void this.view.webview.postMessage(payload);
  }

  private async handleMessage(message: QuickViewInboundMessage): Promise<void> {
    if (message.type === "start") {
      await this.options.timerEngine.start();

      return;
    }

    if (message.type === "stop") {
      await this.options.timerEngine.stop();

      return;
    }

    if (message.type === "startBreak") {
      await this.options.timerEngine.startBreak();

      return;
    }

    if (message.type === "endBreak") {
      await this.options.timerEngine.endBreak();

      return;
    }

    if (message.type === "extend") {
      this.options.onExtendRequested();

      return;
    }

    this.options.onOpenDashboard();
  }

  private getHtml(_webview: vscode.Webview): string {
    const nonce = this.createNonce();

    return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta
      http-equiv="Content-Security-Policy"
      content="default-src 'none'; style-src 'unsafe-inline'; script-src 'nonce-${nonce}';"
    />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      body {
        margin: 0;
        padding: 10px;
        font-family: var(--vscode-font-family);
        color: var(--vscode-foreground);
      }

      .state {
        font-size: 12px;
        opacity: 0.8;
        margin-bottom: 8px;
      }

      .timer {
        font-family: var(--vscode-editor-font-family, monospace);
        font-size: 22px;
        margin-bottom: 10px;
      }

      .row {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 6px;
        margin-bottom: 6px;
      }

      button {
        border: 1px solid var(--vscode-button-border, transparent);
        border-radius: 5px;
        background: var(--vscode-button-background);
        color: var(--vscode-button-foreground);
        padding: 6px;
        cursor: pointer;
      }

      button.secondary {
        background: var(--vscode-input-background);
        color: var(--vscode-input-foreground);
      }

      button:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }
    </style>
  </head>
  <body>
    <div id="state" class="state">Stopped</div>
    <div id="timer" class="timer">00:00:00</div>

    <div class="row">
      <button id="start">Start</button>
      <button id="stop">Stop</button>
    </div>

    <div class="row">
      <button id="startBreak" class="secondary">Start Break</button>
      <button id="endBreak" class="secondary">End Break</button>
    </div>

    <div class="row">
      <button id="extend" class="secondary">Extend</button>
      <button id="openDashboard" class="secondary">Dashboard</button>
    </div>

    <script nonce="${nonce}">
      const vscode = acquireVsCodeApi();

      const byId = (id) => document.getElementById(id);

      const stateEl = byId("state");
      const timerEl = byId("timer");

      const controls = {
        start: byId("start"),
        stop: byId("stop"),
        startBreak: byId("startBreak"),
        endBreak: byId("endBreak"),
        extend: byId("extend")
      };

      function formatElapsed(elapsedMs) {
        const totalSeconds = Math.floor(elapsedMs / 1000);
        const seconds = String(totalSeconds % 60).padStart(2, "0");
        const minutes = String(Math.floor((totalSeconds / 60) % 60)).padStart(2, "0");
        const hours = String(Math.floor(totalSeconds / 3600)).padStart(2, "0");

        return hours + ":" + minutes + ":" + seconds;
      }

      function stateLabel(state) {
        if (state === "working") return "Working";
        if (state === "on_break") return "On Break";
        if (state === "extended") return "Extended";
        return "Stopped";
      }

      function applyState(state) {
        controls.start.disabled = state !== "idle";
        controls.stop.disabled = state === "idle";
        controls.startBreak.disabled = !(state === "working" || state === "extended");
        controls.endBreak.disabled = state !== "on_break";
        controls.extend.disabled = state !== "working";
      }

      window.addEventListener("message", (event) => {
        const message = event.data;
        if (!message || message.type !== "stateUpdate") return;

        stateEl.textContent = stateLabel(message.state);
        timerEl.textContent = formatElapsed(message.elapsed);
        applyState(message.state);
      });

      byId("start").addEventListener("click", () => vscode.postMessage({ type: "start" }));
      byId("stop").addEventListener("click", () => vscode.postMessage({ type: "stop" }));
      byId("startBreak").addEventListener("click", () => vscode.postMessage({ type: "startBreak" }));
      byId("endBreak").addEventListener("click", () => vscode.postMessage({ type: "endBreak" }));
      byId("extend").addEventListener("click", () => vscode.postMessage({ type: "extend" }));
      byId("openDashboard").addEventListener("click", () => vscode.postMessage({ type: "openDashboard" }));

      applyState("idle");
    </script>
  </body>
</html>`;
  }

  private createNonce(): string {
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    let value = "";

    for (let index = 0; index < 24; index += 1) {
      value += alphabet[Math.floor(Math.random() * alphabet.length)];
    }

    return value;
  }
}
