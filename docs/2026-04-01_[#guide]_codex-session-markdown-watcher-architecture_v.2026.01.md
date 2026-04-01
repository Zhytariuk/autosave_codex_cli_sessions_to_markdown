# Architecture

## High-level flow

1. Codex writes session logs to `.codex\sessions`
2. watcher monitors that directory tree
3. when a matching `rollout-*.jsonl` file appears or changes, watcher calls exporter
4. exporter reads JSONL line by line
5. exporter writes a structured Markdown file to `.codex\session-exports`

## Components

### `codex-session-exporter.ps1`

Responsible for:

- parsing one session file
- extracting:
  - session metadata
  - transcript messages
  - final answer
  - latest token snapshot
- generating Markdown

### `codex-session-watcher.ps1`

Responsible for:

- monitoring the session directory tree
- detecting file create/change/rename events
- avoiding duplicate work via a file fingerprint state file
- writing operational logs

### State file

Default:

`$HOME\.codex\automation\codex-session-watcher-state.json`

Purpose:

- remember last exported file fingerprint
- avoid repeated exports of the same unchanged file

### Log file

Default:

`$HOME\.codex\log\codex-session-watcher.log`

Purpose:

- operational visibility
- troubleshooting

## Output design

Exports are stored in date-based directories mirroring the original session structure:

`$HOME\.codex\session-exports\YYYY\MM\DD\rollout-....md`

This keeps the relationship between source JSONL and exported Markdown easy to trace.

## Startup options

### Task Scheduler

Best when available:

- starts automatically at logon
- can run hidden
- cleaner Windows-native background startup

### Startup shortcut

Fallback when Task Scheduler creation is blocked:

- runs at user logon
- user-level setup
- easier in restricted environments
