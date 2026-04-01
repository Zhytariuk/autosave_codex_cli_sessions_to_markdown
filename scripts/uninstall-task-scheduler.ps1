Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
    [string]$TaskName = "CodexSessionMarkdownWatcher"
)

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
Write-Output "Removed scheduled task: $TaskName"
