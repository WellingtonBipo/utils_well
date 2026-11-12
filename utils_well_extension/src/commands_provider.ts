import * as vscode from 'vscode';
import * as path from 'path';

const _extensionId = 'devUtilsWell';

export function activate(context: vscode.ExtensionContext) {
    let treeView = new CommandsProvider(context);
    context.subscriptions.push(
        vscode.window.registerTreeDataProvider(`${_extensionId}-commands`, treeView),
        vscode.commands.registerCommand(`${_extensionId}.openUserSettings`, () => treeView.openUserSettings()),
        vscode.commands.registerCommand(`${_extensionId}.copyCommand`, _copyCommand),
        vscode.commands.registerCommand(`${_extensionId}.runCommand`, (e) => _runCommand(treeView, e)),
        vscode.commands.registerCommand(`${_extensionId}.addCommand`, () => _addCommand()),
        vscode.commands.registerCommand(`${_extensionId}.editCommand`, (e) => _editCommand(treeView, e)),
        vscode.commands.registerCommand(`${_extensionId}.deleteCommand`, (e) => _deleteCommand(treeView, e))
    );
}

class Item extends vscode.TreeItem {
    constructor(public readonly cmd: string, label?: string, public readonly ownTerminal: boolean = false) {
        super(label ? label : cmd, vscode.TreeItemCollapsibleState.None);
        if (cmd !== '') {
            this.contextValue = `${_extensionId}.runTerminalCommand`;
            const tooltip = new vscode.MarkdownString();
            if (label) tooltip.appendText(`${label}\n`);
            tooltip.appendCodeblock(cmd, 'shell');
            if (ownTerminal) tooltip.appendMarkdown('\n\n_Executa em terminal próprio_');
            this.tooltip = tooltip;
        }
    }

    /** Position of this command in the `devUtilsWell.commands.list` setting. */
    index?: number;

    static featureCreator(): Item {
        const i = new Item('Feature creator', '');
        i.contextValue = `${_extensionId}.featureCreator`;
        i.tooltip = 'Abre o criador de features';
        return i;
    }

    static tagVersionCreator(): Item {
        const i = new Item('Tag version creator', '');
        i.contextValue = `${_extensionId}.tagVersionCreator`;
        i.tooltip = 'Cria a tag de versão a partir do pubspec.yaml (tag_version_creator)';
        i.iconPath = new vscode.ThemeIcon('tag');
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
        this.items = [Item.featureCreator(), Item.tagVersionCreator(), new Item('')];
        const list = commands?.list || [];
        for (let index = 0; index < list.length; index++) {
            const commandData = list[index];
            if (!commandData || typeof commandData !== 'object') continue;
            const cmd = commandData['command'];
            const label = commandData['label'];
            const ownTerminal = commandData['ownTerminal'];
            if (!cmd || typeof cmd !== 'string') continue;
            if (label && typeof label !== 'string') continue;
            if (ownTerminal && typeof ownTerminal !== 'boolean') continue;
            const item = new Item(cmd, label, ownTerminal);
            item.index = index;
            const itemConfig = commands?.config?.find(c => c['label'] === item.finalLabel);
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

// ---------------------------------------------------------------------------
// Add / edit commands (persisted in the `devUtilsWell.commands.list` setting)
// ---------------------------------------------------------------------------

interface CommandData {
    label?: string;
    command: string;
    ownTerminal?: boolean;
}

/** Returns the settings scope that currently provides `commands.list` (Global when none). */
function _listTarget(): { config: vscode.WorkspaceConfiguration, target: vscode.ConfigurationTarget, list: any[] } {
    const config = vscode.workspace.getConfiguration(`${_extensionId}.commands`);
    const inspect = config.inspect<any[]>('list');
    if (inspect?.workspaceFolderValue !== undefined) {
        return { config, target: vscode.ConfigurationTarget.WorkspaceFolder, list: [...inspect.workspaceFolderValue] };
    }
    if (inspect?.workspaceValue !== undefined) {
        return { config, target: vscode.ConfigurationTarget.Workspace, list: [...inspect.workspaceValue] };
    }
    return { config, target: vscode.ConfigurationTarget.Global, list: [...(inspect?.globalValue ?? [])] };
}

async function _askCommandData(title: string, current?: Item): Promise<CommandData | undefined> {
    const command = await vscode.window.showInputBox({
        title,
        prompt: 'Comando a ser executado no terminal',
        value: current?.cmd,
        ignoreFocusOut: true,
        validateInput: text => text.trim() ? undefined : 'O comando é obrigatório',
    });
    if (command === undefined) return;

    const currentLabel = current && current.finalLabel !== current.cmd ? current.finalLabel : '';
    const label = await vscode.window.showInputBox({
        title,
        prompt: 'Nome exibido na lista (deixe vazio para mostrar o próprio comando)',
        value: currentLabel,
        ignoreFocusOut: true,
    });
    if (label === undefined) return;

    const sharedTerminal = { label: 'Terminal compartilhado', description: '"Utils Well"', value: false };
    const ownTerminal = { label: 'Terminal próprio', description: 'um terminal só para este comando', value: true };
    const terminalOptions = current?.ownTerminal ? [ownTerminal, sharedTerminal] : [sharedTerminal, ownTerminal];
    const terminal = await vscode.window.showQuickPick(terminalOptions, {
        title,
        placeHolder: 'Onde executar o comando?',
        ignoreFocusOut: true,
    });
    if (!terminal) return;

    const data: CommandData = { command: command.trim() };
    if (label.trim()) data.label = label.trim();
    if (terminal.value) data.ownTerminal = true;
    return data;
}

async function _addCommand() {
    const data = await _askCommandData('Utils Well: Novo comando');
    if (!data) return;
    const { config, target, list } = _listTarget();
    list.push(data);
    await config.update('list', list, target);
    vscode.window.showInformationMessage(`Comando "${data.label ?? data.command}" adicionado.`);
}

async function _editCommand(treeView: CommandsProvider, item?: Item) {
    if (!item) {
        const editable = treeView.items.filter(i => i.index !== undefined);
        item = await _getUserItemSelection('Selecione o comando para editar', editable, i => i.finalLabel);
    }
    if (!item || item.index === undefined) return;

    const data = await _askCommandData(`Utils Well: Editar "${item.finalLabel}"`, item);
    if (!data) return;

    const { config, target, list } = _listTarget();
    const previous = list[item.index];
    if (!previous || previous['command'] !== item.cmd) {
        vscode.window.showErrorMessage('A lista de comandos mudou. Tente editar novamente.');
        return;
    }
    // Keep any extra keys the user may have written manually in settings.json.
    const updated: any = { ...previous, ...data };
    if (!data.label) delete updated.label;
    if (!data.ownTerminal) delete updated.ownTerminal;
    list[item.index] = updated;
    await config.update('list', list, target);

    // `commands.config` entries (folders) are keyed by label: follow a rename.
    const newLabel = data.label ?? data.command;
    if (newLabel !== item.finalLabel) {
        const inspect = config.inspect<any[]>('config');
        const scoped = target === vscode.ConfigurationTarget.WorkspaceFolder ? inspect?.workspaceFolderValue
            : target === vscode.ConfigurationTarget.Workspace ? inspect?.workspaceValue
                : inspect?.globalValue;
        if (scoped?.some(c => c?.['label'] === item!.finalLabel)) {
            const renamed = scoped.map(c => c?.['label'] === item!.finalLabel ? { ...c, label: newLabel } : c);
            await config.update('config', renamed, target);
        }
    }
    vscode.window.showInformationMessage(`Comando "${newLabel}" atualizado.`);
}

async function _deleteCommand(treeView: CommandsProvider, item?: Item) {
    if (!item) {
        const deletable = treeView.items.filter(i => i.index !== undefined);
        item = await _getUserItemSelection('Selecione o comando para deletar', deletable, i => i.finalLabel);
    }
    if (!item || item.index === undefined) return;

    const confirmLabel = 'Deletar';
    const answer = await vscode.window.showWarningMessage(
        `Deletar o comando "${item.finalLabel}"?`,
        { modal: true, detail: item.cmd },
        confirmLabel,
    );
    if (answer !== confirmLabel) return;

    const { config, target, list } = _listTarget();
    const previous = list[item.index];
    if (!previous || previous['command'] !== item.cmd) {
        vscode.window.showErrorMessage('A lista de comandos mudou. Tente deletar novamente.');
        return;
    }
    list.splice(item.index, 1);
    await config.update('list', list, target);
    vscode.window.showInformationMessage(`Comando "${item.finalLabel}" deletado.`);
}
