# Installation

## Prerequisites

- Windows
- PowerShell
- local Codex session logging already working in:
  - `$HOME\.codex\sessions`

## Option A. Task Scheduler

Recommended when Windows allows scheduled task creation.

From the project root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-task-scheduler.ps1
```

Verify:

```powershell
schtasks /Query /TN CodexSessionMarkdownWatcher /V /FO LIST
```

Run immediately:

```powershell
schtasks /Run /TN CodexSessionMarkdownWatcher
```

Remove:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall-task-scheduler.ps1
```

## Option B. Startup

Recommended when scheduled task registration fails due to permissions.

Install:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-startup.ps1
```

This creates a shortcut in the current user's Startup folder.

Remove:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\uninstall-startup.ps1
```

## Manual run

Run watcher directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\codex-session-watcher.ps1
```

Export one file directly:

```powershell
$sf=Get-ChildItem $HOME\.codex\sessions -Recurse -Filter rollout-*.jsonl | Sort-Object LastWriteTime -Descending | Select-Object -First 1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\codex-session-exporter.ps1 -SessionFile $sf.FullName
```
