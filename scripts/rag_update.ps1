#!/usr/bin/env pwsh
<#!
.SYNOPSIS
    Template for incremental RAG updates.

.DESCRIPTION
    Compares a baseline index with a candidate update, evaluates changes,
    and prepares rollback steps. This is a template.

.PARAMETER BaselineDir
    Existing RAG index directory.

.PARAMETER CandidateDir
    Candidate RAG index directory built from new inputs.

.PARAMETER OutputDir
    Directory for diff reports and evaluation artifacts.

.PARAMETER DryRun
    Show planned actions without writing outputs.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$BaselineDir,

    [Parameter(Mandatory=$true)]
    [string]$CandidateDir,

    [Parameter(Mandatory=$true)]
    [string]$OutputDir,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "[RAG] Update template" -ForegroundColor Cyan
Write-Host "Baseline : $BaselineDir"
Write-Host "Candidate: $CandidateDir"
Write-Host "Output   : $OutputDir"
Write-Host "DryRun   : $DryRun"

if (-not (Test-Path $BaselineDir)) { throw "BaselineDir not found: $BaselineDir" }
if (-not (Test-Path $CandidateDir)) { throw "CandidateDir not found: $CandidateDir" }

$BaselineFiles = Get-ChildItem -Path $BaselineDir -File -Recurse
$CandidateFiles = Get-ChildItem -Path $CandidateDir -File -Recurse

$BaselineRel = $BaselineFiles | ForEach-Object { $_.FullName.Substring($BaselineDir.Length).TrimStart('\\') }
$CandidateRel = $CandidateFiles | ForEach-Object { $_.FullName.Substring($CandidateDir.Length).TrimStart('\\') }

$Diff = Compare-Object -ReferenceObject $BaselineRel -DifferenceObject $CandidateRel

Write-Host "Baseline files : $($BaselineFiles.Count)"
Write-Host "Candidate files: $($CandidateFiles.Count)"
Write-Host "Diff entries   : $($Diff.Count)"

if ($DryRun) {
    Write-Host "[DRY-RUN] No files written"
    Write-Host "[PLAN] Write diff report to OutputDir"
    Write-Host "[PLAN] Run evaluation checks"
    Write-Host "[PLAN] Prepare rollback plan"
    exit 0
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$DiffReportPath = Join-Path $OutputDir "rag_update_diff.txt"
$Diff | Out-File -FilePath $DiffReportPath -Encoding utf8
Write-Host "Wrote diff report: $DiffReportPath"

Write-Host "[TODO] Run evaluation of retrieval quality"
Write-Host "[TODO] Record rollback steps and backup locations"
