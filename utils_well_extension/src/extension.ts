import * as vscode from 'vscode';
import * as commandsProvider from './commands_provider';
import * as featureCreatorPanel from './feature_creator_panel';

export function activate(context: vscode.ExtensionContext) {
  commandsProvider.activate(context);
  featureCreatorPanel.activate(context);
}
