import * as vscode from "vscode";

export class NotificationService {
  public async showInfoWithActions(
    message: string,
    actions: string[]
  ): Promise<string | undefined> {
    return vscode.window.showInformationMessage(message, ...actions);
  }

  public async showWarningWithActions(
    message: string,
    actions: string[]
  ): Promise<string | undefined> {
    return vscode.window.showWarningMessage(message, ...actions);
  }
}
