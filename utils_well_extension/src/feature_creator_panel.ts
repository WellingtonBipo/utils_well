import * as vscode from 'vscode';
import * as fs from 'fs';
import { WebviewPanel } from 'vscode';

export function activate(context: vscode.ExtensionContext) {
    context.subscriptions.push(
        vscode.commands.registerCommand("devUtilsWell.featureCreator", () => {
            FeatureCreatorPanel.render(context);
        })
    );
}

class FeatureCreatorPanel {
    public static currentPanel: FeatureCreatorPanel | undefined;
    private readonly _panel: WebviewPanel;
    private _context: vscode.ExtensionContext;
    private _disposables: vscode.Disposable[] = [];

    constructor(context: vscode.ExtensionContext, panel: WebviewPanel) {
        this._context = context;
        this._panel = panel;
        this._panel.onDidDispose(() => this.dispose(), null, this._disposables);
        this._panel.webview.html = this._getWebviewContent();
        this._setWebviewMessageListener();
    }

    public static render(context: vscode.ExtensionContext) {
        if (FeatureCreatorPanel.currentPanel) {
            FeatureCreatorPanel.currentPanel._panel.reveal(vscode.ViewColumn.One);
        } else {
            const panel = vscode.window.createWebviewPanel(
                "featureCreatorView",
                "Criador de Features",
                vscode.ViewColumn.One,
                {
                    enableScripts: true,
                    localResourceRoots: [
                        vscode.Uri.joinPath(context.extensionUri, "out"),
                        vscode.Uri.joinPath(context.extensionUri, "react_vite_ui/build"),
                    ],
                }
            );
            panel.iconPath = {
                light: vscode.Uri.joinPath(context.extensionUri, "media", "logo_light.svg"),
                dark: vscode.Uri.joinPath(context.extensionUri, "media", "logo_dark.svg"),
            };
            FeatureCreatorPanel.currentPanel = new FeatureCreatorPanel(context, panel);
        }
    }

    public dispose() {
        FeatureCreatorPanel.currentPanel = undefined;
        this._panel.dispose();
        while (this._disposables.length) {
            const disposable = this._disposables.pop();
            if (disposable) { disposable.dispose(); }
        }
    }

    private _getWebviewContent() {
        const assetsPath = ["react_vite_ui", "build", "assets"];
        const stylesUri = this._getUri([...assetsPath, "index.css",]);
        const scriptUri = this._getUri([...assetsPath, "index.js",]);
        const nonce = this._getNonce();
        return `
<!DOCTYPE html>
    <html lang="en">
        <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src vscode-webview:; style-src ${this._panel.webview.cspSource} vscode-webview; script-src 'nonce-${nonce}';">
            <link rel="stylesheet" type="text/css" href="${stylesUri}">
            <title>Todo</title>
        </head>
        <body>
            <div id="root"></div>
            <script type="module" nonce="${nonce}" src="${scriptUri}"></script>
        </body>
    </html>`;
    }

    private _setWebviewMessageListener() {
        this._panel.webview.onDidReceiveMessage(
            (message: any) => {
                const command = message.command;
                const text = message.text;
                switch (command) {
                    case "ready":
                        return console.log("ready");
                }
            },
            undefined,
            this._disposables
        );
    }
    private _getUri(pathList: string[]) {
        return this._panel.webview.asWebviewUri(
            vscode.Uri.joinPath(this._context.extensionUri, ...pathList)
        );
    }

    private _getNonce() {
        let text = "";
        const possible =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        for (let i = 0; i < 32; i++) {
            text += possible.charAt(Math.floor(Math.random() * possible.length));
        }
        return text;
    }
}

