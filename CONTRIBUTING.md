# Contributing

## Default rule

If code changes, documentation review is required in the same session.

Do not treat docs updates as optional follow-up work. Before closing a task, review whether the change affects:

- behavior
- installation
- configuration
- usage
- limitations
- troubleshooting
- maintenance workflow

If any of those changed, update the relevant docs.

## Docs checklist

Review these files whenever code changes:

- `CHANGELOG.md` for bug fixes, features, and behavior changes
- `README.md` for install, setup, usage, capabilities, and limitations
- `docs/*` for architecture, operations, troubleshooting, and workflows
- command examples if script or CLI behavior changed

## Commit policy

Before the final commit:

1. inspect `git diff`
2. decide which docs must change
3. update docs in the same session
4. either include docs in the same commit or make a separate docs commit immediately after

If no docs changed, the contributor should be able to explain why no documentation update was needed.

## Reusable policy

This repository uses a portable rule set that should also be applied in other repositories:

- code change -> docs review required
- user-facing or operator-facing change -> docs update required
- bug fix affecting real behavior -> changelog update required
- setup or maintenance change -> README or troubleshooting update required

## Optional local check

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check-docs.ps1
```

This script is intentionally lightweight. It warns when code changed but no docs files changed in the same diff.