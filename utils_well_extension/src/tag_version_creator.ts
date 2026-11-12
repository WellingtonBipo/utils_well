import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { execFile } from 'child_process';
import { promisify } from 'util';
import * as yaml from 'js-yaml';

/**
 * Port of the `tag_version_creator` CLI (go_bag_app/packages/tag_version_creator)
 * as a VS Code command. Reads the `tag_version_creator` section of a pubspec.yaml:
 *
 * ```yaml
 * tag_version_creator:
 *   committed_unsaved_changes: true      # commit pending changes before bumping the version
 *   standard_commit_message: bump version to @{$version}
 *   envs:
 *     - name: PROD
 *       required_branch: master          # optional
 *       left_text: v                     # optional, may contain @{info}
 *       right_text: -@{info}             # optional, may contain @{info}
 *       commit_message: ...              # optional, overrides standard_commit_message
 *       get_user_additional_infos: [info]
 *       plus_recommended: [major, minor, patch, build]
 * ```
 */

const _commandId = 'devUtilsWell.tagVersionCreator';
const _configKey = 'tag_version_creator';
const _versionPlaceholder = '@{$version}';

const execFileAsync = promisify(execFile);

export function activate(context: vscode.ExtensionContext) {
    const output = vscode.window.createOutputChannel('Utils Well - Tag Version Creator');
    context.subscriptions.push(
        output,
        vscode.commands.registerCommand(_commandId, () => new TagVersionCreator(output).create()),
    );
}

// ---------------------------------------------------------------------------
// Version
// ---------------------------------------------------------------------------

type PlusType = 'major' | 'minor' | 'patch' | 'build';
const _plusTypes: PlusType[] = ['major', 'minor', 'patch', 'build'];

class Version {
    constructor(
        readonly major: number,
        readonly minor: number,
        readonly patch: number,
        readonly build: number,
    ) { }

    static parse(text: string): Version {
        const match = /^\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$/.exec(text);
        if (!match) throw new Error(`Formato de versão inválido "${text}" (ex: 1.0.0+1)`);
        const [, major, minor, patch, build] = match.map(Number);
        return new Version(major, minor, patch, build);
    }

    plus(types: Set<PlusType>): Version {
        return new Version(
            this.major + (types.has('major') ? 1 : 0),
            this.minor + (types.has('minor') ? 1 : 0),
            this.patch + (types.has('patch') ? 1 : 0),
            this.build + (types.has('build') ? 1 : 0),
        );
    }

    equals(other: Version): boolean {
        return this.toString() === other.toString();
    }

    toString(): string {
        return `${this.major}.${this.minor}.${this.patch}+${this.build}`;
    }
}

// ---------------------------------------------------------------------------
// Pubspec config
// ---------------------------------------------------------------------------

interface EnvConfig {
    name: string;
    requiredBranch?: string;
    leftText: string;
    rightText: string;
    commitMessage?: string;
    additionalInfos: string[];
    plusRecommended: Set<PlusType>;
}

interface Config {
    committedUnsavedChanges: boolean;
    standardCommitMessage?: string;
    envs: EnvConfig[];
}

function _optionalString(value: unknown, key: string): string | undefined {
    if (value === undefined || value === null) return undefined;
    if (typeof value !== 'string') throw new Error(`"${key}" deve ser um texto`);
    return value;
}

function _stringList(value: unknown, key: string): string[] {
    if (value === undefined || value === null) return [];
    if (!Array.isArray(value)) throw new Error(`"${key}" deve ser uma lista`);
    return value.map(e => String(e));
}

function _parseConfig(pubspec: any): Config {
    const raw = pubspec?.[_configKey];
    if (!raw || typeof raw !== 'object') {
        throw new Error(`Seção "${_configKey}" não encontrada no pubspec.yaml`);
    }
    if (typeof raw['committed_unsaved_changes'] !== 'boolean') {
        throw new Error('"committed_unsaved_changes" é obrigatório (true/false)');
    }
    const rawEnvs = raw['envs'];
    if (!Array.isArray(rawEnvs) || rawEnvs.length === 0) {
        throw new Error('Informe ao menos um item em "envs"');
    }
    const envs = rawEnvs.map((e: any, i: number): EnvConfig => {
        if (!e || typeof e !== 'object') throw new Error(`envs[${i}] inválido`);
        const name = _optionalString(e['name'], `envs[${i}].name`);
        if (!name) throw new Error(`envs[${i}].name é obrigatório`);
        const plus = _stringList(e['plus_recommended'], `${name}.plus_recommended`);
        for (const p of plus) {
            if (!_plusTypes.includes(p as PlusType)) throw new Error(`plus_recommended inválido: ${p}`);
        }
        return {
            name,
            requiredBranch: _optionalString(e['required_branch'], `${name}.required_branch`),
            leftText: _optionalString(e['left_text'], `${name}.left_text`) ?? '',
            rightText: _optionalString(e['right_text'], `${name}.right_text`) ?? '',
            commitMessage: _optionalString(e['commit_message'], `${name}.commit_message`),
            additionalInfos: _stringList(e['get_user_additional_infos'], `${name}.get_user_additional_infos`),
            plusRecommended: new Set(plus as PlusType[]),
        };
    });
    return {
        committedUnsavedChanges: raw['committed_unsaved_changes'],
        standardCommitMessage: _optionalString(raw['standard_commit_message'], 'standard_commit_message'),
        envs,
    };
}

/** Replaces only the top-level `version:` line, keeping the rest of the file untouched. */
function _replacePubspecVersion(content: string, version: Version): string {
    const regex = /^version:[ \t]*[^\r\n#]*?([ \t]*(#[^\r\n]*)?)$/m;
    if (!regex.test(content)) throw new Error('Campo "version" não encontrado no pubspec.yaml');
    return content.replace(regex, (_match, trailing: string) => `version: ${version}${trailing ?? ''}`);
}

// ---------------------------------------------------------------------------
// Flow
// ---------------------------------------------------------------------------

class CanceledError extends Error { }

interface Plan {
    pubspecPath: string;
    cwd: string;
    pubspecContent: string;
    env: EnvConfig;
    branch: string;
    currentVersion: Version;
    newVersion: Version;
    pendingChangesCommitMessage?: string;
    versionCommitMessage?: string;
    tag: string;
}

class TagVersionCreator {
    constructor(private readonly output: vscode.OutputChannel) { }

    async create() {
        let plan: Plan | undefined;
        let pubspecWritten = false;
        let versionCommitted = false;
        try {
            plan = await this._buildPlan();
            if (!await this._confirm(plan)) throw new CanceledError();

            const p = plan;
            this.output.show(true);
            this.output.appendLine(`\n=== Tag Version Creator: ${p.tag} (${p.env.name}) ===`);
            await vscode.window.withProgress(
                { location: vscode.ProgressLocation.Notification, title: `Criando tag ${p.tag}`, cancellable: false },
                async progress => {
                    if (p.pendingChangesCommitMessage !== undefined) {
                        progress.report({ message: 'Commitando alterações pendentes...' });
                        await this._git(p.cwd, 'add', '.');
                        await this._git(p.cwd, 'commit', '--message', p.pendingChangesCommitMessage);
                    }
                    if (p.versionCommitMessage !== undefined) {
                        progress.report({ message: `Atualizando versão para ${p.newVersion}...` });
                        fs.writeFileSync(p.pubspecPath, _replacePubspecVersion(p.pubspecContent, p.newVersion));
                        pubspecWritten = true;
                        await this._git(p.cwd, 'add', p.pubspecPath);
                        await this._git(p.cwd, 'commit', '--message', p.versionCommitMessage);
                        versionCommitted = true;
                    }
                    progress.report({ message: 'Enviando commits...' });
                    await this._git(p.cwd, 'push', '--set-upstream', 'origin', p.branch);
                    progress.report({ message: `Criando tag ${p.tag}...` });
                    await this._git(p.cwd, 'tag', p.tag);
                    await this._git(p.cwd, 'push', 'origin', `refs/tags/${p.tag}`);
                },
            );
            this.output.appendLine('=== Finalizado ===');
            vscode.window.showInformationMessage(`Tag "${plan.tag}" criada e enviada com sucesso.`);
        } catch (e) {
            if (plan && pubspecWritten && !versionCommitted) {
                // Restore the pubspec so a failed run doesn't leave a dangling version bump.
                fs.writeFileSync(plan.pubspecPath, plan.pubspecContent);
            }
            if (e instanceof CanceledError) {
                vscode.window.showInformationMessage('Criação da tag cancelada.');
                return;
            }
            const message = e instanceof Error ? e.message : String(e);
            this.output.appendLine(`ERRO: ${message}`);
            vscode.window.showErrorMessage(`Tag Version Creator: ${message}`, 'Ver log').then(action => {
                if (action) this.output.show(true);
            });
        }
    }

    // ---- Gathering (read-only: nothing is changed until the user confirms) ----

    private async _buildPlan(): Promise<Plan> {
        const pubspecPath = await this._pickPubspec();
        const cwd = path.dirname(pubspecPath);
        const pubspecContent = fs.readFileSync(pubspecPath, 'utf8');
        const pubspec = yaml.load(pubspecContent) as any;
        const config = _parseConfig(pubspec);
        const currentVersion = Version.parse(String(pubspec?.['version'] ?? ''));

        await this._git(cwd, 'rev-parse', '--is-inside-work-tree').catch(() => {
            throw new Error(`"${cwd}" não é um repositório git`);
        });

        const env = await this._pickEnv(config);

        const branch = (await this._git(cwd, 'branch', '--show-current')).trim();
        if (!branch) throw new Error('Não foi possível identificar a branch atual (detached HEAD?)');
        if (env.requiredBranch && branch !== env.requiredBranch) {
            throw new Error(`Branch atual "${branch}" inválida para ${env.name}. Necessária: "${env.requiredBranch}"`);
        }

        const newVersion = await this._askVersion(currentVersion, currentVersion.plus(env.plusRecommended));

        const status = (await this._git(cwd, 'status', '--porcelain')).trim();
        let pendingChangesCommitMessage: string | undefined;
        if (status) {
            if (!config.committedUnsavedChanges) {
                throw new Error('Existem alterações não commitadas (committed_unsaved_changes: false)');
            }
            const count = status.split('\n').length;
            pendingChangesCommitMessage = await this._askText(
                `Existem ${count} arquivo(s) com alterações não commitadas. Mensagem do commit para eles:`,
            );
        }

        const infos = await this._askAdditionalInfos(env, config);
        const fill = (text: string) => {
            let result = text.split(_versionPlaceholder).join(newVersion.toString());
            for (const [key, value] of infos) result = result.split(`@{${key}}`).join(value);
            return result;
        };

        let versionCommitMessage: string | undefined;
        if (!newVersion.equals(currentVersion)) {
            const template = env.commitMessage ?? config.standardCommitMessage;
            versionCommitMessage = template !== undefined
                ? fill(template)
                : await this._askText(`Mensagem do commit da versão ${newVersion}:`);
        }

        const tag = `${fill(env.leftText)}${newVersion}${fill(env.rightText)}`;
        await this._git(cwd, 'fetch', '--prune', '--tags');
        const existing = (await this._git(cwd, 'tag', '--list', tag)).trim();
        if (existing) throw new Error(`A tag "${tag}" já existe`);

        return {
            pubspecPath, cwd, pubspecContent, env, branch, currentVersion, newVersion,
            pendingChangesCommitMessage, versionCommitMessage, tag,
        };
    }

    private async _pickPubspec(): Promise<string> {
        if (!vscode.workspace.workspaceFolders?.length) {
            throw new Error('Nenhuma pasta aberta no workspace');
        }
        const files = await vscode.workspace.findFiles(
            '**/pubspec.yaml',
            '**/{.dart_tool,build,node_modules,.symlinks,ephemeral}/**',
        );
        const candidates = files
            .map(f => f.fsPath)
            .filter(f => new RegExp(`^${_configKey}:`, 'm').test(fs.readFileSync(f, 'utf8')))
            .sort();
        if (candidates.length === 0) {
            throw new Error(`Nenhum pubspec.yaml com a seção "${_configKey}" encontrado no workspace`);
        }
        if (candidates.length === 1) return candidates[0];
        const picked = await vscode.window.showQuickPick(
            candidates.map(f => ({ label: vscode.workspace.asRelativePath(f), value: f })),
            { title: 'Tag Version Creator', placeHolder: 'Selecione o pubspec.yaml', ignoreFocusOut: true },
        );
        if (!picked) throw new CanceledError();
        return picked.value;
    }

    private async _pickEnv(config: Config): Promise<EnvConfig> {
        if (config.envs.length === 1) return config.envs[0];
        const picked = await vscode.window.showQuickPick(
            config.envs.map(env => ({
                label: env.name,
                description: env.requiredBranch ? `branch: ${env.requiredBranch}` : undefined,
                value: env,
            })),
            { title: 'Tag Version Creator', placeHolder: 'Escolha o ambiente (target)', ignoreFocusOut: true },
        );
        if (!picked) throw new CanceledError();
        return picked.value;
    }

    private async _askVersion(current: Version, recommended: Version): Promise<Version> {
        const value = await vscode.window.showInputBox({
            title: 'Tag Version Creator',
            prompt: `Versão atual: ${current}. Recomendada: ${recommended}`,
            value: recommended.toString(),
            ignoreFocusOut: true,
            validateInput: text => {
                try {
                    Version.parse(text);
                    return undefined;
                } catch (e) {
                    return (e as Error).message;
                }
            },
        });
        if (value === undefined) throw new CanceledError();
        return Version.parse(value);
    }

    private async _askAdditionalInfos(env: EnvConfig, config: Config): Promise<Map<string, string>> {
        const templates = [env.leftText, env.rightText, env.commitMessage ?? config.standardCommitMessage ?? ''];
        const infos = new Map<string, string>();
        for (const info of env.additionalInfos) {
            if (!templates.some(t => t.includes(`@{${info}}`))) continue;
            infos.set(info, await this._askText(`Informe "${info}":`));
        }
        return infos;
    }

    private async _askText(prompt: string, placeHolder?: string): Promise<string> {
        const value = await vscode.window.showInputBox({
            title: 'Tag Version Creator',
            prompt,
            placeHolder,
            ignoreFocusOut: true,
            validateInput: text => text.trim() ? undefined : 'Campo obrigatório',
        });
        if (value === undefined) throw new CanceledError();
        return value.trim();
    }

    private async _confirm(plan: Plan): Promise<boolean> {
        const steps: string[] = [];
        if (plan.pendingChangesCommitMessage !== undefined) {
            steps.push(`• Commit de TODAS as alterações pendentes: "${plan.pendingChangesCommitMessage}"`);
        }
        if (plan.versionCommitMessage !== undefined) {
            steps.push(`• Versão ${plan.currentVersion} → ${plan.newVersion} no pubspec.yaml`);
            steps.push(`• Commit: "${plan.versionCommitMessage}"`);
        } else {
            steps.push(`• Versão mantida: ${plan.currentVersion}`);
        }
        steps.push(`• Push da branch "${plan.branch}" para origin`);
        steps.push(`• Criar e enviar a tag "${plan.tag}"`);

        const confirmLabel = 'Criar tag';
        const answer = await vscode.window.showWarningMessage(
            `Criar a tag "${plan.tag}" (${plan.env.name})?`,
            {
                modal: true,
                detail: `${vscode.workspace.asRelativePath(plan.pubspecPath)}\n\n${steps.join('\n')}`,
            },
            confirmLabel,
        );
        return answer === confirmLabel;
    }

    // ---- Git ----

    private async _git(cwd: string, ...args: string[]): Promise<string> {
        this.output.appendLine(`$ git ${args.map(a => (/\s/.test(a) ? JSON.stringify(a) : a)).join(' ')}`);
        try {
            const { stdout, stderr } = await execFileAsync('git', args, { cwd, maxBuffer: 10 * 1024 * 1024 });
            if (stdout.trim()) this.output.appendLine(stdout.trimEnd());
            if (stderr.trim()) this.output.appendLine(stderr.trimEnd());
            return stdout;
        } catch (e: any) {
            const detail = (e?.stderr || e?.stdout || e?.message || String(e)).toString().trim();
            this.output.appendLine(detail);
            throw new Error(`git ${args[0]} falhou: ${detail.split('\n')[0]}`);
        }
    }
}
