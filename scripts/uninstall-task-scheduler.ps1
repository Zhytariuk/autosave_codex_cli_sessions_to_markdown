param(
    [string]$TaskName = "CodexSessionMarkdownWatcher"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
Write-Output "Removed scheduled task: $TaskName"
