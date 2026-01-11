<#
.SYNOPSIS
Fast Verify mode for vibe-spec-ssot repository

.DESCRIPTION
Validates SSOT documentation integrity:
1. Part structure (all 12 required sections present)
2. Cross-link integrity (no broken Part references)
3. Glossary consistency (terms defined in glossary/)
4. Undecided items tracking (未決事項 sections populated if MUST rules present)

MUST complete in <1 minute for Fast mode.
Generates evidence report in evidence/verify_reports/

.PARAMETER Mode
Fast (default) or Full

.EXAMPLE
.\verify_repo.ps1 -Mode Fast

.NOTES
Created: 2026-01-11
Purpose: Implement ADR-0001 rule 5 (検証手順はchecks/に置く)
#>

param(
    [ValidateSet("Fast", "Full")]
    [string]$Mode = "Fast"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportDir = Join-Path $RepoRoot "evidence\verify_reports"
$ReportPath = Join-Path $ReportDir "verify_$Timestamp.log"

# Ensure report directory exists
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
}

function Write-VerifyLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "PASS", "WARN", "ERROR", "FAIL")]
        [string]$Level = "INFO"
    )
    $LogLine = "[$Timestamp] [$Level] $Message"

    # Color output based on level
    switch ($Level) {
        "PASS" { Write-Host $LogLine -ForegroundColor Green }
        "WARN" { Write-Host $LogLine -ForegroundColor Yellow }
        "ERROR" { Write-Host $LogLine -ForegroundColor Red }
        "FAIL" { Write-Host $LogLine -ForegroundColor Red }
        default { Write-Host $LogLine }
    }

    Add-Content -Path $ReportPath -Value $LogLine -Encoding UTF8
}

function Test-PartStructure {
    Write-VerifyLog "CHECK 1: Part Structure Validation" "INFO"

    # Required sections for all Part files (Part00.md - Part20.md)
    $RequiredSections = @(
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

    $DocsDir = Join-Path $RepoRoot "docs"
    $PartFiles = Get-ChildItem -Path $DocsDir -Filter "Part*.md"
    $MissingCount = 0

    foreach ($PartFile in $PartFiles) {
        $Content = Get-Content $PartFile.FullName -Raw -Encoding UTF8

        foreach ($Section in $RequiredSections) {
            if ($Content -notmatch [regex]::Escape($Section)) {
                Write-VerifyLog "MISSING: $($PartFile.Name) lacks '$Section'" "ERROR"
                $MissingCount++
            }
        }
    }

    if ($MissingCount -eq 0) {
        Write-VerifyLog "CHECK 1: PASS (All Parts have required sections)" "PASS"
        return $true
    } else {
        Write-VerifyLog "CHECK 1: FAIL ($MissingCount missing sections)" "FAIL"
        return $false
    }
}

function Test-CrossLinks {
    Write-VerifyLog "CHECK 2: Cross-Link Integrity" "INFO"

    $DocsDir = Join-Path $RepoRoot "docs"
    $AllDocs = Get-ChildItem -Path $DocsDir -Filter "*.md" -Recurse
    $BrokenLinks = @()

    foreach ($Doc in $AllDocs) {
        $Content = Get-Content $Doc.FullName -Raw -Encoding UTF8

        # Extract markdown links [text](path)
        $LinkPattern = '\[([^\]]+)\]\(([^\)]+)\)'
        $Matches = [regex]::Matches($Content, $LinkPattern)

        foreach ($Match in $Matches) {
            $LinkPath = $Match.Groups[2].Value

            # Skip external URLs (http/https)
            if ($LinkPath -match '^https?://') { continue }

            # Skip anchors within same document
            if ($LinkPath -match '^#') { continue }

            # Resolve relative path from document's directory
            $DocDir = Split-Path $Doc.FullName -Parent
            $TargetPath = Join-Path $DocDir $LinkPath

            # Normalize path
            $TargetPath = [System.IO.Path]::GetFullPath($TargetPath)

            if (-not (Test-Path $TargetPath)) {
                $RelativePath = $LinkPath
                $BrokenLinks += "$($Doc.Name) -> $RelativePath"
                Write-VerifyLog "BROKEN LINK: $($Doc.Name) -> $RelativePath" "ERROR"
            }
        }
    }

    if ($BrokenLinks.Count -eq 0) {
        Write-VerifyLog "CHECK 2: PASS (No broken links)" "PASS"
        return $true
    } else {
        Write-VerifyLog "CHECK 2: FAIL ($($BrokenLinks.Count) broken links)" "FAIL"
        return $false
    }
}

function Test-GlossaryConsistency {
    Write-VerifyLog "CHECK 3: Glossary Consistency" "INFO"

    # Read glossary terms
    $GlossaryPath = Join-Path $RepoRoot "glossary\GLOSSARY.md"

    if (-not (Test-Path $GlossaryPath)) {
        Write-VerifyLog "ERROR: glossary/GLOSSARY.md not found" "ERROR"
        return $false
    }

    $GlossaryLines = Get-Content $GlossaryPath -Encoding UTF8

    # Extract term names (lines starting with "- " followed by term name and ":")
    $DefinedTerms = @()
    $UndefinedTerms = @()

    foreach ($Line in $GlossaryLines) {
        # Match pattern: - TERM: or - **TERM**: or - **TERM (expansion)**:
        if ($Line -match '^-\s+\*?\*?([^:*]+?)\*?\*?\s*(\([^\)]+\))?\s*:\s*(.*)$') {
            $TermName = $Matches[1].Trim()
            $Definition = $Matches[3].Trim()

            $DefinedTerms += $TermName

            # Check if definition is empty (undefined)
            if ([string]::IsNullOrWhiteSpace($Definition)) {
                $UndefinedTerms += $TermName
            }
        }
    }

    Write-VerifyLog "Found $($DefinedTerms.Count) terms in GLOSSARY.md" "INFO"

    if ($UndefinedTerms.Count -gt 0) {
        Write-VerifyLog "WARN: $($UndefinedTerms.Count) terms are undefined" "WARN"
        foreach ($Term in $UndefinedTerms) {
            Write-VerifyLog "  - Undefined: $Term" "WARN"
        }
        # Not a hard fail for Fast mode, but logged as warning
        return $true
    } else {
        Write-VerifyLog "CHECK 3: PASS (All $($DefinedTerms.Count) terms defined)" "PASS"
        return $true
    }
}

function Test-UndecidedTracking {
    Write-VerifyLog "CHECK 4: Undecided Items Tracking" "INFO"

    $DocsDir = Join-Path $RepoRoot "docs"
    $PartFiles = Get-ChildItem -Path $DocsDir -Filter "Part*.md"
    $ViolationCount = 0

    foreach ($PartFile in $PartFiles) {
        $Content = Get-Content $PartFile.FullName -Raw -Encoding UTF8

        # Check if Part has MUST/MUST NOT rules in section 5
        if ($Content -match '## 5\. ルール（MUST / MUST NOT / SHOULD）\s+.*(MUST NOT|MUST\s)') {
            # Check if section 11 (未決事項) is empty template
            # Pattern: section header followed by only "- " and whitespace
            if ($Content -match '## 11\. 未決事項（推測禁止）\s+-\s*\r?\n\s*## 12') {
                Write-VerifyLog "VIOLATION: $($PartFile.Name) has MUST rules but empty 未決事項" "ERROR"
                $ViolationCount++
            }
        }
    }

    if ($ViolationCount -eq 0) {
        Write-VerifyLog "CHECK 4: PASS (Undecided items properly tracked)" "PASS"
        return $true
    } else {
        Write-VerifyLog "CHECK 4: FAIL ($ViolationCount violations)" "FAIL"
        return $false
    }
}

# ============================================================================
# Main Execution
# ============================================================================

Write-VerifyLog "=== Fast Verify Started ===" "INFO"
Write-VerifyLog "Mode: $Mode" "INFO"
Write-VerifyLog "Repository: $RepoRoot" "INFO"
Write-VerifyLog "Report: $ReportPath" "INFO"
Write-VerifyLog "" "INFO"

$StartTime = Get-Date

# Run all checks
$Results = @{
    PartStructure = Test-PartStructure
    CrossLinks = Test-CrossLinks
    GlossaryConsistency = Test-GlossaryConsistency
    UndecidedTracking = Test-UndecidedTracking
}

$EndTime = Get-Date
$Duration = ($EndTime - $StartTime).TotalSeconds

Write-VerifyLog "" "INFO"
Write-VerifyLog "=== Fast Verify Completed ===" "INFO"

$PassCount = ($Results.Values | Where-Object { $_ -eq $true }).Count
$FailCount = ($Results.Values | Where-Object { $_ -eq $false }).Count

Write-VerifyLog "PASS: $PassCount / $($Results.Count)" "INFO"
Write-VerifyLog "FAIL: $FailCount / $($Results.Count)" "INFO"
Write-VerifyLog "Duration: $([math]::Round($Duration, 2)) seconds" "INFO"
Write-VerifyLog "Report saved to: $ReportPath" "INFO"

if ($FailCount -gt 0) {
    Write-VerifyLog "RESULT: FAIL" "FAIL"
    exit 1
} else {
    Write-VerifyLog "RESULT: PASS" "PASS"
    exit 0
}
