#!/usr/bin/env pwsh
<#!
.SYNOPSIS
    Template for MCP healthcheck.

.DESCRIPTION
    Checks local MCP configuration and summarizes server entries.
    This is a template. Add active health checks as needed.

.PARAMETER ConfigPath
    Path to MCP config JSON file.

.PARAMETER DryRun
    Print checks only.
#>

param(
    [string]$ConfigPath = ".mcp.json",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "[MCP] Healthcheck template" -ForegroundColor Cyan
Write-Host "ConfigPath: $ConfigPath"
Write-Host "DryRun    : $DryRun"

if (-not (Test-Path $ConfigPath)) {
    Write-Host "[WARN] MCP config not found: $ConfigPath" -ForegroundColor Yellow
    exit 1
}

$ConfigRaw = Get-Content -Path $ConfigPath -Raw
$Config = $ConfigRaw | ConvertFrom-Json

if ($null -ne $Config.servers) {
    Write-Host "Servers:" -ForegroundColor Cyan
    foreach ($Server in $Config.servers.PSObject.Properties) {
        Write-Host "- $($Server.Name)"
    }
} else {
    Write-Host "[WARN] No servers listed in config" -ForegroundColor Yellow
}

Write-Host "[PLAN] Optional checks to add:" -ForegroundColor Cyan
Write-Host "- Resolve server command paths"
Write-Host "- Verify environment variables"
Write-Host "- Run a lightweight ping or list call"

if ($DryRun) {
    Write-Host "[DRY-RUN] No actions executed"
    exit 0
}

Write-Host "[INFO] Template complete. Add active checks as needed."
