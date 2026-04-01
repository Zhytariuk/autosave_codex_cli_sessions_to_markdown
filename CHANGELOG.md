# Changelog

All notable changes to this project will be documented in this file.

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
- Session exporter now reads `rollout-*.jsonl` explicitly as UTF-8 to preserve Cyrillic and other non-ASCII text in Markdown exports on Windows PowerShell.

### Notes

- The project builds on top of Codex's existing local session logging and does not replace it.
- Auto-start registration may still require elevated rights depending on local Windows policy.
