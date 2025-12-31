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

    folders: string[] = [];

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
        const commands = config.get<{ list: any[], config: any[] }>('commands');
        if (!commands) return;
        this.items = [Item.featureCreator(), new Item('')];
        for (let commandData of commands.list || []) {
            if (!commandData && typeof commandData !== 'object') continue;
            const cmd = commandData['command'];
            const label = commandData['label'];
            const ownTerminal = commandData['ownTerminal'];
            if (!cmd || typeof cmd !== 'string') continue;
            if (label && typeof label !== 'string') continue;
            if (ownTerminal && typeof ownTerminal !== 'boolean') continue;
            const item = new Item(cmd, label, ownTerminal);
            const itemConfig = commands.config?.find(c => c['label'] === item.finalLabel);
            const folders = itemConfig && itemConfig['folders'];
            if (folders && Array.isArray(folders)) {
                item.folders = folders;
            }
            this.items.push(item);
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

async function _runCommand(treeView: CommandsProvider, item?: Item) {
    if (!item) {
        item = await _getUserItemSelection('Select a command to run', treeView.items, item => item.finalLabel);
    }

    if (!item) return;

    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders || workspaceFolders.length === 0) {
        return vscode.window.showInformationMessage('No workspace or project folder open.');
    }

    if (workspaceFolders.length === 1) {
        return _runOnTerminal(item, workspaceFolders[0].uri.fsPath);
    }

    const folder = await _getUserItemSelection(
        'Select a folder to run the command',
        [...workspaceFolders],
        f => path.basename(f.uri.fsPath)
    );
    if (!folder) return;
    _runOnTerminal(item, folder.uri.fsPath);
}

function _copyCommand(item: Item) {
    vscode.env.clipboard.writeText(item.cmd);
    vscode.window.showInformationMessage(`Command copied to clipboard: ${item.finalLabel} `);
}

async function _runOnTerminal(item: Item, f: string) {
    let folder = f;
    if (item.folders.length > 0) {
        const subFolder = await _getUserItemSelection(
            'Select a subfolder to run the command',
            item.folders,
            subfolder => subfolder
        );
        if (!subFolder) return;
        folder = path.join(folder, subFolder);
    }
    const terminalName = item.ownTerminal ? `Utils Well - ${item.finalLabel} - ${folder} ` : `Utils Well`;
    const existingTerminal = vscode.window.terminals.find(t => t.name === terminalName);
    const terminal = existingTerminal ?? vscode.window.createTerminal({ name: terminalName, cwd: folder });
    terminal.show(true);
    if (existingTerminal) terminal.sendText(`cd ${folder} `, true);
    terminal.sendText(item.cmd, true);
}

async function _getUserItemSelection<T>(
    description: string,
    items: T[],
    itemToLabel: (item: T) => string,
): Promise<T | undefined> {
    const selectionItem = [];
    for (let item of items) {
        selectionItem.push({
            label: itemToLabel(item),
            value: item
        });
    }
    const item = await vscode.window.showQuickPick(
        selectionItem,
        {
            placeHolder: description,
            canPickMany: false
        }
    );
    return item?.value;
}
