param(
    [string]$SessionFile = "",
    [string]$CodexRoot = "",
    [string]$ExportRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($CodexRoot)) {
    $CodexRoot = Join-Path $HOME ".codex"
}

if ([string]::IsNullOrWhiteSpace($ExportRoot)) {
    $ExportRoot = Join-Path $CodexRoot "session-exports"
}

function Get-CodexSessionExportPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SessionFile,
        [Parameter(Mandatory = $true)]
        [string]$ExportRoot,
        [Parameter(Mandatory = $true)]
        [string]$SessionsRoot
    )

    $leaf = Split-Path -Leaf $SessionFile
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($leaf)
    $sessionsRootWithSlash = ($SessionsRoot.TrimEnd('\') + "\")
    $escapedSessionsRoot = [regex]::Escape($sessionsRootWithSlash)
    $relative = $SessionFile -replace "^$escapedSessionsRoot", ''
    $relativeDir = Split-Path -Parent $relative

    if ([string]::IsNullOrWhiteSpace($relativeDir)) {
        return Join-Path $ExportRoot ($baseName + ".md")
    }

    return Join-Path (Join-Path $ExportRoot $relativeDir) ($baseName + ".md")
}

function Get-CodexTextFromContent {
    param(
        [object[]]$Content
    )

    if (-not $Content) {
        return $null
    }

    $parts = foreach ($item in $Content) {
        if ($null -eq $item) {
            continue
        }

        $itemType = if ($item.PSObject.Properties["type"]) { [string]$item.type } else { "" }
        $itemText = if ($item.PSObject.Properties["text"]) { [string]$item.text } else { $null }

        if ($itemType -eq "input_text" -or $itemType -eq "output_text") {
            $itemText
            continue
        }

        if ($itemText) {
            $itemText
        }
    }

    $text = ($parts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`r`n`r`n"
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    return $text.Trim()
}

function Read-Utf8FileLines {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $fileStream = [System.IO.File]::Open(
        $Path,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::ReadWrite
    )
    $reader = [System.IO.StreamReader]::new($fileStream, [System.Text.UTF8Encoding]::new($false))

    try {
        while (-not $reader.EndOfStream) {
            $lines.Add($reader.ReadLine())
        }
    } finally {
        $reader.Dispose()
        $fileStream.Dispose()
    }

    return $lines
}

function Convert-CodexSessionToMarkdown {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SessionFile,
        [Parameter(Mandatory = $true)]
        [string]$ExportRoot,
        [Parameter(Mandatory = $true)]
        [string]$SessionsRoot
    )

    if (-not (Test-Path -LiteralPath $SessionFile)) {
        throw "Session file not found: $SessionFile"
    }

    $sessionMeta = $null
    $messages = New-Object System.Collections.Generic.List[object]
    $tokenSnapshots = New-Object System.Collections.Generic.List[object]
    $finalAnswer = $null

    foreach ($line in (Read-Utf8FileLines -Path $SessionFile)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        try {
            $entry = $line | ConvertFrom-Json
        } catch {
            continue
        }

        switch ($entry.type) {
            "session_meta" {
                $sessionMeta = $entry.payload
            }
            "response_item" {
                $payload = $entry.payload
                if ($null -eq $payload) {
                    continue
                }

                $payloadType = if ($payload.PSObject.Properties["type"]) { [string]$payload.type } else { "" }
                if ($payloadType -eq "message") {
                    $role = if ($payload.PSObject.Properties["role"]) { [string]$payload.role } else { "" }
                    if ($role -ne "user" -and $role -ne "assistant") {
                        continue
                    }

                    $content = if ($payload.PSObject.Properties["content"]) { $payload.content } else { $null }
                    $text = Get-CodexTextFromContent -Content $content
                    if ([string]::IsNullOrWhiteSpace($text)) {
                        continue
                    }

                    $phase = if ($payload.PSObject.Properties["phase"]) { [string]$payload.phase } else { "" }
                    $message = [pscustomobject]@{
                        timestamp = $entry.timestamp
                        role      = $role
                        phase     = $phase
                        text      = $text
                    }
                    $messages.Add($message)

                    if ($role -eq "assistant" -and $phase -eq "final_answer") {
                        $finalAnswer = $text
                    }
                }
            }
            "event_msg" {
                $payload = $entry.payload
                if ($null -eq $payload) {
                    continue
                }

                if ($payload.type -eq "token_count") {
                    $tokenSnapshots.Add([pscustomobject]@{
                        timestamp   = $entry.timestamp
                        info        = $payload.info
                        rate_limits = $payload.rate_limits
                    })
                }
            }
        }
    }

    $exportPath = Get-CodexSessionExportPath -SessionFile $SessionFile -ExportRoot $ExportRoot -SessionsRoot $SessionsRoot
    $exportDir = Split-Path -Parent $exportPath
    if (-not (Test-Path -LiteralPath $exportDir)) {
        New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
    }

    $lastSnapshot = $null
    if ($tokenSnapshots.Count -gt 0) {
        $lastSnapshot = $tokenSnapshots[$tokenSnapshots.Count - 1]
    }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Codex Session Export")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("## Source")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("- Session file: ``$SessionFile``")
    if ($sessionMeta) {
        [void]$sb.AppendLine("- Session id: ``$($sessionMeta.id)``")
        [void]$sb.AppendLine("- Started at: ``$($sessionMeta.timestamp)``")
        [void]$sb.AppendLine("- CWD: ``$($sessionMeta.cwd)``")
        [void]$sb.AppendLine("- Originator: ``$($sessionMeta.originator)``")
        [void]$sb.AppendLine("- CLI version: ``$($sessionMeta.cli_version)``")
        [void]$sb.AppendLine("- Model provider: ``$($sessionMeta.model_provider)``")
    }

    if ($lastSnapshot) {
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("## Latest Token Snapshot")
        [void]$sb.AppendLine()
        if ($lastSnapshot.info) {
            $info = $lastSnapshot.info
            $last = $info.last_token_usage
            $total = $info.total_token_usage
            $ctx = $info.model_context_window
            $ctxUsed = 0
            if ($ctx -and $last.input_tokens) {
                $ctxUsed = [math]::Round(($last.input_tokens / $ctx) * 100, 1)
            }

            [void]$sb.AppendLine("- Snapshot at: ``$($lastSnapshot.timestamp)``")
            [void]$sb.AppendLine("- Last input tokens: ``$($last.input_tokens)``")
            [void]$sb.AppendLine("- Last output tokens: ``$($last.output_tokens)``")
            [void]$sb.AppendLine("- Last total tokens: ``$($last.total_tokens)``")
            [void]$sb.AppendLine("- Session total tokens: ``$($total.total_tokens)``")
            [void]$sb.AppendLine("- Context window: ``$ctx``")
            [void]$sb.AppendLine("- Context used approx: ``$ctxUsed%``")
        }

        if ($lastSnapshot.rate_limits -and $lastSnapshot.rate_limits.primary) {
            [void]$sb.AppendLine("- Weekly used: ``$($lastSnapshot.rate_limits.primary.used_percent)%``")
        }
    }

    if ($finalAnswer) {
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("## Final Answer")
        [void]$sb.AppendLine()
        [void]$sb.AppendLine($finalAnswer)
    }

    [void]$sb.AppendLine()
    [void]$sb.AppendLine("## Transcript")
    [void]$sb.AppendLine()

    foreach ($message in $messages) {
        $titleRole = if ($message.role -eq "user") { "User" } else { "Assistant" }
        $phaseSuffix = if ([string]::IsNullOrWhiteSpace($message.phase)) { "" } else { " [$($message.phase)]" }
        [void]$sb.AppendLine("### $titleRole$phaseSuffix")
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("- Timestamp: ``$($message.timestamp)``")
        [void]$sb.AppendLine()
        [void]$sb.AppendLine($message.text)
        [void]$sb.AppendLine()
    }

    [System.IO.File]::WriteAllText($exportPath, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
    return $exportPath
}

if ($MyInvocation.InvocationName -ne "." -and -not [string]::IsNullOrWhiteSpace($SessionFile)) {
    $sessionsRoot = Join-Path $CodexRoot "sessions"
    Convert-CodexSessionToMarkdown -SessionFile $SessionFile -ExportRoot $ExportRoot -SessionsRoot $sessionsRoot
}
