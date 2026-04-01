# Roadmap

## Near term

- Add `re-export-all.ps1` for regenerating all existing Markdown exports from local `rollout-*.jsonl` files.
- Improve watcher logging with clearer startup, skip, and unchanged-file messages.
- Add `.gitattributes` to normalize line endings and avoid cross-machine `LF/CRLF` noise.
- Handle empty or still-growing `rollout-*.jsonl` files more explicitly during export and watch cycles.
- Document and optionally support `pwsh.exe` as a first-class execution path alongside `powershell.exe`.

## Mid term

- Add optional JSON export alongside Markdown export.
- Add a configurable export naming strategy.
- Add an installer that writes `HKCU\...\Run` autostart directly.
- Add filtering for which session events should appear in the transcript.
- Add summary generation mode for shorter session exports.
- Add optional per-project export folders.
- Add support for exporting metadata into a machine-friendly index file.

## Longer term

- Add tests with fixture sessions covering ASCII, Cyrillic, empty, and partially broken inputs.
- Add package/release artifacts for easier installation.
- Add support for richer GitHub release notes and version tagging workflow.
