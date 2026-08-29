# Claude Code / Codex Notification

([日本語の説明は下部をご覧ください / Japanese version below](#claude-code--codex-の通知))

Ever start another task while an AI agent works, only to come back and find it's actually been sitting idle for a while, silently waiting on a permission prompt? Claude Code and Codex don't notify you for this by default — so this is a tiny, fully open-source PowerShell script that pops up a small always-on-top notification window on **every connected monitor** whenever Claude Code or Codex needs your attention. No app to install, nothing running in the background, no server. Claude Code's and Codex's hook systems call the script directly, on demand.

---

## How it works

`notify-all-screens.ps1` draws a small dark popup in the bottom-right corner of each monitor (via `System.Windows.Forms`), showing a title + message, and closes itself after ~8 seconds. Claude Code's `Notification`/`Stop` hooks and Codex's `notify`/`PermissionRequest` hooks each call it directly with a different message — that's the entire mechanism.

## Setup

### Claude Code (WSL2)

1. Save [`notify-all-screens.ps1`](./notify-all-screens.ps1) to `~/.config/notify/notify-all-screens.ps1` inside WSL2.
2. Add this to `~/.claude/settings.json` (merge into any existing `hooks` key — don't overwrite it):

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "timeout": 10,
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$(wslpath -w ~/.config/notify/notify-all-screens.ps1)\" -Title 'Claude Code' -Message 'approval needed'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "timeout": 10,
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$(wslpath -w ~/.config/notify/notify-all-screens.ps1)\" -Title 'Claude Code' -Message 'waiting for input'"
          }
        ]
      }
    ]
  }
}
```

3. Restart Claude Code, then run `/hooks` to confirm both are registered.

Both hooks are needed for full coverage — they fire at different times:

| Event | Fires when |
|---|---|
| `Notification` (`permission_prompt`) | Claude Code is waiting for permission to run a tool, mid-task |
| `Stop` | Claude Code finished responding and is waiting for your next input, every turn |

### Claude Code (native Windows, no WSL)

Same script, just skip the `wslpath` conversion — save it to e.g. `%USERPROFILE%\.config\notify\notify-all-screens.ps1` and point the hook straight at that path:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "timeout": 10,
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.config\\notify\\notify-all-screens.ps1\" -Title 'Claude Code' -Message 'approval needed'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "timeout": 10,
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.config\\notify\\notify-all-screens.ps1\" -Title 'Claude Code' -Message 'waiting for input'"
          }
        ]
      }
    ]
  }
}
```

### Codex (WSL2)

Codex's hook model is different from Claude Code's — it needs two *separate* mechanisms to get the same coverage:

| Mechanism | Fires when |
|---|---|
| `notify` (`agent-turn-complete`) | Response finished, waiting for your next input, every turn |
| `hooks.PermissionRequest` | An approval prompt (e.g. running a command) is shown |

Add this to `~/.codex/config.toml`:

```toml
notify = ["bash", "-c", "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$(wslpath -w ~/.config/notify/notify-all-screens.ps1)\" -Title 'Codex' -Message 'waiting for input'"]

[[hooks.PermissionRequest]]
matcher = ""

[[hooks.PermissionRequest.hooks]]
type = "command"
timeout = 10
command = '''powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w ~/.config/notify/notify-all-screens.ps1)" -Title 'Codex' -Message 'approval needed' '''
```

Restart Codex for the config change to take effect — `config.toml` is only read at startup.

Notes:
- If you already have a `config.toml`, put the `notify = [...]` line at the very top of the file — putting it below other settings can make it silently stop working.
- Add this to your **user-level** `~/.codex/config.toml` — a project-level `notify` setting is ignored.
- This never interferes with your approvals — Codex just shows the notification, then falls back to its normal approval prompt as usual.

### Codex (native Windows, no WSL)

```toml
notify = ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "C:\\Users\\yourname\\.config\\notify\\notify-all-screens.ps1", "-Title", "Codex", "-Message", "waiting for input"]

[[hooks.PermissionRequest]]
matcher = ""

[[hooks.PermissionRequest.hooks]]
type = "command"
timeout = 10
command = '''powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\yourname\.config\notify\notify-all-screens.ps1" -Title 'Codex' -Message 'approval needed' '''
```

Restart Codex for the config change to take effect — `config.toml` is only read at startup.

This looks slightly different from the WSL2 version above because there's no `bash` on native Windows, so `notify` calls `powershell.exe` directly instead.

---

## License

MIT — see [LICENSE](./LICENSE).

---

# Claude Code / Codex の通知

AIの作業時間がかかりそうだと思い別の作業をしていたら、実はコマンドの承認待ちでAIが止まっていて作業が進んでいなかった、ということはありませんか。Claude CodeもCodexも、現時点ではデフォルトでこれを通知してくれません。そこで作ったのが、Claude CodeやCodexが確認を必要としたときに、接続中の**全モニター**に小さな常時最前面の通知ウィンドウをポップアップ表示する、完全オープンソースの小さなPowerShellスクリプトです。インストール不要、バックグラウンドで常駐するアプリもサーバーもありません。Claude Code / Codexのフック機構が、必要なタイミングでこのスクリプトを直接呼び出すだけです。

---

## 仕組み

`notify-all-screens.ps1` は `System.Windows.Forms` を使って各モニターの右下に小さな暗色のポップアップを描画し、タイトルとメッセージを表示して約8秒後に自動で閉じます。Claude Codeの `Notification`/`Stop` フックとCodexの `notify`/`PermissionRequest` フックが、それぞれ異なるメッセージでこのスクリプトを直接呼び出す — それが仕組みのすべてです。

## セットアップ

### Claude Code（WSL2）

1. [`notify-all-screens.ps1`](./notify-all-screens.ps1) をWSL2内の `~/.config/notify/notify-all-screens.ps1` として保存します。
2. `~/.claude/settings.json` に以下を追加します（既存の `hooks` キーがある場合は中身をマージすること。トップレベルを丸ごと置き換えない）：

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "timeout": 10,
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$(wslpath -w ~/.config/notify/notify-all-screens.ps1)\" -Title 'Claude Code' -Message 'approval needed'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "timeout": 10,
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$(wslpath -w ~/.config/notify/notify-all-screens.ps1)\" -Title 'Claude Code' -Message 'waiting for input'"
          }
        ]
      }
    ]
  }
}
```

3. Claude Codeを再起動し、`/hooks` と入力して両方が登録されていることを確認します。

2つのフックはそれぞれ異なるタイミングで発火するため、両方とも必要です：

| イベント | 発火タイミング |
|---|---|
| `Notification`（`permission_prompt`） | ツール実行の許可待ちになった瞬間（タスク途中） |
| `Stop` | 応答が完了し、次の入力を待つ状態になった瞬間（毎ターン） |

### Claude Code（ネイティブWindows、WSLなし）

スクリプトは同じものを使い、`wslpath` の変換だけ不要になります — 例えば `%USERPROFILE%\.config\notify\notify-all-screens.ps1` に保存し、フックからそのパスを直接指定します：

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "timeout": 10,
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.config\\notify\\notify-all-screens.ps1\" -Title 'Claude Code' -Message 'approval needed'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "timeout": 10,
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.config\\notify\\notify-all-screens.ps1\" -Title 'Claude Code' -Message 'waiting for input'"
          }
        ]
      }
    ]
  }
}
```

### Codex（WSL2）

Codexのフック機構はClaude Codeと異なり、同じカバレッジを得るには2つの**別々の**仕組みが必要です：

| 仕組み | 発火タイミング |
|---|---|
| `notify`（`agent-turn-complete`） | 応答が完了し、次の入力を待つ状態になった瞬間（毎ターン） |
| `hooks.PermissionRequest` | 承認プロンプト（コマンド実行の許可待ちなど）が表示された瞬間 |

`~/.codex/config.toml` に以下を追加します：

```toml
notify = ["bash", "-c", "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$(wslpath -w ~/.config/notify/notify-all-screens.ps1)\" -Title 'Codex' -Message 'waiting for input'"]

[[hooks.PermissionRequest]]
matcher = ""

[[hooks.PermissionRequest.hooks]]
type = "command"
timeout = 10
command = '''powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w ~/.config/notify/notify-all-screens.ps1)" -Title 'Codex' -Message 'approval needed' '''
```

設定を反映させるにはCodexを再起動してください — `config.toml` は起動時にのみ読み込まれます。

補足：
- すでに `config.toml` がある場合、`notify = [...]` の行はファイルの一番上に置いてください — 他の設定より下に置くと、サイレントに動かなくなることがあります。
- **ユーザーレベル**の `~/.codex/config.toml` に追加してください — プロジェクトレベルの `notify` は無視されます。
- 承認フローを妨げることはありません — Codexは通知を表示するだけで、その後はいつも通りの承認プロンプトにフォールバックします。

### Codex（ネイティブWindows、WSLなし）

```toml
notify = ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "C:\\Users\\yourname\\.config\\notify\\notify-all-screens.ps1", "-Title", "Codex", "-Message", "waiting for input"]

[[hooks.PermissionRequest]]
matcher = ""

[[hooks.PermissionRequest.hooks]]
type = "command"
timeout = 10
command = '''powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\yourname\.config\notify\notify-all-screens.ps1" -Title 'Codex' -Message 'approval needed' '''
```

設定を反映させるにはCodexを再起動してください — `config.toml` は起動時にのみ読み込まれます。

上のWSL2版と少し違って見えるのは、ネイティブWindowsには `bash` が無いため、`notify` が `powershell.exe` を直接呼び出しているためです。

---

## ライセンス

MIT — [LICENSE](./LICENSE) を参照してください。
