import * as vscode from 'vscode';
import * as path from 'path';

const commands = [
    { "cmd": 'Criador de Feature', "contextValue": 'featureCreator' },
    { "cmd": 'flutter clean && flutter pub get', "contextValue": 'runTerminalCommand' },
    { "cmd": 'rm pubspec.lock && flutter clean && flutter pub get', "contextValue": 'runTerminalCommand' },
    { "cmd": 'cd ios && rm Podfile.lock && pod install --repo-update', "contextValue": 'runTerminalCommand' },
    { "cmd": 'very_good test --test-randomize-ordering-seed=random', "contextValue": 'runTerminalCommand' },
];

export function activate(context: vscode.ExtensionContext) {
    context.subscriptions.push(
        vscode.window.registerTreeDataProvider(
            'ailosDevTools-commands',
            new AilosCommandsProvider()
        )
    );
    context.subscriptions.push(
        vscode.commands.registerCommand('ailosDevTools.runCommand', runCommand)
    );
}

class AilosCommandsProvider implements vscode.TreeDataProvider<vscode.TreeItem> {

    getTreeItem(element: vscode.TreeItem): vscode.TreeItem | Thenable<vscode.TreeItem> {
        return element;
    }

    getChildren(element?: vscode.TreeItem | undefined): vscode.ProviderResult<vscode.TreeItem[]> {
        const items = [
            ...(element ? [element] : []),
            ...commands.map(command => {
                const item = new vscode.TreeItem(command.cmd);
                item.contextValue = command.contextValue;
                return item;
            })
        ];
        return items;
    }

}

function runCommand(commandLabel: any) {
    let command: string | undefined;
    if (commandLabel && typeof commandLabel === 'object' && 'label' in commandLabel) {
        command = commandLabel.label;
    } else {
        vscode.window.showQuickPick(
            commands.map(e => e.cmd),
            {
                placeHolder: 'Select a command to run',
                canPickMany: false
            }
        ).then(selected => command = selected);
    }

    console.log('Running command', command);

    if (!command) { return; }

    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders || workspaceFolders.length === 0) {
        return vscode.window.showInformationMessage('No workspace or project folder open.');
    }

    if (workspaceFolders.length === 1) {
        return runTerminal(command, workspaceFolders[0].uri.fsPath);
    }

    const dirs = workspaceFolders.map(folder => ({
        label: path.basename(folder.uri.fsPath),
        description: folder.uri.fsPath,
        uri: folder.uri
    }));

    vscode.window.showQuickPick(
        dirs,
        {
            placeHolder: 'Select a command to run',
            canPickMany: false
        }
    ).then(selected => {
        if (!selected || !command) { return; }
        runTerminal(command, selected.uri.fsPath);
    });
}

function runTerminal(command: string, cwd: string) {
    const terminalName = `Ailos Dev Tools`;
    const existingTerminal = vscode.window.terminals.find(t => t.name === terminalName);
    const terminal = existingTerminal ?? vscode.window.createTerminal({ name: terminalName, cwd: cwd });
    terminal.show(true);
    if (existingTerminal) { terminal.sendText(`cd ${cwd}`, true); }
    terminal.sendText(command, true);
}