<#
.SYNOPSIS
  Mirrors the addon into the WoW AddOns folder and keeps it in sync while files change.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts/watch.ps1
  powershell -ExecutionPolicy Bypass -File scripts/watch.ps1 -AddOnsPath "D:\Games\World of Warcraft\_forever_\Interface\AddOns"
#>
param(
  [string]$AddOnsPath = "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns"
)

$ErrorActionPreference = "Stop"

$AddonName = "ProfessionRecipeProfit"
$Source = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Destination = Join-Path $AddOnsPath $AddonName

# Dev-only paths that never get deployed (dot-files/dirs are excluded as well).
$ExcludedDirs = @("scripts")
$ExcludedFiles = @("pkgmeta.yaml")

if (-not (Test-Path $AddOnsPath)) {
  throw "AddOns folder not found: $AddOnsPath"
}

function Test-Excluded([string]$fullPath) {
  $relative = $fullPath.Substring($Source.Length).TrimStart("\", "/")
  foreach ($segment in $relative -split "[\\/]") {
    if ($segment.StartsWith(".")) { return $true }
  }
  $first = ($relative -split "[\\/]")[0]
  return ($ExcludedDirs -contains $first) -or ($ExcludedFiles -contains $relative)
}

function Sync-Addon {
  $robocopyArgs = @($Source, $Destination, "/MIR", "/XD", ".*") + $ExcludedDirs + @("/XF", ".*") + $ExcludedFiles + @("/NJH", "/NJS", "/NP", "/NDL")
  $output = & robocopy @robocopyArgs
  # Robocopy exit codes below 8 mean success.
  if ($LASTEXITCODE -ge 8) {
    Write-Host ($output -join "`n")
    Write-Host "[$(Get-Date -Format HH:mm:ss)] sync failed (robocopy exit $LASTEXITCODE)" -ForegroundColor Red
    return
  }
  $changed = @($output | Where-Object { $_.Trim() }) | ForEach-Object { $_.Trim() -replace "\s+", " " }
  Write-Host "[$(Get-Date -Format HH:mm:ss)] synced to $Destination" -ForegroundColor Green
  foreach ($line in $changed) { Write-Host "  $line" }
}

Sync-Addon

$watcher = New-Object System.IO.FileSystemWatcher $Source
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]"FileName, DirectoryName, LastWrite, Size"
$events = "Changed", "Created", "Deleted", "Renamed"
foreach ($name in $events) {
  Register-ObjectEvent -InputObject $watcher -EventName $name -SourceIdentifier "PRPWatch.$name" | Out-Null
}
$watcher.EnableRaisingEvents = $true

Write-Host "Watching $Source (Ctrl+C to stop). /reload in game after a sync; new files or .toc edits need a client restart."

try {
  while ($true) {
    if (-not (Wait-Event -Timeout 1)) { continue }
    # Debounce: editors fire several events per save.
    Start-Sleep -Milliseconds 300
    $pending = @(Get-Event | Where-Object { $_.SourceIdentifier -like "PRPWatch.*" })
    $relevant = $pending | Where-Object { -not (Test-Excluded $_.SourceEventArgs.FullPath) }
    $pending | ForEach-Object { Remove-Event -EventIdentifier $_.EventIdentifier }
    if ($relevant) { Sync-Addon }
  }
}
finally {
  foreach ($name in $events) { Unregister-Event -SourceIdentifier "PRPWatch.$name" -ErrorAction SilentlyContinue }
  $watcher.Dispose()
}
