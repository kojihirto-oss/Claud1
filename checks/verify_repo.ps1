param(
    [string]$Mode = "Fast"
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot | Split-Path -Parent

Write-Host "Running Verify Repo in $Mode mode..." -ForegroundColor Cyan

# 1. Markdown Header Check
Write-Host "Checking Markdown headers..." -ForegroundColor Yellow
$docsPath = Join-Path $root "docs"
if (-not (Test-Path $docsPath)) {
    Write-Host "Error: docs directory not found at $docsPath" -ForegroundColor Red
    exit 1
}

$docs = Get-ChildItem "$docsPath\*.md"
$failed = $false

foreach ($doc in $docs) {
    $content = Get-Content $doc.FullName
    if ($content.Count -gt 0 -and $content[0] -notmatch "^# ") {
        Write-Host "  [FAIL] $($doc.Name): First line is not a H1 header" -ForegroundColor Red
        $failed = $true
    }
}

# 2. Link Check (Simple)
Write-Host "Checking internal links..." -ForegroundColor Yellow
foreach ($doc in $docs) {
    $content = Get-Content $doc.FullName -Raw
    # Check for absolute paths (C:\...) which should not be in docs
    if ($content -match "C:\\Users\\") {
         Write-Host "  [WARN] $($doc.Name): Contains absolute path (C:\Users...)" -ForegroundColor Yellow
         # Warning only for now as some might be in code blocks
    }
}

# 3. Large File Check (50MB)
Write-Host "Checking for files over 50MB..." -ForegroundColor Yellow
$maxSizeBytes = 50MB
$sizeExceptionPatterns = @(
)

if ($sizeExceptionPatterns.Count -eq 0) {
    Write-Host "  Exceptions: none" -ForegroundColor DarkGray
} else {
    Write-Host "  Exceptions:" -ForegroundColor DarkGray
    $sizeExceptionPatterns | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
}

function Test-IsSizeException {
    param([string]$Path)
    foreach ($pattern in $sizeExceptionPatterns) {
        if ($Path -like $pattern) { return $true }
    }
    return $false
}

$largeFiles = @()

# Tracked files: check git blob size so LFS pointers do not fail.
$trackedPaths = git ls-files
foreach ($path in $trackedPaths) {
    if (Test-IsSizeException $path) { continue }
    $sizeText = git cat-file -s (":$path") 2>$null
    if ($sizeText) {
        $sizeBytes = [int64]$sizeText
        if ($sizeBytes -gt $maxSizeBytes) {
            $largeFiles += [pscustomobject]@{
                Path = $path
                SizeMB = [math]::Round($sizeBytes / 1MB, 2)
                Source = "tracked"
            }
        }
    }
}

# Untracked but not ignored files.
$untrackedPaths = git ls-files --others --exclude-standard
foreach ($path in $untrackedPaths) {
    if (Test-IsSizeException $path) { continue }
    $fullPath = Join-Path $root $path
    if (Test-Path $fullPath) {
        $sizeBytes = (Get-Item $fullPath).Length
        if ($sizeBytes -gt $maxSizeBytes) {
            $largeFiles += [pscustomobject]@{
                Path = $path
                SizeMB = [math]::Round($sizeBytes / 1MB, 2)
                Source = "untracked"
            }
        }
    }
}

if ($largeFiles.Count -gt 0) {
    Write-Host "  [FAIL] Files over 50MB detected:" -ForegroundColor Red
    $largeFiles | Sort-Object SizeMB -Descending | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Host $_ }
    $failed = $true
}

if ($failed) {
    Write-Host "Verify FAILED." -ForegroundColor Red
    exit 1
} else {
    Write-Host "Verify PASSED." -ForegroundColor Green
    exit 0
}
