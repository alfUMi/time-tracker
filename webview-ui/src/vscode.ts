import { ExtensionMessage } from "./types";

interface VSCodeApi {
  postMessage(message: ExtensionMessage): void;

  getState<TState>(): TState | undefined;

  setState<TState>(state: TState): void;
}

declare global {
  interface Window {
    acquireVsCodeApi?: () => VSCodeApi;
  }
}

const fallbackApi: VSCodeApi = {
  postMessage: (message) => {
    console.log("[time-tracker] mock postMessage", message);
  },

  getState: () => undefined,

  setState: () => {}
};

export const vscodeApi: VSCodeApi =
  typeof window.acquireVsCodeApi === "function"
    ? window.acquireVsCodeApi()
    : fallbackApi;
