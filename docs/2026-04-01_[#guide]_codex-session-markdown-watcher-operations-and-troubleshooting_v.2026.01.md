# Operations and Troubleshooting

## Expected behavior

After installation:

- Codex writes a session JSONL
- watcher detects it
- Markdown export appears in:
  - `$HOME\.codex\session-exports`

## Check log output

```powershell
Get-Content $HOME\.codex\log\codex-session-watcher.log -Tail 50
```

## Common issue: Task Scheduler access denied

Symptoms:

- `schtasks /Create` returns `Access is denied`
- `Register-ScheduledTask` returns `Access is denied`

Meaning:

- the script is fine
- Windows permissions or policy block scheduled task creation in the current context

Workaround:

- run installer from elevated PowerShell
- or use the `Startup` installation path

## Common issue: no markdown export appears

Check:

1. does `$HOME\.codex\sessions` contain `rollout-*.jsonl` files
2. is watcher actually running
3. is log file showing export errors
4. does manual export work
5. if Startup is used, does the shortcut still point to the current repository path

Manual export test:

```powershell
$sf=Get-ChildItem $HOME\.codex\sessions -Recurse -Filter rollout-*.jsonl | Sort-Object LastWriteTime -Descending | Select-Object -First 1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\codex-session-exporter.ps1 -SessionFile $sf.FullName
```

Notes:

- Active session files can stay locked while Codex is still writing them. The exporter now opens them with read/write sharing, so current-session Markdown export should still succeed.
- If Startup was installed from an older checkout path, rerun `scripts\install-startup.ps1` so the shortcut target points to the current watcher script.

## Common issue: duplicate exports

The watcher uses a fingerprint state file based on:

- file length
- last write timestamp

This is enough for the current use case and avoids repeated work in normal operation.

## Common issue: duplicate watcher state entries

Symptoms:

- state file contains duplicate entries for the same session
- one key uses the expected relative path and another uses a mangled Windows user-path prefix

Meaning:

- Windows path encoding may differ between processes when the user profile path contains non-ASCII characters
- watcher state should be keyed relative to `.codex\sessions`, not by the full absolute path

Current behavior:

- watcher state keys are normalized to the path below `.codex\sessions`
- rebuilding the state file removes stale duplicate absolute-path keys
