param(
    [string]$BaseRef = "HEAD"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$codePatterns = @(
    "scripts/*.ps1",
    "src/*",
    "app/*"
)

$docPatterns = @(
    "CHANGELOG.md",
    "README.md",
    "CONTRIBUTING.md",
    "docs/*",
    ".github/PULL_REQUEST_TEMPLATE.md"
)

$changedFiles = git diff --name-only $BaseRef
if ($LASTEXITCODE -ne 0) {
    throw "Unable to read git diff against $BaseRef"
}

if (-not $changedFiles) {
    Write-Output "No changed files detected against $BaseRef."
    exit 0
}

$hasCodeChanges = $false
foreach ($pattern in $codePatterns) {
    if ($changedFiles | Where-Object { $_ -like $pattern }) {
        $hasCodeChanges = $true
        break
    }
}

if (-not $hasCodeChanges) {
    Write-Output "No code changes matched the configured paths."
    exit 0
}

$hasDocChanges = $false
foreach ($pattern in $docPatterns) {
    if ($changedFiles | Where-Object { $_ -like $pattern }) {
        $hasDocChanges = $true
        break
    }
}

if ($hasDocChanges) {
    Write-Output "Code changes detected and docs were updated in the same diff."
    exit 0
}

Write-Warning "Code changes were detected, but no docs files changed."
Write-Warning "Review CHANGELOG.md, README.md, CONTRIBUTING.md, docs/*, and examples before committing."
exit 0