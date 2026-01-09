# vibekanban.ps1 - VIBE Coding 自動化スクリプト（MVP版）
# 使い方: このファイルを $PROFILE にドットソースするか、関数を直接コピー
# 例: . .\vibekanban.ps1

<#
.SYNOPSIS
    VIBEKANBANの状態を表示する
.DESCRIPTION
    WORK/配下のチケット状態を一覧表示
.EXAMPLE
    vibekanban-status
#>
function vibekanban-status {
    [CmdletBinding()]
    param()
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  VIBEKANBAN Status" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $workPath = ".\WORK"
    
    if (-not (Test-Path $workPath)) {
        Write-Host "  ⚠️  WORK/ フォルダが見つかりません" -ForegroundColor Yellow
        Write-Host "  → 'mkdir WORK' で作成してください" -ForegroundColor Gray
        return
    }
    
    $tickets = Get-ChildItem -Path $workPath -Directory -ErrorAction SilentlyContinue
    
    if ($tickets.Count -eq 0) {
        Write-Host "  📭 アクティブなチケットはありません" -ForegroundColor Gray
        Write-Host "  → 'vibekanban-new <名前>' で新規作成" -ForegroundColor Gray
        return
    }
    
    $active = 0
    $done = 0
    
    foreach ($ticket in $tickets) {
        $ticketName = $ticket.Name
        $ticketPath = $ticket.FullName
        $hasTicket = Test-Path "$ticketPath\TICKET.md"
        $hasDone = Test-Path "$ticketPath\DONE.md"
        $hasContext = Test-Path "$ticketPath\CONTEXT_PACK.md"
        
        # サイズ判定
        $size = "?"
        if ($hasTicket) {
            $ticketContent = Get-Content "$ticketPath\TICKET.md" -Raw -ErrorAction SilentlyContinue
            if ($ticketContent -match "サイズ:\s*(S|M|L|XL)") {
                $size = $matches[1]
            }
        }
        
        # ステータス判定
        if ($hasDone) {
            $status = "✅ DONE"
            $statusColor = "Green"
            $done++
        } elseif ($hasContext) {
            $status = "🔨 BUILD"
            $statusColor = "Yellow"
            $active++
        } elseif ($hasTicket) {
            $status = "📋 PLAN"
            $statusColor = "Cyan"
            $active++
        } else {
            $status = "❓ EMPTY"
            $statusColor = "Gray"
        }
        
        Write-Host "  $status " -ForegroundColor $statusColor -NoNewline
        Write-Host "[$size] " -ForegroundColor Magenta -NoNewline
        Write-Host "$ticketName" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Active: $active  |  Done: $done  |  Total: $($tickets.Count)" -ForegroundColor Gray
    Write-Host ""
}

<#
.SYNOPSIS
    新規チケットを作成する
.DESCRIPTION
    WORK/配下に新規チケットフォルダを作成し、テンプレートをコピー
.PARAMETER Name
    チケット名（フォルダ名になる）
.PARAMETER Size
    チケットサイズ: S, M, L, XL（デフォルト: M）
.EXAMPLE
    vibekanban-new "feature-login" -Size M
    vibekanban-new "bugfix-auth" S
#>
function vibekanban-new {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,
        
        [Parameter(Position=1)]
        [ValidateSet("S", "M", "L", "XL")]
        [string]$Size = "M"
    )
    
    $workPath = ".\WORK"
    $templatesPath = ".\TEMPLATES"
    $ticketPath = "$workPath\$Name"
    
    # WORK/フォルダがなければ作成
    if (-not (Test-Path $workPath)) {
        New-Item -ItemType Directory -Path $workPath -Force | Out-Null
        Write-Host "  📁 WORK/ フォルダを作成しました" -ForegroundColor Gray
    }
    
    # 既存チェック
    if (Test-Path $ticketPath) {
        Write-Host "  ⚠️  '$Name' は既に存在します" -ForegroundColor Yellow
        return
    }
    
    # チケットフォルダ作成
    New-Item -ItemType Directory -Path $ticketPath -Force | Out-Null
    
    # テンプレートコピー
    $templateFile = "$templatesPath\TICKET_$Size.md"
    if (Test-Path $templateFile) {
        Copy-Item $templateFile "$ticketPath\TICKET.md"
        Write-Host ""
        Write-Host "  ✅ チケット作成完了" -ForegroundColor Green
        Write-Host ""
        Write-Host "  📁 Path: $ticketPath" -ForegroundColor Cyan
        Write-Host "  📋 Size: $Size" -ForegroundColor Magenta
        Write-Host "  📝 File: TICKET.md" -ForegroundColor White
        Write-Host ""
        Write-Host "  → TICKET.md を編集してください" -ForegroundColor Gray
    } else {
        # テンプレートがない場合は最小限のTICKET.mdを作成
        $minimalTemplate = @"
# TICKET: $Name

## サイズ: $Size

## 何をやるか


## なぜやるか


## 受入基準
- [ ] 

"@
        Set-Content -Path "$ticketPath\TICKET.md" -Value $minimalTemplate -Encoding UTF8
        Write-Host ""
        Write-Host "  ✅ チケット作成完了（テンプレートなし）" -ForegroundColor Green
        Write-Host "  💡 TEMPLATES/TICKET_$Size.md を配置すると自動コピーされます" -ForegroundColor Gray
        Write-Host ""
    }
}

<#
.SYNOPSIS
    Fast Verifyを実行する
.DESCRIPTION
    lint と test を実行して合否判定
.PARAMETER Full
    Full Verify（ビルド含む）を実行
.EXAMPLE
    vibekanban-verify
    vibekanban-verify -Full
#>
function vibekanban-verify {
    [CmdletBinding()]
    param(
        [switch]$Full
    )
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    if ($Full) {
        Write-Host "  Full Verify" -ForegroundColor Cyan
    } else {
        Write-Host "  Fast Verify" -ForegroundColor Cyan
    }
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $results = @()
    $allPassed = $true
    
    # パッケージマネージャ検出
    $useNpm = Test-Path ".\package.json"
    $usePython = Test-Path ".\requirements.txt" -or Test-Path ".\pyproject.toml"
    
    if ($useNpm) {
        # === npm/node プロジェクト ===
        
        # Lint
        Write-Host "  🔍 Running lint..." -ForegroundColor Yellow
        $lintResult = npm run lint 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results += @{Name="Lint"; Status="PASS"; Color="Green"}
        } else {
            $results += @{Name="Lint"; Status="FAIL"; Color="Red"}
            $allPassed = $false
        }
        
        # Test
        Write-Host "  🧪 Running tests..." -ForegroundColor Yellow
        $testResult = npm test 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results += @{Name="Test"; Status="PASS"; Color="Green"}
        } else {
            $results += @{Name="Test"; Status="FAIL"; Color="Red"}
            $allPassed = $false
        }
        
        # Full Verify追加項目
        if ($Full) {
            # Build
            Write-Host "  🏗️  Running build..." -ForegroundColor Yellow
            $buildResult = npm run build 2>&1
            if ($LASTEXITCODE -eq 0) {
                $results += @{Name="Build"; Status="PASS"; Color="Green"}
            } else {
                $results += @{Name="Build"; Status="FAIL"; Color="Red"}
                $allPassed = $false
            }
        }
    }
    elseif ($usePython) {
        # === Python プロジェクト ===
        
        # Lint (ruff or flake8)
        Write-Host "  🔍 Running lint..." -ForegroundColor Yellow
        if (Get-Command ruff -ErrorAction SilentlyContinue) {
            $lintResult = ruff check . 2>&1
        } elseif (Get-Command flake8 -ErrorAction SilentlyContinue) {
            $lintResult = flake8 . 2>&1
        } else {
            Write-Host "    ⚠️  No linter found (ruff/flake8)" -ForegroundColor Gray
            $LASTEXITCODE = 0
        }
        if ($LASTEXITCODE -eq 0) {
            $results += @{Name="Lint"; Status="PASS"; Color="Green"}
        } else {
            $results += @{Name="Lint"; Status="FAIL"; Color="Red"}
            $allPassed = $false
        }
        
        # Test
        Write-Host "  🧪 Running tests..." -ForegroundColor Yellow
        $testResult = pytest 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results += @{Name="Test"; Status="PASS"; Color="Green"}
        } else {
            $results += @{Name="Test"; Status="FAIL"; Color="Red"}
            $allPassed = $false
        }
    }
    else {
        Write-Host "  ⚠️  package.json または requirements.txt が見つかりません" -ForegroundColor Yellow
        Write-Host "  → プロジェクトルートで実行してください" -ForegroundColor Gray
        return
    }
    
    # 結果表示
    Write-Host ""
    Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Results:" -ForegroundColor White
    foreach ($r in $results) {
        $icon = if ($r.Status -eq "PASS") { "✅" } else { "❌" }
        Write-Host "    $icon $($r.Name): " -NoNewline
        Write-Host $r.Status -ForegroundColor $r.Color
    }
    Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    
    if ($allPassed) {
        Write-Host "  🎉 ALL PASSED" -ForegroundColor Green
    } else {
        Write-Host "  💥 VERIFY FAILED" -ForegroundColor Red
        Write-Host "  → エラーログを確認して修正してください" -ForegroundColor Gray
    }
    Write-Host ""
    
    return $allPassed
}

<#
.SYNOPSIS
    チケットを完了状態にする
.DESCRIPTION
    DONE.mdを作成し、完了処理を行う
.PARAMETER Name
    チケット名
.EXAMPLE
    vibekanban-done "feature-login"
#>
function vibekanban-done {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name
    )
    
    $ticketPath = ".\WORK\$Name"
    $templatesPath = ".\TEMPLATES"
    
    if (-not (Test-Path $ticketPath)) {
        Write-Host "  ⚠️  '$Name' が見つかりません" -ForegroundColor Yellow
        return
    }
    
    if (Test-Path "$ticketPath\DONE.md") {
        Write-Host "  ⚠️  '$Name' は既に完了しています" -ForegroundColor Yellow
        return
    }
    
    # DONE.mdテンプレートコピー
    $templateFile = "$templatesPath\DONE.md"
    if (Test-Path $templateFile) {
        Copy-Item $templateFile "$ticketPath\DONE.md"
    } else {
        $minimalDone = @"
# DONE: $Name

## 完了日: $(Get-Date -Format "yyyy-MM-dd")

## 何を変えたか


## なぜ変えたか


## どう検証したか
- [ ] Fast Verify通過

## 学び

"@
        Set-Content -Path "$ticketPath\DONE.md" -Value $minimalDone -Encoding UTF8
    }
    
    Write-Host ""
    Write-Host "  ✅ DONE.md を作成しました" -ForegroundColor Green
    Write-Host "  📝 $ticketPath\DONE.md を編集してください" -ForegroundColor Gray
    Write-Host ""
}

# エクスポート
Export-ModuleMember -Function vibekanban-status, vibekanban-new, vibekanban-verify, vibekanban-done

# 直接実行時のヘルプ
Write-Host ""
Write-Host "  VIBEKANBAN Commands Loaded:" -ForegroundColor Cyan
Write-Host "    vibekanban-status          現在の状態を表示" -ForegroundColor Gray
Write-Host "    vibekanban-new <name> [S|M|L|XL]  新規チケット作成" -ForegroundColor Gray
Write-Host "    vibekanban-verify [-Full]  Fast/Full Verify実行" -ForegroundColor Gray
Write-Host "    vibekanban-done <name>     チケットを完了" -ForegroundColor Gray
Write-Host ""
