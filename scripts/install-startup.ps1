Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
    [string]$WatcherScript = "$PSScriptRoot\codex-session-watcher.ps1",
    [string]$ShortcutName = "CodexSessionMarkdownWatcher.lnk"
)

if (-not (Test-Path -LiteralPath $WatcherScript)) {
    throw "Watcher script not found: $WatcherScript"
}

$startupDir = [Environment]::GetFolderPath("Startup")
$shortcutPath = Join-Path $startupDir $ShortcutName

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$WatcherScript`""
$shortcut.WorkingDirectory = Split-Path -Parent $WatcherScript
$shortcut.WindowStyle = 7
$shortcut.Description = "Start Codex session markdown watcher"
$shortcut.Save()

Write-Output "Installed startup shortcut: $shortcutPath"
