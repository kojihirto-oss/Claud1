$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$outDir = Join-Path (Get-Location) "out"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outFile = Join-Path $outDir ("DESIGN_MASTER_FULL_" + $ts + "_UTF8.txt")

$files = @()
if (Test-Path ".\docs\00_INDEX.md") { $files += ".\docs\00_INDEX.md" }
if (Test-Path ".\docs\README.md")   { $files += ".\docs\README.md" }

$parts = Get-ChildItem ".\docs" -Filter "Part*.md" | Sort-Object {
  if ($_.BaseName -match '^Part(\d+)$') { [int]$Matches[1] } else { 9999 }
}
$files += $parts.FullName

$sb = New-Object System.Text.StringBuilder
foreach ($f in $files) {
  $name = Split-Path $f -Leaf
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("============================================================")
  [void]$sb.AppendLine("FILE: " + $name)
  [void]$sb.AppendLine("============================================================")
  [void]$sb.AppendLine("")
  $content = Get-Content -LiteralPath $f -Raw
  [void]$sb.AppendLine($content)
  [void]$sb.AppendLine("")
}

$sb.ToString() | Set-Content -LiteralPath $outFile -Encoding utf8
"OUT: $outFile"
"SHA256: " + (Get-FileHash -Algorithm SHA256 -LiteralPath $outFile).Hash
