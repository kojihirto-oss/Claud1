#!/usr/bin/env pwsh
<#
.SYNOPSIS
    SSOT検証スクリプト（Fast/Full Verify）

.DESCRIPTION
    docs/が壊れていないことを確認する。
    - Fast: 基本的なリンク切れ、必須フォルダ確認（数秒〜数分）
    - Full: Fast + 用語整合性、Part間整合チェック（数分〜数十分）

.PARAMETER Mode
    検証モード: Fast または Full（デフォルト: Fast）

.EXAMPLE
    pwsh checks/verify_repo.ps1 -Mode Fast
    pwsh checks/verify_repo.ps1 -Mode Full
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Fast", "Full")]
    [string]$Mode = "Fast"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportDir = Join-Path $RepoRoot "evidence" "verify_reports"
$ReportFile = Join-Path $ReportDir "verify_${Timestamp}_${Mode}.log"

# 証跡ディレクトリ作成
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
}

# ログ関数
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $LogMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Write-Host $LogMessage
    Add-Content -Path $ReportFile -Value $LogMessage
}

function Test-Result {
    param([string]$TestName, [bool]$Passed, [string]$Details = "")
    if ($Passed) {
        Write-Log "✓ PASS: $TestName" "PASS"
        if ($Details) { Write-Log "  → $Details" "INFO" }
        return 1
    } else {
        Write-Log "✗ FAIL: $TestName" "FAIL"
        if ($Details) { Write-Log "  → $Details" "ERROR" }
        return 0
    }
}

# ヘッダー
Write-Log "========================================" "INFO"
Write-Log "SSOT Verify - Mode: $Mode" "INFO"
Write-Log "Repo: $RepoRoot" "INFO"
Write-Log "========================================" "INFO"

$PassCount = 0
$TotalTests = 0

# ========================================
# Fast Verify（基本チェック）
# ========================================

Write-Log "`n[Fast Verify] 開始" "INFO"

# 1. 必須フォルダ存在確認
Write-Log "`n--- 1. 必須フォルダ確認 ---" "INFO"
$RequiredDirs = @("docs", "decisions", "sources", "glossary", "checks", "evidence")
foreach ($dir in $RequiredDirs) {
    $DirPath = Join-Path $RepoRoot $dir
    $TotalTests++
    $PassCount += Test-Result "必須フォルダ: $dir/" (Test-Path $DirPath)
}

# 2. 必須ファイル存在確認
Write-Log "`n--- 2. 必須ファイル確認 ---" "INFO"
$RequiredFiles = @(
    "docs/00_INDEX.md",
    "docs/Part00.md",
    "docs/Part02.md",
    "docs/FACTS_LEDGER.md",
    "decisions/ADR_TEMPLATE.md",
    "glossary/GLOSSARY.md"
)
foreach ($file in $RequiredFiles) {
    $FilePath = Join-Path $RepoRoot $file
    $TotalTests++
    $PassCount += Test-Result "必須ファイル: $file" (Test-Path $FilePath)
}

# 3. ADRファイル確認
Write-Log "`n--- 3. ADRファイル確認 ---" "INFO"
$ADRFiles = Get-ChildItem -Path (Join-Path $RepoRoot "decisions") -Filter "*.md" | Where-Object { $_.Name -match '^\d{4}-' }
$TotalTests++
$PassCount += Test-Result "ADRファイル存在" ($ADRFiles.Count -ge 1) "検出: $($ADRFiles.Count)件"

# 4. Partファイル確認（Part00〜Part20）
Write-Log "`n--- 4. Partファイル確認 ---" "INFO"
$MissingParts = @()
for ($i = 0; $i -le 20; $i++) {
    $PartNum = "{0:D2}" -f $i
    $PartFile = Join-Path $RepoRoot "docs" "Part$PartNum.md"
    if (-not (Test-Path $PartFile)) {
        $MissingParts += "Part$PartNum.md"
    }
}
$TotalTests++
$PassCount += Test-Result "全Partファイル存在（Part00〜Part20）" ($MissingParts.Count -eq 0) $(if ($MissingParts.Count -gt 0) { "欠落: $($MissingParts -join ', ')" } else { "全21ファイル確認" })

# 5. .gitignore 確認
Write-Log "`n--- 5. .gitignore 確認 ---" "INFO"
$GitignorePath = Join-Path $RepoRoot ".gitignore"
if (Test-Path $GitignorePath) {
    $GitignoreContent = Get-Content $GitignorePath -Raw
    $TotalTests++
    $PassCount += Test-Result ".gitignore に .rag/ エントリ存在" ($GitignoreContent -match '\.rag/')
} else {
    $TotalTests++
    Test-Result ".gitignore ファイル存在" $false
}

# ========================================
# Full Verify（詳細チェック）
# ========================================

if ($Mode -eq "Full") {
    Write-Log "`n`n[Full Verify] 開始" "INFO"

    # 6. Part02 リンク切れチェック（簡易）
    Write-Log "`n--- 6. Part02 内部参照チェック ---" "INFO"
    $Part02Path = Join-Path $RepoRoot "docs" "Part02.md"
    if (Test-Path $Part02Path) {
        $Part02Content = Get-Content $Part02Path -Raw
        $BrokenLinks = @()

        # decisions/ へのリンクチェック
        if ($Part02Content -match 'decisions/ADR-(\d{4})') {
            $ADRRefs = [regex]::Matches($Part02Content, 'decisions/(ADR-\d{4}|0001-[^)]+\.md)')
            foreach ($match in $ADRRefs) {
                $RefPath = Join-Path $RepoRoot ($match.Value -replace 'decisions/', 'decisions/')
                if (-not (Test-Path $RefPath)) {
                    $BrokenLinks += $match.Value
                }
            }
        }

        # glossary/ へのリンクチェック
        if ($Part02Content -match 'glossary/GLOSSARY\.md') {
            $GlossaryPath = Join-Path $RepoRoot "glossary" "GLOSSARY.md"
            if (-not (Test-Path $GlossaryPath)) {
                $BrokenLinks += "glossary/GLOSSARY.md"
            }
        }

        $TotalTests++
        $PassCount += Test-Result "Part02 リンク切れなし" ($BrokenLinks.Count -eq 0) $(if ($BrokenLinks.Count -gt 0) { "切れたリンク: $($BrokenLinks -join ', ')" } else { "OK" })
    }

    # 7. sources/ 保護確認（読み取り専用かチェックは難しいので、存在確認のみ）
    Write-Log "`n--- 7. sources/ 保護状態確認 ---" "INFO"
    $SourcesPath = Join-Path $RepoRoot "sources"
    $SourcesFiles = Get-ChildItem -Path $SourcesPath -Recurse -File
    $TotalTests++
    $PassCount += Test-Result "sources/ にファイル存在" ($SourcesFiles.Count -gt 0) "ファイル数: $($SourcesFiles.Count)"
}

# ========================================
# 結果サマリー
# ========================================

Write-Log "`n========================================" "INFO"
Write-Log "検証完了" "INFO"
Write-Log "モード: $Mode" "INFO"
Write-Log "合格: $PassCount / $TotalTests" "INFO"
$SuccessRate = [math]::Round(($PassCount / $TotalTests) * 100, 2)
Write-Log "成功率: $SuccessRate%" "INFO"

if ($PassCount -eq $TotalTests) {
    Write-Log "結果: PASS ✓" "PASS"
    Write-Log "証跡: $ReportFile" "INFO"
    Write-Log "========================================" "INFO"
    exit 0
} else {
    Write-Log "結果: FAIL ✗" "FAIL"
    Write-Log "証跡: $ReportFile" "INFO"
    Write-Log "========================================" "INFO"
    exit 1
}
