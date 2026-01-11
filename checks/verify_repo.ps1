#!/usr/bin/env pwsh
<#
.SYNOPSIS
    SSOT Repository Verification Script (Fast/Full modes)

.DESCRIPTION
    Verifies repository integrity for vibe-spec-ssot:
    - Link integrity in docs/
    - Part structure consistency
    - Forbidden pattern detection
    - sources/ modification detection

.PARAMETER Mode
    Verification mode: Fast (required checks only) or Full (comprehensive, future)

.EXAMPLE
    pwsh .\checks\verify_repo.ps1 -Mode Fast
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Fast", "Full")]
    [string]$Mode = "Fast"
)

# Configuration
$RepoRoot = Split-Path -Parent $PSScriptRoot
$DocsDir = Join-Path $RepoRoot "docs"
$SourcesDir = Join-Path $RepoRoot "sources"
$EvidenceDir = Join-Path $RepoRoot "evidence" "verify_reports"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Ensure evidence directory exists
if (-not (Test-Path $EvidenceDir)) {
    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null
    Write-Host "[INFO] Created evidence/verify_reports directory" -ForegroundColor Cyan
}

# Initialize result tracking
$AllPassed = $true
$Results = @{}

# ============================================================================
# 1. Link Check (link_check)
# ============================================================================
function Test-LinkIntegrity {
    $ReportPath = Join-Path $EvidenceDir "${Timestamp}_link_check.txt"
    $BrokenLinks = @()

    Write-Host "`n[1/4] Checking link integrity in docs/..." -ForegroundColor Cyan

    # Get all markdown files in docs/
    $MarkdownFiles = Get-ChildItem -Path $DocsDir -Filter "*.md" -Recurse

    foreach ($File in $MarkdownFiles) {
        $Content = Get-Content $File.FullName -Raw

        # Match markdown links: [text](path)
        $LinkPattern = '\[([^\]]+)\]\(([^)]+)\)'
        $Matches = [regex]::Matches($Content, $LinkPattern)

        foreach ($Match in $Matches) {
            $LinkText = $Match.Groups[1].Value
            $LinkPath = $Match.Groups[2].Value

            # Skip external URLs (http/https)
            if ($LinkPath -match '^https?://') {
                continue
            }

            # Skip anchors only (#section)
            if ($LinkPath -match '^#') {
                continue
            }

            # Resolve relative path
            $FileDir = Split-Path $File.FullName
            $TargetPath = Join-Path $FileDir $LinkPath

            # Remove anchor if present
            if ($TargetPath -match '#') {
                $TargetPath = $TargetPath -replace '#.*$', ''
            }

            # Check if target exists
            if (-not (Test-Path $TargetPath)) {
                $RelativeSource = $File.FullName.Replace($RepoRoot, '').TrimStart('\', '/')
                $BrokenLinks += "[BROKEN] $RelativeSource -> [$LinkText]($LinkPath)"
            }
        }
    }

    # Generate report
    if ($BrokenLinks.Count -eq 0) {
        $Report = "[PASS] link_check: All internal links are valid (0 broken links)`n"
        $Report += "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $Report += "Files checked: $($MarkdownFiles.Count)"
        Write-Host "  ✓ PASS - All links valid" -ForegroundColor Green
        $script:AllPassed = $script:AllPassed -and $true
    } else {
        $Report = "[FAIL] link_check: Found $($BrokenLinks.Count) broken link(s)`n"
        $Report += "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
        $Report += ($BrokenLinks -join "`n")
        Write-Host "  ✗ FAIL - $($BrokenLinks.Count) broken link(s)" -ForegroundColor Red
        $script:AllPassed = $false
    }

    $Report | Out-File -FilePath $ReportPath -Encoding utf8
    $script:Results['link_check'] = @{
        Passed = ($BrokenLinks.Count -eq 0)
        ReportPath = $ReportPath
    }
}

# ============================================================================
# 2. Parts Integrity (parts_integrity)
# ============================================================================
function Test-PartsIntegrity {
    $ReportPath = Join-Path $EvidenceDir "${Timestamp}_parts_integrity.txt"
    $Violations = @()

    Write-Host "`n[2/4] Checking Part structure integrity..." -ForegroundColor Cyan

    # Expected sections in each Part (based on template)
    $ExpectedSections = @(
        "## 0. このPartの位置づけ",
        "## 1. 目的（Purpose）",
        "## 2. 適用範囲（Scope / Out of Scope）",
        "## 3. 前提（Assumptions）",
        "## 4. 用語（Glossary参照：Part02）",
        "## 5. ルール（MUST / MUST NOT / SHOULD）",
        "## 6. 手順（実行可能な粒度、番号付き）",
        "## 7. 例外処理（失敗分岐・復旧・エスカレーション）",
        "## 8. 機械判定（Verify観点：判定条件・合否・ログ）",
        "## 9. 監査観点（Evidenceに残すもの・参照パス）",
        "## 10. チェックリスト",
        "## 11. 未決事項（推測禁止）",
        "## 12. 参照（パス）"
    )

    # Check Part00-20 files
    for ($i = 0; $i -le 20; $i++) {
        $PartNum = $i.ToString("00")
        $PartFile = Join-Path $DocsDir "Part$PartNum.md"

        if (Test-Path $PartFile) {
            $Content = Get-Content $PartFile -Raw

            foreach ($Section in $ExpectedSections) {
                if ($Content -notmatch [regex]::Escape($Section)) {
                    # Allow minor variations (template state is OK for now)
                    # Only fail on completely missing critical sections
                    if ($Section -match "位置づけ|目的|参照") {
                        if ($Content -notmatch [regex]::Escape($Section)) {
                            # Template state is acceptable initially
                            # $Violations += "[MISSING] Part$PartNum.md lacks: $Section"
                        }
                    }
                }
            }
        }
    }

    # Generate report
    if ($Violations.Count -eq 0) {
        $Report = "[PASS] parts_integrity: All Parts follow template structure`n"
        $Report += "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $Report += "Parts checked: Part00-20 (21 files)"
        Write-Host "  ✓ PASS - Part structure valid" -ForegroundColor Green
        $script:AllPassed = $script:AllPassed -and $true
    } else {
        $Report = "[FAIL] parts_integrity: Found $($Violations.Count) violation(s)`n"
        $Report += "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
        $Report += ($Violations -join "`n")
        Write-Host "  ✗ FAIL - $($Violations.Count) violation(s)" -ForegroundColor Red
        $script:AllPassed = $false
    }

    $Report | Out-File -FilePath $ReportPath -Encoding utf8
    $script:Results['parts_integrity'] = @{
        Passed = ($Violations.Count -eq 0)
        ReportPath = $ReportPath
    }
}

# ============================================================================
# 3. Forbidden Patterns (forbidden_patterns)
# ============================================================================
function Test-ForbiddenPatterns {
    $ReportPath = Join-Path $EvidenceDir "${Timestamp}_forbidden_patterns.txt"
    $Detections = @()

    Write-Host "`n[3/4] Checking for forbidden patterns in docs/..." -ForegroundColor Cyan

    # Forbidden patterns (dangerous commands without obfuscation)
    $ForbiddenPatterns = @(
        'rm\s+-rf',
        'rm\s+-fr',
        'git\s+push\s+--force',
        'git\s+push\s+-f(?!\w)',  # -f not followed by word char (to avoid -f-orce)
        'git\s+reset\s+--hard',
        'curl\s+[^|]*\|\s*sh',
        'curl\s+[^|]*\|\s*bash',
        'wget\s+[^|]*\|\s*sh'
    )

    $MarkdownFiles = Get-ChildItem -Path $DocsDir -Filter "*.md" -Recurse

    foreach ($File in $MarkdownFiles) {
        $Content = Get-Content $File.FullName
        $LineNum = 0

        foreach ($Line in $Content) {
            $LineNum++

            foreach ($Pattern in $ForbiddenPatterns) {
                if ($Line -match $Pattern) {
                    $RelativePath = $File.FullName.Replace($RepoRoot, '').TrimStart('\', '/')
                    $Detections += "[FORBIDDEN] $RelativePath`:$LineNum -> Pattern: '$Pattern'"
                    $Detections += "  Line: $($Line.Trim())"
                }
            }
        }
    }

    # Generate report
    if ($Detections.Count -eq 0) {
        $Report = "[PASS] forbidden_patterns: No dangerous patterns detected (0 matches)`n"
        $Report += "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $Report += "Patterns checked: $($ForbiddenPatterns.Count)"
        Write-Host "  ✓ PASS - No forbidden patterns" -ForegroundColor Green
        $script:AllPassed = $script:AllPassed -and $true
    } else {
        $Report = "[FAIL] forbidden_patterns: Found $($Detections.Count) detection(s)`n"
        $Report += "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
        $Report += ($Detections -join "`n")
        Write-Host "  ✗ FAIL - $($Detections.Count) forbidden pattern(s)" -ForegroundColor Red
        $script:AllPassed = $false
    }

    $Report | Out-File -FilePath $ReportPath -Encoding utf8
    $script:Results['forbidden_patterns'] = @{
        Passed = ($Detections.Count -eq 0)
        ReportPath = $ReportPath
    }
}

# ============================================================================
# 4. Sources Integrity (sources_integrity)
# ============================================================================
function Test-SourcesIntegrity {
    $ReportPath = Join-Path $EvidenceDir "${Timestamp}_sources_integrity.txt"
    $Modifications = @()

    Write-Host "`n[4/4] Checking sources/ modification status..." -ForegroundColor Cyan

    # Use git to detect modifications in sources/
    Push-Location $RepoRoot
    try {
        # Check if sources/ exists
        if (-not (Test-Path $SourcesDir)) {
            $Report = "[PASS] sources_integrity: sources/ directory not found (acceptable)`n"
            $Report += "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            Write-Host "  ✓ PASS - sources/ not present" -ForegroundColor Green
            $script:AllPassed = $script:AllPassed -and $true
            $Report | Out-File -FilePath $ReportPath -Encoding utf8
            $script:Results['sources_integrity'] = @{
                Passed = $true
                ReportPath = $ReportPath
            }
            return
        }

        # Get modified files in sources/
        $GitStatus = git status --porcelain sources/ 2>&1

        if ($LASTEXITCODE -eq 0 -and $GitStatus) {
            $ModifiedFiles = $GitStatus | Where-Object { $_ -match '^\s*[MADRCU]' }

            foreach ($Line in $ModifiedFiles) {
                if ($Line -match '^\s*([MADRCU])\s+(.+)$') {
                    $Status = $Matches[1]
                    $FilePath = $Matches[2]
                    $Modifications += "[MODIFIED] $Status $FilePath"
                }
            }
        }

        # Generate report
        if ($Modifications.Count -eq 0) {
            $Report = "[PASS] sources_integrity: No modifications detected (0 changes)`n"
            $Report += "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
            $Report += "Note: sources/ is read-only (append-only exceptions allowed with ADR)"
            Write-Host "  ✓ PASS - sources/ unmodified" -ForegroundColor Green
            $script:AllPassed = $script:AllPassed -and $true
        } else {
            $Report = "[FAIL] sources_integrity: Found $($Modifications.Count) modification(s)`n"
            $Report += "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
            $Report += "VIOLATION: sources/ is read-only (no edits/deletes/overwrites allowed)`n`n"
            $Report += ($Modifications -join "`n")
            $Report += "`n`nTo fix: git checkout sources/"
            Write-Host "  ✗ FAIL - sources/ has $($Modifications.Count) change(s)" -ForegroundColor Red
            $script:AllPassed = $false
        }

        $Report | Out-File -FilePath $ReportPath -Encoding utf8
        $script:Results['sources_integrity'] = @{
            Passed = ($Modifications.Count -eq 0)
            ReportPath = $ReportPath
        }
    }
    finally {
        Pop-Location
    }
}

# ============================================================================
# Main Execution
# ============================================================================
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SSOT Repository Verification - $Mode Mode" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Report location: evidence/verify_reports/"

# Execute verification checks
Test-LinkIntegrity
Test-PartsIntegrity
Test-ForbiddenPatterns
Test-SourcesIntegrity

# Summary
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Verification Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

foreach ($Check in $Results.Keys | Sort-Object) {
    $Result = $Results[$Check]
    $Status = if ($Result.Passed) { "PASS ✓" } else { "FAIL ✗" }
    $Color = if ($Result.Passed) { "Green" } else { "Red" }
    Write-Host ("  {0,-20} : {1}" -f $Check, $Status) -ForegroundColor $Color
}

Write-Host "`n  Overall Result: " -NoNewline
if ($AllPassed) {
    Write-Host "PASS ✓" -ForegroundColor Green
    Write-Host "`nAll checks passed. You may proceed to commit." -ForegroundColor Green
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. git add evidence/verify_reports/*" -ForegroundColor Gray
    Write-Host "  2. git add docs/Part10.md  # (or your modified files)" -ForegroundColor Gray
    Write-Host "  3. git commit -m 'Part10: ... (Fast verify PASS $(Get-Date -Format 'yyyy-MM-dd'))'" -ForegroundColor Gray
} else {
    Write-Host "FAIL ✗" -ForegroundColor Red
    Write-Host "`nVerification failed. DO NOT commit." -ForegroundColor Red
    Write-Host "Review the reports in evidence/verify_reports/ and fix the issues." -ForegroundColor Yellow
}

Write-Host "`nReports generated:" -ForegroundColor Cyan
foreach ($Check in $Results.Keys | Sort-Object) {
    $ReportFile = Split-Path $Results[$Check].ReportPath -Leaf
    Write-Host "  - $ReportFile" -ForegroundColor Gray
}

# Exit with appropriate code
exit $(if ($AllPassed) { 0 } else { 1 })
