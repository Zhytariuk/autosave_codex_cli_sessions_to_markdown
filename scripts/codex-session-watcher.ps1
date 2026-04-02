param(
    [string]$CodexRoot = "",
    [string]$SessionsRoot = "",
    [string]$ExportRoot = "",
    [string]$StatePath = "",
    [string]$LogPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\codex-session-exporter.ps1"

if ([string]::IsNullOrWhiteSpace($CodexRoot)) {
    $CodexRoot = Join-Path $HOME ".codex"
}

if ([string]::IsNullOrWhiteSpace($SessionsRoot)) {
    $SessionsRoot = Join-Path $CodexRoot "sessions"
}

if ([string]::IsNullOrWhiteSpace($ExportRoot)) {
    $ExportRoot = Join-Path $CodexRoot "session-exports"
}

if ([string]::IsNullOrWhiteSpace($StatePath)) {
    $StatePath = Join-Path $CodexRoot "automation\codex-session-watcher-state.json"
}

if ([string]::IsNullOrWhiteSpace($LogPath)) {
    $LogPath = Join-Path $CodexRoot "log\codex-session-watcher.log"
}

function Write-Log {
    param([string]$Message)

    $logDir = Split-Path -Parent $LogPath
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -LiteralPath $LogPath -Value $line
}

function Load-State {
    if (-not (Test-Path -LiteralPath $StatePath)) {
        return @{}
    }

    try {
        $raw = Get-Content -LiteralPath $StatePath -Raw
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return @{}
        }

        $obj = $raw | ConvertFrom-Json
        $table = @{}
        foreach ($prop in $obj.PSObject.Properties) {
            $table[$prop.Name] = [string]$prop.Value
        }
        return $table
    } catch {
        Write-Log "Failed to load state, starting fresh: $($_.Exception.Message)"
        return @{}
    }
}

function Save-State {
    param([hashtable]$State)

    $stateDir = Split-Path -Parent $StatePath
    if (-not (Test-Path -LiteralPath $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }

    $ordered = [ordered]@{}
    foreach ($key in ($State.Keys | Sort-Object)) {
        $ordered[$key] = $State[$key]
    }

    $json = $ordered | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($StatePath, $json, [System.Text.UTF8Encoding]::new($false))
}

function Get-FileFingerprint {
    param([System.IO.FileInfo]$File)
    return "{0}|{1}" -f $File.Length, $File.LastWriteTimeUtc.Ticks
}

function Get-StateKey {
    param([string]$Path)

    $marker = "\sessions\"
    $index = $Path.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase)
    if ($index -ge 0) {
        return $Path.Substring($index + $marker.Length)
    }

    return [System.IO.Path]::GetFileName($Path)
}

function Export-IfChanged {
    param(
        [string]$Path,
        [hashtable]$State
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $file = Get-Item -LiteralPath $Path
    if ($file.PSIsContainer -or $file.Extension -ne ".jsonl" -or $file.Name -notlike "rollout-*.jsonl") {
        return
    }

    Start-Sleep -Milliseconds 750
    $fingerprint = Get-FileFingerprint -File $file
    $stateKey = Get-StateKey -Path $file.FullName
    if ($State.ContainsKey($stateKey) -and $State[$stateKey] -eq $fingerprint) {
        return
    }

    try {
        $exportPath = Convert-CodexSessionToMarkdown -SessionFile $file.FullName -ExportRoot $ExportRoot -SessionsRoot $SessionsRoot
        $State[$stateKey] = $fingerprint
        Save-State -State $State
        Write-Log "Exported $($file.FullName) -> $exportPath"
    } catch {
        Write-Log "Export failed for $($file.FullName): $($_.Exception.Message)"
    }
}

if (-not (Test-Path -LiteralPath $SessionsRoot)) {
    throw "Sessions root not found: $SessionsRoot"
}

$state = Load-State

Get-ChildItem -LiteralPath $SessionsRoot -Recurse -File -Filter "rollout-*.jsonl" |
    Sort-Object FullName |
    ForEach-Object {
        Export-IfChanged -Path $_.FullName -State $state
    }

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $SessionsRoot
$watcher.Filter = "*.jsonl"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$action = {
    $path = $Event.SourceEventArgs.FullPath
    Export-IfChanged -Path $path -State $state
}

$null = Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
$null = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
$null = Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action

Write-Log "Watcher started. SessionsRoot=$SessionsRoot ExportRoot=$ExportRoot"

while ($true) {
    Wait-Event -Timeout 60 | Out-Null
}
