import * as vscode from 'vscode';
import * as path from 'path';

const _extensionId = 'devUtilsWell';

export function activate(context: vscode.ExtensionContext) {
    let treeView = new CommandsProvider(context);
    context.subscriptions.push(
        vscode.window.registerTreeDataProvider(`${_extensionId}-commands`, treeView),
        vscode.commands.registerCommand(`${_extensionId}.openUserSettings`, () => treeView.openUserSettings()),
        vscode.commands.registerCommand(`${_extensionId}.copyCommand`, _copyCommand),
        vscode.commands.registerCommand(`${_extensionId}.runCommand`, (e) => _runCommand(treeView, e))
    );
}

class Item extends vscode.TreeItem {
    constructor(public readonly cmd: string, label?: string, public readonly ownTerminal: boolean = false) {
        super(label ? label : cmd, vscode.TreeItemCollapsibleState.None);
        if (cmd !== '') this.contextValue = `${_extensionId}.runTerminalCommand`;
    }

    static featureCreator(): Item {
        const i = new Item('Feature creator', '');
        i.contextValue = `${_extensionId}.featureCreator`;
        return i;
    }

    get finalLabel(): string {
        return (this.label as string) ?? this.cmd;
    }
}

class CommandsProvider implements vscode.TreeDataProvider<Item> {

    items: Item[] = [];

    constructor(private context: vscode.ExtensionContext) {
        this.loadItems();
        vscode.workspace.onDidChangeConfiguration(event => {
            if (event.affectsConfiguration(`${_extensionId}.commands`)) {
                this.loadItems(true);
            }
        });
    }

    private loadItems(refresh: boolean = false) {
        const config = vscode.workspace.getConfiguration(_extensionId);
        const commands = config.get<Array<any>>('commands');
        this.items = [Item.featureCreator(), new Item('')];
        for (let commandData of commands || []) {
            if (!commandData && typeof commandData !== 'object') continue;
            const cmd = commandData['command'];
            const label = commandData['label'];
            const ownTerminal = commandData['ownTerminal'];
            if (!cmd || typeof cmd !== 'string') continue;
            if (label && typeof label !== 'string') continue;
            if (ownTerminal && typeof ownTerminal !== 'boolean') continue;
            this.items.push(new Item(cmd, label, ownTerminal));
        }
        if (refresh) this._onDidChangeTreeData.fire();
    }


    private _onDidChangeTreeData =
        new vscode.EventEmitter<Item | undefined | null | void>();

    readonly onDidChangeTreeData =
        this._onDidChangeTreeData.event;

    getTreeItem(element: Item): Item | Thenable<Item> {
        return element;
    }

    getChildren(element?: Item | undefined): vscode.ProviderResult<Item[]> {
        return this.items;
    }

    openUserSettings() {
        vscode.commands.executeCommand('workbench.action.openSettingsJson');
    }
}

function _runCommand(treeView: CommandsProvider, item?: Item) {
    if (!item) {
        const cmds = [];
        for (let e of treeView.items) {
            if (e.contextValue !== `${_extensionId}.runTerminalCommand`) continue;
            cmds.push({
                label: e.finalLabel,
                item: e
            });
        }
        vscode.window.showQuickPick(
            cmds,
            {
                placeHolder: 'Select a command to run',
                canPickMany: false
            }
        ).then(selected => item = selected?.item);
    }

    if (!item) return;

    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders || workspaceFolders.length === 0) {
        return vscode.window.showInformationMessage('No workspace or project folder open.');
    }

    if (workspaceFolders.length === 1) {
        return _runOnTerminal(item, workspaceFolders[0].uri.fsPath);
    }

    const dirs = workspaceFolders.map(folder => ({
        label: path.basename(folder.uri.fsPath),
        description: folder.uri.fsPath,
        uri: folder.uri
    }));

    vscode.window.showQuickPick(
        dirs,
        {
            placeHolder: 'Select a folder to run',
            canPickMany: false
        }
    ).then(selected => {
        if (!selected) return;
        _runOnTerminal(item!, selected.uri.fsPath);
    });
}

function _copyCommand(item: Item) {
    vscode.env.clipboard.writeText(item.cmd);
    vscode.window.showInformationMessage(`Command copied to clipboard: ${item.finalLabel}`);
}

function _runOnTerminal(item: Item, folder: string) {
    const terminalName = item.ownTerminal ? `Utils Well - ${item.finalLabel} - ${folder}` : `Utils Well`;
    const existingTerminal = vscode.window.terminals.find(t => t.name === terminalName);
    const terminal = existingTerminal ?? vscode.window.createTerminal({ name: terminalName, cwd: folder });
    terminal.show(true);
    if (existingTerminal) { terminal.sendText(`cd ${folder}`, true); }
    terminal.sendText(item.cmd, true);
}
