# verify_repo.ps1 - Repository Verification Script
# Purpose: Verify SSOT integrity, link validity, and forbidden commands
# Required: PowerShell 7+

param(
    [Parameter()]
    [ValidateSet('Fast', 'Full')]
    [string]$Mode = 'Fast',

    [Parameter()]
    [switch]$Parallel = $false,

    [Parameter()]
    [switch]$Verbose = $false
)

# Initialize
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$DocsPath = Join-Path $RepoRoot 'docs'
$SourcesPath = Join-Path $RepoRoot 'sources'
$EvidencePath = Join-Path $RepoRoot 'evidence' 'verify_reports'
$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$AllPassed = $true

# Ensure evidence directory exists
if (-not (Test-Path $EvidencePath)) {
    New-Item -ItemType Directory -Path $EvidencePath -Force | Out-Null
}

# Logging function
function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $color = switch ($Level) {
        'ERROR' { 'Red' }
        'WARN' { 'Yellow' }
        'PASS' { 'Green' }
        default { 'White' }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

# V-0001: Link integrity check
function Test-Links {
    Write-Log "Running V-0001: Link integrity check" -Level 'INFO'

    $reportPath = Join-Path $EvidencePath "${Timestamp}_link_check.md"
    $brokenLinks = @()

    # Get all markdown files in docs/
    $mdFiles = Get-ChildItem -Path $DocsPath -Filter '*.md' -Recurse

    foreach ($file in $mdFiles) {
        $content = Get-Content $file.FullName -Raw

        # Match markdown links: [text](path)
        $linkPattern = '\[([^\]]+)\]\(([^\)]+)\)'
        $matches = [regex]::Matches($content, $linkPattern)

        foreach ($match in $matches) {
            $linkText = $match.Groups[1].Value
            $linkPath = $match.Groups[2].Value

            # Skip external links (http/https)
            if ($linkPath -match '^https?://') {
                continue
            }

            # Skip anchors only (#section)
            if ($linkPath -match '^#') {
                continue
            }

            # Remove anchor from path
            $cleanPath = $linkPath -replace '#.*$', ''

            # Resolve relative path
            $basePath = Split-Path $file.FullName -Parent
            $targetPath = Join-Path $basePath $cleanPath
            $targetPath = [System.IO.Path]::GetFullPath($targetPath)

            if (-not (Test-Path $targetPath)) {
                $brokenLinks += [PSCustomObject]@{
                    File = $file.FullName.Replace($RepoRoot, '')
                    LinkText = $linkText
                    LinkPath = $linkPath
                    ResolvedPath = $targetPath.Replace($RepoRoot, '')
                }
            }
        }
    }

    # Generate report
    $report = @"
# V-0001: Link Integrity Check Report

**Timestamp**: $Timestamp
**Mode**: $Mode
**Status**: $(if ($brokenLinks.Count -eq 0) { 'PASS' } else { 'FAIL' })

## Summary
- Total broken links: $($brokenLinks.Count)

## Broken Links
$( if ($brokenLinks.Count -eq 0) {
    "No broken links found."
} else {
    $brokenLinks | ForEach-Object {
        "### $($_.File)`n- Link text: ``$($_.LinkText)```n- Link path: ``$($_.LinkPath)```n- Resolved path: ``$($_.ResolvedPath)```n"
    }
})

## Execution
- Command: ``pwsh checks/verify_repo.ps1 -Mode $Mode``
- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

    $report | Out-File -FilePath $reportPath -Encoding utf8

    if ($brokenLinks.Count -gt 0) {
        Write-Log "FAIL: Found $($brokenLinks.Count) broken links" -Level 'ERROR'
        $script:AllPassed = $false
        return $false
    } else {
        Write-Log "PASS: No broken links found" -Level 'PASS'
        return $true
    }
}

# V-0002: Part existence check
function Test-PartsExist {
    Write-Log "Running V-0002: Part existence check" -Level 'INFO'

    $reportPath = Join-Path $EvidencePath "${Timestamp}_parts_check.md"
    $missingParts = @()

    for ($i = 0; $i -le 20; $i++) {
        $partNum = $i.ToString('00')
        $partPath = Join-Path $DocsPath "Part${partNum}.md"

        if (-not (Test-Path $partPath)) {
            $missingParts += "Part${partNum}.md"
        }
    }

    # Generate report
    $report = @"
# V-0002: Part Existence Check Report

**Timestamp**: $Timestamp
**Mode**: $Mode
**Status**: $(if ($missingParts.Count -eq 0) { 'PASS' } else { 'FAIL' })

## Summary
- Expected parts: 21 (Part00 - Part20)
- Missing parts: $($missingParts.Count)

## Missing Parts
$( if ($missingParts.Count -eq 0) {
    "All parts exist."
} else {
    $missingParts | ForEach-Object { "- $_" }
})

## Execution
- Command: ``pwsh checks/verify_repo.ps1 -Mode $Mode``
- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

    $report | Out-File -FilePath $reportPath -Encoding utf8

    if ($missingParts.Count -gt 0) {
        Write-Log "FAIL: Missing $($missingParts.Count) parts" -Level 'ERROR'
        $script:AllPassed = $false
        return $false
    } else {
        Write-Log "PASS: All parts exist" -Level 'PASS'
        return $true
    }
}

# V-0003 & V-0901: Forbidden commands check
function Test-ForbiddenCommands {
    Write-Log "Running V-0003/V-0901: Forbidden commands check" -Level 'INFO'

    $reportPath = Join-Path $EvidencePath "${Timestamp}_forbidden_check.md"
    $detections = @()

    # Define forbidden commands (from Part09 R-0902)
    $forbiddenPatterns = @(
        'rm\s+-rf',
        'rmdir\s+/s\s+/q',
        'del\s+/s\s+/q',
        'git\s+push\s+--force',
        'git\s+push\s+-f\b',
        'git\s+reset\s+--hard',
        'git\s+clean\s+-fdx',
        'curl.*\|\s*sh',
        'wget.*\|\s*sh',
        'eval\s*\$\(',
        'bash\s*<\(',
        'chmod\s+777',
        'sudo\s+',
        'pip\s+install\s+-g',
        'npm\s+install\s+-g',
        'apt\s+install'
    )

    # Check docs/ and checks/
    $filesToCheck = @()
    $filesToCheck += Get-ChildItem -Path $DocsPath -Filter '*.md' -Recurse
    $filesToCheck += Get-ChildItem -Path (Split-Path $PSScriptRoot -Parent | Join-Path -ChildPath 'checks') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue

    foreach ($file in $filesToCheck) {
        $lineNum = 0
        foreach ($line in Get-Content $file.FullName) {
            $lineNum++

            foreach ($pattern in $forbiddenPatterns) {
                if ($line -match $pattern) {
                    $detections += [PSCustomObject]@{
                        File = $file.FullName.Replace($RepoRoot, '')
                        Line = $lineNum
                        Content = $line.Trim()
                        Pattern = $pattern
                    }
                }
            }
        }
    }

    # Generate report
    $report = @"
# V-0003/V-0901: Forbidden Commands Check Report

**Timestamp**: $Timestamp
**Mode**: $Mode
**Status**: $(if ($detections.Count -eq 0) { 'PASS' } else { 'FAIL' })

## Summary
- Forbidden commands detected: $($detections.Count)

## Detections
$( if ($detections.Count -eq 0) {
    "No forbidden commands found."
} else {
    $detections | ForEach-Object {
        "### $($_.File):$($_.Line)`n- Pattern: ``$($_.Pattern)```n- Content: ``$($_.Content)```n"
    }
})

## Forbidden Patterns Checked
$( $forbiddenPatterns | ForEach-Object { "- ``$_``" } )

## Execution
- Command: ``pwsh checks/verify_repo.ps1 -Mode $Mode``
- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

    $report | Out-File -FilePath $reportPath -Encoding utf8

    if ($detections.Count -gt 0) {
        Write-Log "FAIL: Found $($detections.Count) forbidden commands" -Level 'ERROR'
        $script:AllPassed = $false
        return $false
    } else {
        Write-Log "PASS: No forbidden commands found" -Level 'PASS'
        return $true
    }
}

# V-0004 & V-0902: Sources integrity check
function Test-SourcesIntegrity {
    Write-Log "Running V-0004/V-0902: Sources integrity check" -Level 'INFO'

    $reportPath = Join-Path $EvidencePath "${Timestamp}_sources_integrity.md"
    $modifications = @()

    # Check if git is available
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Log "WARN: Git not available, skipping sources integrity check" -Level 'WARN'
        return $true
    }

    # Check for modifications in sources/ (existing files only)
    try {
        # Get the last commit
        $lastCommit = git log -1 --format='%H' 2>$null

        if ($lastCommit) {
            # Check diff between HEAD~1 and HEAD for sources/
            $diffOutput = git diff --name-status HEAD~1 HEAD -- sources/ 2>$null

            if ($diffOutput) {
                foreach ($line in $diffOutput -split "`n") {
                    if ($line -match '^M\s+(.+)$') {
                        $modifications += $Matches[1]
                    }
                }
            }
        }
    } catch {
        Write-Log "WARN: Could not check git history: $_" -Level 'WARN'
    }

    # Generate report
    $report = @"
# V-0004/V-0902: Sources Integrity Check Report

**Timestamp**: $Timestamp
**Mode**: $Mode
**Status**: $(if ($modifications.Count -eq 0) { 'PASS' } else { 'FAIL' })

## Summary
- Modified files in sources/: $($modifications.Count)

## Modified Files
$( if ($modifications.Count -eq 0) {
    "No modifications in sources/ (additions are OK)."
} else {
    $modifications | ForEach-Object { "- $_" }
})

## Rule
- sources/ files must not be modified (append-only)
- See: Part00 R-0003, Part09 R-0903

## Execution
- Command: ``pwsh checks/verify_repo.ps1 -Mode $Mode``
- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

    $report | Out-File -FilePath $reportPath -Encoding utf8

    if ($modifications.Count -gt 0) {
        Write-Log "FAIL: Found $($modifications.Count) modified files in sources/" -Level 'ERROR'
        $script:AllPassed = $false
        return $false
    } else {
        Write-Log "PASS: No modifications in sources/" -Level 'PASS'
        return $true
    }
}

# Main execution
Write-Log "=== Repository Verification Started ===" -Level 'INFO'
Write-Log "Mode: $Mode" -Level 'INFO'
Write-Log "Repository: $RepoRoot" -Level 'INFO'
Write-Log "" -Level 'INFO'

# Run checks based on mode
$checks = @()

if ($Mode -eq 'Fast') {
    $checks = @(
        @{ Name = 'V-0001: Link Integrity'; Function = ${function:Test-Links} }
        @{ Name = 'V-0002: Part Existence'; Function = ${function:Test-PartsExist} }
        @{ Name = 'V-0003/V-0901: Forbidden Commands'; Function = ${function:Test-ForbiddenCommands} }
        @{ Name = 'V-0004/V-0902: Sources Integrity'; Function = ${function:Test-SourcesIntegrity} }
    )
} elseif ($Mode -eq 'Full') {
    $checks = @(
        @{ Name = 'V-0001: Link Integrity'; Function = ${function:Test-Links} }
        @{ Name = 'V-0002: Part Existence'; Function = ${function:Test-PartsExist} }
        @{ Name = 'V-0003/V-0901: Forbidden Commands'; Function = ${function:Test-ForbiddenCommands} }
        @{ Name = 'V-0004/V-0902: Sources Integrity'; Function = ${function:Test-SourcesIntegrity} }
        # Full mode would add more checks here (integration, security, etc.)
    )
}

# Execute checks
foreach ($check in $checks) {
    Write-Log "--- $($check.Name) ---" -Level 'INFO'
    & $check.Function
    Write-Log "" -Level 'INFO'
}

# Summary
Write-Log "=== Verification Complete ===" -Level 'INFO'
Write-Log "Evidence saved to: $EvidencePath" -Level 'INFO'

if ($AllPassed) {
    Write-Log "Overall Status: PASS" -Level 'PASS'
    exit 0
} else {
    Write-Log "Overall Status: FAIL" -Level 'ERROR'
    Write-Log "Please fix the issues above and re-run verification" -Level 'ERROR'
    exit 1
}
