param(
    [string]$TaskName = "CodexSessionMarkdownWatcher",
    [string]$WatcherScript = "$PSScriptRoot\codex-session-watcher.ps1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $WatcherScript)) {
    throw "Watcher script not found: $WatcherScript"
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$WatcherScript`""
$trigger = New-ScheduledTaskTrigger -AtLogOn

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Description "Watch Codex session JSONL files and export structured markdown." `
    -Force

Write-Output "Installed scheduled task: $TaskName"
