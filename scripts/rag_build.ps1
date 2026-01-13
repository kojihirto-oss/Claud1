#!/usr/bin/env pwsh
<#!
.SYNOPSIS
    Template for initial RAG build.

.DESCRIPTION
    Builds a new RAG index from an input folder into an output folder.
    This is a template. Replace the placeholder steps with your pipeline.

.PARAMETER InputDir
    Source directory for documents.

.PARAMETER OutputDir
    Destination directory for the RAG index.

.PARAMETER DryRun
    Show planned actions without writing outputs.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$InputDir,

    [Parameter(Mandatory=$true)]
    [string]$OutputDir,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "[RAG] Build template" -ForegroundColor Cyan
Write-Host "Input : $InputDir"
Write-Host "Output: $OutputDir"
Write-Host "DryRun: $DryRun"

if (-not (Test-Path $InputDir)) {
    throw "InputDir not found: $InputDir"
}

$InputFiles = Get-ChildItem -Path $InputDir -File -Recurse
Write-Host "Input files: $($InputFiles.Count)"

if (-not (Test-Path $OutputDir)) {
    if ($DryRun) {
        Write-Host "[DRY-RUN] Create output directory: $OutputDir"
    } else {
        New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
        Write-Host "Created output directory"
    }
}

Write-Host "[PLAN] Build embeddings and index from input files"
Write-Host "[PLAN] Write index artifacts under OutputDir"

if ($DryRun) {
    Write-Host "[DRY-RUN] No files written"
    exit 0
}

$Manifest = [ordered]@{
    generated_at = (Get-Date -Format "s")
    input_dir = $InputDir
    output_dir = $OutputDir
    file_count = $InputFiles.Count
}

$ManifestPath = Join-Path $OutputDir "rag_manifest.json"
$Manifest | ConvertTo-Json -Depth 3 | Out-File -FilePath $ManifestPath -Encoding utf8
Write-Host "Wrote manifest: $ManifestPath"
