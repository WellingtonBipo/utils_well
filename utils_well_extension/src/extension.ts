import * as vscode from 'vscode';
import * as commandsProvider from './ailos_commands_provider';
import * as searchOnReposProvider from './ailos_search_on_repos_provider';
import * as featureCreatorPanel from './ailos_feature_creator_panel';

export function activate(context: vscode.ExtensionContext) {
  commandsProvider.activate(context);
  searchOnReposProvider.activate(context);
  featureCreatorPanel.activate(context);
}
