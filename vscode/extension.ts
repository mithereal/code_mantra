import * as vscode from 'vscode';
import WebSocket from 'ws';

export function activate(context: vscode.ExtensionContext) {
    const userId = vscode.workspace.getConfiguration('codeMantra').get('userId', 'user_default');
    const ws = new WebSocket(`ws://localhost:4000/developer_socket/websocket?user_id=${userId}`);

    ws.on('open', () => {
        vscode.window.showInformationMessage('🛡️ Code::Mantra Connected to BEAM Backend.');
    });

    // Listen to active editor text changes
    vscode.workspace.onDidChangeTextDocument(event => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) return;

        const payload = {
            topic: "developer_workspace:" + userId,
            event: "telemetry_batch",
            payload: {
                language: editor.document.languageId,
                file_extension: editor.document.fileName.split('.').pop(),
                buffer_content: editor.document.getText(),
                commits_per_day: 10.0,
                avg_lines_per_commit: editor.document.lineCount
            }
        };

        if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify(payload));
        }
    });
}

export function deactivate() {}