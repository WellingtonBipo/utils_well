import * as vscode from 'vscode';
import * as fs from 'fs';

export function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider(
      'ailosDevTools-searchOnRepos',
      new AilosSearchOnReposProvider(context)
    )
  );
}

class AilosSearchOnReposProvider implements vscode.WebviewViewProvider {
  private view?: vscode.WebviewView;
  private searchData: string | null = null;
  private context: vscode.ExtensionContext;

  constructor(context: vscode.ExtensionContext) {
    this.context = context;
  }

  public resolveWebviewView(
    webviewView: vscode.WebviewView,
    _context: vscode.WebviewViewResolveContext,
    _token: vscode.CancellationToken,
  ) {
    this.view = webviewView;
    webviewView.webview.options = { enableScripts: true };
    webviewView.webview.html = this._getHtmlWebview();
    webviewView.webview.onDidReceiveMessage(
      message => {
        vscode.window.showWarningMessage(message);
        if (message.command === 'openFile') { return this._openFile(message.arg); }
        if (message.command === 'search') { return this._search(message.arg); }
        console.log(`Message unhandled: ${message}`);
      }
    );
  }

  private _getHtmlWebview({ results, loading }: { results?: FolderFound[], loading?: boolean } = {}) {
    const body = `
    <body>
      <div class="input-group">
        <input id="searchInput" type="text" placeholder="Buscar..."${this.searchData ? ` value="${this.searchData}"` : ''}${loading ? ' disabled' : ''} />
        <div class="right">
          ${loading ? `<div class="spinner"></div>` : `<span class="icon" id="searchIcon">&#128269;</span>`}
        </div>
      </div>
      ${!results || results.length === 0 ? '' : `<div style="padding-bottom: 4px; display: flex; justify-content: flex-end;"><span>${results.reduceRight((a, b) => a + b.count, 0)} resultados</span></div>`}
      ${!results ? '' : [`<div id="results">`, ...results.map(e => e.html(0)).flat().map(e => `  ${e}`), `</div>`].join('\n      ')}
    </body>
`;
    return `
<!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    </head>
    <style>
      ${this.styles.join('\n      ')}
    </style>
${body}
    <script>
      // setTimeout(() => vscode.postMessage('test'), 5000);
      ${this.scripts.join('\n      ')}
    </script>
  </html>`;

  }

  get styles(): string[] {
    return [
      'body {',
      '  background-color: transparent;',
      '  color: #d4d4d4;',
      '  font-family: Segoe WPC, Segoe UI, sans-serif;',
      '  margin: 0;',
      '  padding: 16px;',
      '}',
      '',
      '.input-group {',
      '  background-color: #2d2d2d;',
      '  border: 1px solid #3c3c3c;',
      '  border-radius: 3px;',
      '  display: flex;',
      '  align-items: center;',
      '  padding: 6px 6px;',
      '  margin-bottom: 12px;',
      '}',
      '',
      '.input-group input {',
      '  flex: 1;',
      '  background-color: transparent;',
      '  border: none;',
      '  outline: none;',
      '  color: #d4d4d4;',
      '  font-size: 14px;',
      '}',
      '',
      '.input-group:focus-within {',
      '  border-color: #0078d4;',
      '}',
      '',
      '.icon {',
      '  color: #bbbbbb;',
      '  cursor: pointer;',
      '  font-size: 14px;',
      '  transition: color 0.2s;',
      '}',
      '',
      '.icon:hover {',
      '  color: white;',
      '}',
      '',
      '.spinner {',
      '  border: 2px solid #333;',
      '  border-top: 2px solid #0078d4;',
      '  border-radius: 50%;',
      '  width: 16px;',
      '  height: 16px;',
      '  animation: spin 1s linear infinite;',
      '}',
      '',
      '@keyframes spin {',
      '  0% { transform: rotate(0deg);}',
      '  100% { transform: rotate(360deg);}',
      '}',
      '',
      '.explorer-item {',
      '  display: flex;',
      '  align-items: center;',
      '  cursor: pointer;',
      '  user-select: none;',
      '  font-family: var(--vscode-font-family);',
      '  font-size: 13px;',
      '  color: var(--vscode-foreground);',
      '  width: 100%;',
      '  max-width: 100%;',
      '  box-sizing: border-box;',
      '}',
      '',
      '.explorer-item span {',
      '  flex: 1 1 auto;',
      '  min-width: 0;',
      '  overflow: hidden;',
      '  text-overflow: ellipsis;',
      '  white-space: nowrap;',
      '  display: block;',
      '  padding: 5px 0px;',
      '}',
      '',
      '.explorer-item:hover {',
      '  background-color: var(--vscode-list-hoverBackground);',
      '}',
      '',
      '.collapsed::before {',
      `  content: '▶';`,
      '  display: inline-block;',
      '  margin-right: 4px;',
      '  font-size: 10px;',
      '}',
      '',
      '.expanded::before {',
      `  content: '▼';`,
      '  display: inline-block;',
      '  margin-right: 4px;',
      '  font-size: 10px;',
      '}',
      '',
      '.item-count {',
      '  flex: 0 0 auto;',
      '  display: inline-flex;',
      '  align-items: center;',
      '  justify-content: center;',
      '  min-width: 20px;',
      '  height: 20px;',
      '  padding: 0 6px;',
      '  border-radius: 10px;',
      '  background: #444;',
      '  color: #fff;',
      '  text-align: center;',
      '  font-size: 12px;',
      '  margin-left: 8px;',
      '  box-sizing: border-box;',
      '  line-height: 20px;',
      '}',
      '',
      '.hidden {',
      '  display: none;',
      '}',
    ];
  }
  get scripts(): string[] {
    return [
      'const vscode = acquireVsCodeApi();',
      '',
      'document.getElementById("searchInput").addEventListener("keydown", (e) => {',
      '  if (e.key === "Enter" && !e.target.disabled) {',
      '    search();',
      '  }',
      '});',
      '',
      'const searchIcon = document.getElementById("searchIcon");',
      'if (searchIcon) {',
      '  searchIcon.addEventListener("click", () => {',
      '    if (!document.getElementById("searchInput").disabled) {',
      '      search();',
      '    }',
      '  });',
      '}',
      '',
      'function search() {',
      `  const valor = document.getElementById('searchInput').value;`,
      `  vscode.postMessage({ command: 'search', arg: valor });`,
      '}',
      '',
      'function openFile(path) {',
      `  vscode.postMessage({ command: 'openFile', arg: path });`,
      '}',
      '',
      `function toggleFolder(id) {`,
      `  const item = document.querySelector(\`[item-id="\${id}"]\`);`,
      `  const collapsed = item.classList.contains('expanded');`,
      `  item.classList.toggle('expanded', !collapsed);`,
      `  item.classList.toggle('collapsed', collapsed);`,
      `  const content = document.querySelector(\`[content-id="\${id}"]\`);`,
      `  content.classList.toggle('hidden', collapsed);`,
      `}`,
    ];
  }

  private async _openFile(path: string) {
    const [filePath, lineStr] = path.split(':');
    const fileUri = vscode.Uri.file(filePath);
    const lineNumber = parseInt(lineStr, 10) - 1;
    try {
      const doc = await vscode.workspace.openTextDocument(fileUri);
      const editor = await vscode.window.showTextDocument(doc, { preview: false });
      if (!isNaN(lineNumber) && lineNumber >= 0) {
        const position = new vscode.Position(lineNumber, 0);
        editor.selection = new vscode.Selection(position, position);
        editor.revealRange(new vscode.Range(position, position), vscode.TextEditorRevealType.InCenter);
      }
    } catch (err) {
      vscode.window.showErrorMessage(`Não foi possível abrir o arquivo: ${err}`);
    }
  }


  private async _search(data: string) {
    try {
      data = data.trim();
      if (data?.length === 0) {
        this.searchData = null;
        this.view!.webview.html = this._getHtmlWebview();
        return;
      }
      this.searchData = data;
      this.view!.webview.html = this._getHtmlWebview({ loading: true });
      const pubspec = await this.getPubspec();
      const pubspecLock = await this.getPubspecLock();
      const dependenciesRefs = this.getDependenciesRefs(pubspec, pubspecLock);
      const results = this.searchOnRepos(dependenciesRefs);
      this.view!.webview.html = this._getHtmlWebview({ results: results });
    } catch (error) {
      this.view!.webview.html = this._getHtmlWebview();
      vscode.window.showWarningMessage(`${error}`);
    }
  }

  async getPubspec(): Promise<string[]> {
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders || workspaceFolders.length === 0) {
      throw new Error('Nenhuma pasta de workspace aberta.');
    }

    if (!workspaceFolders.find(e => e.uri.path.endsWith('ailos_app'))) {
      throw new Error('Diretório ailos_app não encontrado');
    }

    const pubspecFiles = await vscode.workspace.findFiles('pubspec.yaml');
    if (pubspecFiles.length === 0) {
      throw new Error('Arquivo pubspec.yaml não encontrado.');
    }

    const pubspecFile = pubspecFiles.find(e => e.path.endsWith('ailos_app/pubspec.yaml'));

    if (!pubspecFile) { throw new Error('Arquivo pubspec.yaml não encontrado.'); }

    try {
      const fileData = await vscode.workspace.fs.readFile(pubspecFile);
      const fileContent = Buffer.from(fileData).toString('utf8');
      const lines = fileContent.split(/\r?\n/);
      return lines;
    } catch (error) {
      throw new Error(`Erro ao ler o arquivo pubspec.yaml: ${error}`);
    }
  }

  async getPubspecLock(): Promise<string[]> {
    const pubspecFiles = await vscode.workspace.findFiles('pubspec.lock');
    const pubspecFile = pubspecFiles.find(e => e.path.endsWith('ailos_app/pubspec.lock'));

    if (!pubspecFile) {
      throw new Error('Arquivo pubspec.lock não encontrado.');
    }

    try {
      const fileData = await vscode.workspace.fs.readFile(pubspecFile);
      const fileContent = Buffer.from(fileData).toString('utf8');
      const lines = fileContent.split(/\r?\n/);
      return lines;
    } catch (error) {
      throw new Error(`Erro ao ler o arquivo pubspec.lock: ${error}`);
    }
  }

  getDependenciesRefs(pubspec: string[], pubspecLock: string[]): { repoName: string, commit: string }[] {
    let dependencies: { repoName: string, commit: string }[] = [];
    const url = '      url: git@ssh.dev.azure.com:v3/Ailos/Mobile/';
    const ref = '      resolved-ref: ';
    for (let i = 0; i < pubspec.length; i++) {
      const line = pubspec[i];
      if (!line.startsWith(url)) { continue; }
      const depName = line.replaceAll(url, '').trim();
      let depLocation: { repoName: string, commit: string } | undefined;
      for (let j = 0; j < pubspecLock.length; j++) {
        const line2 = pubspecLock[j];
        if (line2.startsWith(`  ${depName}:`)) {
          const commit = pubspecLock.slice(j).find(e => e.startsWith(ref));
          if (commit) { depLocation = { repoName: depName, commit: commit.replaceAll(ref, '').replaceAll('"', '') }; }
        }
      }
      if (!depLocation) { throw new Error(`Related dep ${depName} not found on pubspec.lock`); }
      dependencies.push(depLocation);
    }
    return dependencies;
  }

  searchOnRepos(dependenciesRefs: { repoName: string, commit: string }[]): FolderFound[] {
    if (process.platform === 'win32') { throw new Error('Windows not implemented'); }
    const pubCacheDir = `${process.env.HOME}/.pub-cache/git`;
    if (!fs.existsSync(pubCacheDir)) {
      throw new Error(`Não foi possível localizar o diretório ${pubCacheDir}`);
    }
    const pubCacheDirUri = vscode.Uri.file(pubCacheDir);
    const results: FolderFound[] = [];
    for (let i = 0; i < dependenciesRefs.length; i++) {
      const ref = dependenciesRefs[i];
      const repoName = `${ref.repoName}-${ref.commit}`;
      const repoPath = `${pubCacheDirUri.path}/${repoName}`;
      if (!fs.existsSync(repoPath)) { throw Error(`Repo ${repoName} not found`); }
      const files = fs.readdirSync(repoPath, { withFileTypes: true, recursive: true });
      const repoResults = this.results([repoName, files]);
      if (repoResults.length !== 0) { results.push(new FolderFound(ref.repoName, repoResults)); }
    }
    return results;
  }

  results(configs: [string, fs.Dirent<string>[]] | { fullPath: string, relativePath: string }[])
    : (FolderFound | FileFound)[] {
    let repoNameDir: string | undefined;
    let confs: (fs.Dirent<string> | { fullPath: string, relativePath: string })[];

    if (configs.length === 2 && typeof configs[0] === 'string') {
      repoNameDir = configs[0] as string;
      confs = configs[1] as fs.Dirent<string>[];
    } else {
      confs = configs as any;
    }

    const folders: { [name: string]: { fullPath: string, relativePath: string }[] } = {};
    const files: FileFound[] = [];
    for (let i = 0; i < confs.length; i++) {
      const config = confs[i];
      let fullPath: string, relativePath: string;

      if (config instanceof fs.Dirent) {
        if (!config.isFile()) { continue; }
        fullPath = `${config.parentPath}/${config.name}`;
        relativePath = fullPath.split(repoNameDir!)[1];
      } else {
        fullPath = config.fullPath;
        relativePath = config.relativePath;
      }

      if (!relativePath.endsWith('.dart')) { continue; }
      if (relativePath.startsWith('/')) { relativePath = relativePath.substring(1); }

      if (!relativePath.includes('/')) {
        const file = fs.readFileSync(fullPath);
        const fileLines = Buffer.from(file).toString('utf8').split(/\r?\n/);
        const lines: [number, string][] = [];
        for (let i = 0; i < fileLines.length; i++) {
          const line = fileLines[i];
          if (line.includes(this.searchData!)) { lines.push([i + 1, line]); }
        }
        if (lines.length !== 0) { files.push(new FileFound(fullPath, lines)); }
      } else {
        const parts = relativePath.split('/');
        const relaPath = relativePath.replaceAll(`${parts[0]}/`, '');
        folders[parts[0]] = [
          ...(parts[0] in folders ? folders[parts[0]] : []),
          { fullPath: fullPath, relativePath: relaPath },
        ];
      }
    }

    const folderValues: FolderFound[] = [];
    const folderEntries = Object.entries(folders);
    for (let index = 0; index < folderEntries.length; index++) {
      const entry = folderEntries[index];
      const files = this.results(entry[1]);
      if (files && files.length !== 0) { folderValues.push(new FolderFound(entry[0], files)); }
    }
    return [...folderValues, ...files];
  }
}

function row(
  distance: number,
  text: string,
  options: { path?: string, count?: number, child?: string[] } = {},
): string[] {
  const { path, count, child } = options;
  const isFile = path !== undefined;
  const id = text;
  const func = isFile ? `onclick="openFile('${path}')"` : `onclick="toggleFolder('${id}')"`;
  return [
    `<div item-id="${id}" class="explorer-item${isFile ? '' : ' collapsed'}" style="padding-left:${distance * 10}px;" ${func}>`,
    `  <span>${text}</span>`,
    ...(count ? [`  <div class="item-count"><span>${count}</span></div>`] : []),
    `</div>`,
    ...(child ? [
      `<div  content-id="${id}" class="hidden"'}>`,
      ...child.map(e => `  ${e}`),
      `</div>`,
    ] : []),
  ];
}

interface Found {
  html(distance: number): string[];
  get count(): number;
}

class FolderFound implements Found {
  constructor(
    public readonly name: string,
    public readonly files: (FolderFound | FileFound)[]
  ) { }

  get count(): number {
    return this.files.reduceRight((acc, file) => acc + file.count, 0);
  }

  html(distance: number): string[] {
    const { text, files } = this.text();
    return row(
      distance,
      text,
      {
        count: this.count,
        child: files.map(file => file.html(distance + 1)).flat()
      }
    );
  }

  text(): { text: string, files: (FolderFound | FileFound)[] } {
    if (this.files.length === 1) {
      const file = this.files[0];
      if (file instanceof FolderFound) {
        const newText = file.text();
        return { text: `${this.name} / ${newText.text}`, files: newText.files };
      }
    }
    return { text: this.name, files: this.files };
  }
}

class FileFound implements Found {
  constructor(
    public readonly path: string,
    public readonly lines: [number, string][],
  ) { }

  get count(): number {
    return this.lines.length;
  }

  html(distance: number): string[] {
    const text = this.path.split('/').pop()!;
    return row(
      distance,
      text,
      {
        count: this.count,
        child: this.lines.map(
          line => row(
            distance + 2,
            line[1].trim(),
            { path: `${this.path}:${line[0]}` }
          )
        ).flat()
      }
    );
  }
}
