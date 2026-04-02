# autosave_codex_cli_sessions_to_markdown

Local automation for exporting Codex session logs into structured Markdown files.

## What this project is

Codex already logs each session locally as `jsonl` under:

`$HOME\.codex\sessions`

This project does not replace that built-in logging.

It adds a second layer:

- watches new or updated `rollout-*.jsonl` files
- converts them into readable structured `.md`
- preserves UTF-8 text correctly during export, including Cyrillic and other non-ASCII content
- starts correctly in Windows PowerShell for manual runs and startup installation
- supports background startup through either:
  - `Task Scheduler`
  - Windows `Startup`

## Project structure

- `scripts\codex-session-exporter.ps1`
- `scripts\codex-session-watcher.ps1`
- `scripts\install-task-scheduler.ps1`
- `scripts\install-startup.ps1`
- `scripts\uninstall-task-scheduler.ps1`
- `scripts\uninstall-startup.ps1`
- `docs\2026-04-01_[#guide]_codex-session-markdown-watcher-problem-context-and-solution_v.2026.01.md`
- `docs\2026-04-01_[#guide]_codex-session-markdown-watcher-architecture_v.2026.01.md`
- `docs\2026-04-01_[#guide]_codex-session-markdown-watcher-installation_v.2026.01.md`
- `docs\2026-04-01_[#guide]_codex-session-markdown-watcher-operations-and-troubleshooting_v.2026.01.md`

## Quick start

Manual watcher run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\codex-session-watcher.ps1
```

Manual export for the latest session:

```powershell
$sf=Get-ChildItem $HOME\.codex\sessions -Recurse -Filter rollout-*.jsonl | Sort-Object LastWriteTime -Descending | Select-Object -First 1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\codex-session-exporter.ps1 -SessionFile $sf.FullName
```

## Output

Markdown exports are written to:

`$HOME\.codex\session-exports`

## Installation options

### Option 1. Task Scheduler

Recommended when Windows allows scheduled task creation.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-task-scheduler.ps1
```

### Option 2. Startup

Recommended when scheduled task creation is blocked by permissions.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-startup.ps1
```

## Notes

- This project assumes Codex continues writing session files to `.codex\sessions`.
- The exporter rewrites Markdown when the source session file changes.
- A small state file prevents repeated duplicate exports.
- Watcher state keys are stored relative to `.codex\sessions`, which avoids duplicate state entries caused by broken absolute path prefixes on some Windows setups.
- For portability, the scripts default to `$HOME\.codex` and can also be pointed at another root with `-CodexRoot`.
- Session files are read as UTF-8 during export so non-English text is not mangled on Windows PowerShell.
- Active session files are opened with read/write sharing, so Markdown export can succeed while Codex is still appending to the current `jsonl`.
- If Startup was installed from an older checkout path, rerun `scripts\install-startup.ps1` to refresh the shortcut target.
- PowerShell script entry points are structured for Windows PowerShell compatibility, so watcher and installers can be launched directly as `.ps1`.

## Contribution workflow

This repository treats documentation review as a required part of code changes.

- code change -> docs review required
- behavior change -> changelog update required
- setup or workflow change -> README or troubleshooting update required

Useful files:

- `CONTRIBUTING.md`
- `.github\PULL_REQUEST_TEMPLATE.md`
- `scripts\check-docs.ps1`
