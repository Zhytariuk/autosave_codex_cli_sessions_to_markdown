# Changelog

All notable changes to this project will be documented in this file.

## [0.1.2] - 2026-04-02

### Fixed

- Exporter now opens active `rollout-*.jsonl` files with read/write sharing so Markdown export can succeed while Codex is still writing the session.
- Watcher state keys now use normalized paths relative to `.codex\sessions`, avoiding duplicate state entries when Windows path encoding mangles the user profile prefix.
- Startup-installed watcher instances can be refreshed to the current script path without relying on an older machine-specific repository location.
## [0.1.1] - 2026-04-01

### Fixed

- Session exporter now reads `rollout-*.jsonl` explicitly as UTF-8 to preserve Cyrillic and other non-ASCII text in Markdown exports on Windows PowerShell.
- PowerShell entry scripts now place `param(...)` first, fixing startup and watcher execution in Windows PowerShell.

## [0.1.0] - 2026-04-01

### Added

- Initial standalone repository for Codex session to Markdown automation.
- PowerShell exporter for converting Codex `rollout-*.jsonl` session logs into structured Markdown.
- PowerShell watcher based on `FileSystemWatcher` for automatic export on new or changed session files.
- State tracking to avoid duplicate exports of unchanged session logs.
- Operational logging for watcher activity and export failures.
- Installer and uninstaller for Windows `Task Scheduler`.
- Installer and uninstaller for Windows `Startup`.
- Documentation for problem context, architecture, installation, and troubleshooting.

### Changed

- Scripts made portable by defaulting to `$HOME\.codex` instead of a hardcoded user path.
- Added optional `-CodexRoot` parameter so the project can be reused on another Windows machine or another local Codex root.

### Notes

- The project builds on top of Codex's existing local session logging and does not replace it.
- Auto-start registration may still require elevated rights depending on local Windows policy.
