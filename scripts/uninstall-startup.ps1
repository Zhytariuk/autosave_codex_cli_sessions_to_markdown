Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
    [string]$ShortcutName = "CodexSessionMarkdownWatcher.lnk"
)

$startupDir = [Environment]::GetFolderPath("Startup")
$shortcutPath = Join-Path $startupDir $ShortcutName

if (Test-Path -LiteralPath $shortcutPath) {
    Remove-Item -LiteralPath $shortcutPath -Force
    Write-Output "Removed startup shortcut: $shortcutPath"
} else {
    Write-Output "Startup shortcut not found: $shortcutPath"
}
