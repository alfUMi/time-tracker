import { useEffect } from "react";

import { WebviewMessage } from "../types";

export function useVSCodeMessage(
  onMessage: (message: WebviewMessage) => void
): void {
  useEffect(() => {
    const listener = (event: MessageEvent<WebviewMessage>) => {
      const data = event.data;

      if (!data || typeof data !== "object" || !("type" in data)) {
        return;
      }

      onMessage(data);
    };

    window.addEventListener("message", listener);

    return () => {
      window.removeEventListener("message", listener);
    };
  }, [onMessage]);
}
