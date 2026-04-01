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

Manual export test:

```powershell
$sf=Get-ChildItem $HOME\.codex\sessions -Recurse -Filter rollout-*.jsonl | Sort-Object LastWriteTime -Descending | Select-Object -First 1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\codex-session-exporter.ps1 -SessionFile $sf.FullName
```

## Common issue: duplicate exports

The watcher uses a fingerprint state file based on:

- file length
- last write timestamp

This is enough for the current use case and avoids repeated work in normal operation.
