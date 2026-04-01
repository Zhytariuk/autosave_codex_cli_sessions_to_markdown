# Problem, Context, and Solution

## Problem

Codex already stores sessions locally, but the native format is `jsonl`.

That is useful for machine logging, but less useful for:

- human reading
- quick review
- archiving
- sharing or moving session summaries between places

The goal was not to replace the built-in logging.

The goal was to automatically create a second, readable, structured Markdown copy for each session without manual reminders.

## Existing built-in behavior

Codex already logs session data under:

`$HOME\.codex\sessions`

and also keeps other local history/state artifacts in:

`C:\Users\ЖЖ\.codex`

So the core logging capability already exists.

## What this project adds

This project adds an automation layer on top of existing Codex logging:

1. detect new or changed `rollout-*.jsonl` files
2. parse useful session data
3. export a readable `.md` file
4. run automatically in the background at user logon

## Why this approach

This approach is intentionally simple:

- no external cloud service
- no new database
- no changes to Codex internals
- no attempt to intercept prompts in real time

Instead, it reuses the stable thing that already exists:

- local session log files

That makes the solution cheaper, easier to maintain, and less fragile.
