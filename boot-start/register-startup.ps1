# Sync knifes tools into Windows Startup folder via shortcuts
param(
  [string]$ConfigPath,
  [switch]$Status,
  [switch]$Remove
)

$ErrorActionPreference = 'Continue'
$ManagedPrefix = 'knifes-'

function Get-StartupFolder {
  $folder = [Environment]::GetFolderPath('Startup')
  if ([string]::IsNullOrWhiteSpace($folder)) {
    throw 'cannot resolve Windows Startup folder'
  }
  return $folder
}

function Get-ManagedShortcutName {
  param([Parameter(Mandatory)][string]$ToolPath)
  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($ToolPath)
  return "$ManagedPrefix$baseName.lnk"
}

function Get-ManagedShortcutPath {
  param([Parameter(Mandatory)][string]$ToolPath)
  $startupFolder = Get-StartupFolder
  $shortcutName = Get-ManagedShortcutName -ToolPath $ToolPath
  return Join-Path $startupFolder $shortcutName
}

function Get-ShortcutTargetPath {
  param([Parameter(Mandatory)][string]$ShortcutPath)

  if (-not (Test-Path -LiteralPath $ShortcutPath)) {
    return $null
  }

  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($ShortcutPath)
  return $shortcut.TargetPath
}

function Get-ManagedShortcuts {
  $startupFolder = Get-StartupFolder
  if (-not (Test-Path -LiteralPath $startupFolder)) {
    return @()
  }

  return Get-ChildItem -LiteralPath $startupFolder -Filter "$ManagedPrefix*.lnk" -File -ErrorAction SilentlyContinue
}

function New-ToolShortcut {
  param(
    [Parameter(Mandatory)][string]$ToolPath,
    [Parameter(Mandatory)][string]$ShortcutPath
  )

  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($ShortcutPath)
  $shortcut.TargetPath = $ToolPath
  $shortcut.WorkingDirectory = Split-Path -Parent $ToolPath
  $shortcut.Save()
}

function Read-StartupConfig {
  param([Parameter(Mandatory)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "config not found: $Path"
  }

  $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  $config = $raw | ConvertFrom-Json

  if (-not $config.tools) {
    return @()
  }

  $paths = @()
  foreach ($item in @($config.tools)) {
    if ([string]::IsNullOrWhiteSpace($item)) { continue }
    $paths += $item.Trim()
  }
  return $paths
}

function Sync-StartupTools {
  param([Parameter(Mandatory)][string[]]$ToolPaths)

  $stats = @{ ok = 0; skip = 0; fail = 0 }
  $expectedShortcuts = @{}

  Write-Host '=== Sync startup tools ==='
  Write-Host "Startup folder: $(Get-StartupFolder)"
  Write-Host ''

  foreach ($toolPath in $ToolPaths) {
    $resolved = $null
    try {
      $resolved = (Resolve-Path -LiteralPath $toolPath -ErrorAction Stop).Path
    } catch {
      Write-Host "[FAIL] path not found: $toolPath"
      $stats.fail++
      continue
    }

    $shortcutPath = Get-ManagedShortcutPath -ToolPath $resolved
    $expectedShortcuts[$shortcutPath] = $true
    $displayName = [System.IO.Path]::GetFileName($resolved)

    if (Test-Path -LiteralPath $shortcutPath) {
      $currentTarget = Get-ShortcutTargetPath -ShortcutPath $shortcutPath
      if ($currentTarget -and ($currentTarget -eq $resolved)) {
        Write-Host "[SKIP] $displayName"
        $stats.skip++
        continue
      }
    }

    try {
      New-ToolShortcut -ToolPath $resolved -ShortcutPath $shortcutPath
      Write-Host "[OK] $displayName -> $shortcutPath"
      $stats.ok++
    } catch {
      Write-Host "[FAIL] $displayName $($_.Exception.Message)"
      $stats.fail++
    }
  }

  foreach ($shortcut in Get-ManagedShortcuts) {
    if ($expectedShortcuts.ContainsKey($shortcut.FullName)) { continue }
    try {
      Remove-Item -LiteralPath $shortcut.FullName -Force
      Write-Host "[OK] removed orphan shortcut: $($shortcut.Name)"
      $stats.ok++
    } catch {
      Write-Host "[FAIL] remove $($shortcut.Name) $($_.Exception.Message)"
      $stats.fail++
    }
  }

  Write-Host ''
  Write-Host "Done. updated=$($stats.ok) skipped=$($stats.skip) failed=$($stats.fail)"
  if ($stats.fail -gt 0) { exit 1 }
}

function Show-StartupStatus {
  param([Parameter(Mandatory)][string[]]$ToolPaths)

  Write-Host '=== Startup status ==='
  Write-Host "Startup folder: $(Get-StartupFolder)"
  Write-Host ''

  Write-Host 'Configured tools:'
  if (-not $ToolPaths -or $ToolPaths.Count -eq 0) {
    Write-Host '  (none)'
  } else {
    foreach ($toolPath in $ToolPaths) {
      $resolved = $null
      $exists = $false
      try {
        $resolved = (Resolve-Path -LiteralPath $toolPath -ErrorAction Stop).Path
        $exists = $true
      } catch {
        $resolved = $toolPath
      }

      $shortcutPath = Get-ManagedShortcutPath -ToolPath $resolved
      $registered = $false
      $targetOk = $false

      if (Test-Path -LiteralPath $shortcutPath) {
        $registered = $true
        $currentTarget = Get-ShortcutTargetPath -ShortcutPath $shortcutPath
        if ($exists -and $currentTarget -eq $resolved) {
          $targetOk = $true
        }
      }

      $pathState = if ($exists) { 'exists' } else { 'missing' }
      $regState = if ($targetOk) { 'registered' } elseif ($registered) { 'mismatch' } else { 'not registered' }
      Write-Host "  - $resolved"
      Write-Host "    path: $pathState | startup: $regState"
    }
  }

  Write-Host ''
  Write-Host 'Managed shortcuts in Startup folder:'
  $managed = Get-ManagedShortcuts
  if (-not $managed -or $managed.Count -eq 0) {
    Write-Host '  (none)'
    return
  }

  $configuredResolved = @{}
  foreach ($toolPath in $ToolPaths) {
    try {
      $resolved = (Resolve-Path -LiteralPath $toolPath -ErrorAction Stop).Path
      $configuredResolved[$resolved] = $true
    } catch {
      continue
    }
  }

  foreach ($shortcut in $managed) {
    $target = Get-ShortcutTargetPath -ShortcutPath $shortcut.FullName
    $orphan = -not ($target -and $configuredResolved.ContainsKey($target))
    $tag = if ($orphan) { 'orphan' } else { 'ok' }
    Write-Host "  - $($shortcut.Name) -> $target ($tag)"
  }
}

function Remove-StartupTools {
  $stats = @{ ok = 0; fail = 0 }

  Write-Host '=== Remove startup tools ==='
  Write-Host "Startup folder: $(Get-StartupFolder)"
  Write-Host ''

  $managed = Get-ManagedShortcuts
  if (-not $managed -or $managed.Count -eq 0) {
    Write-Host 'No managed shortcuts found.'
    return
  }

  foreach ($shortcut in $managed) {
    try {
      Remove-Item -LiteralPath $shortcut.FullName -Force
      Write-Host "[OK] removed $($shortcut.Name)"
      $stats.ok++
    } catch {
      Write-Host "[FAIL] remove $($shortcut.Name) $($_.Exception.Message)"
      $stats.fail++
    }
  }

  Write-Host ''
  Write-Host "Done. removed=$($stats.ok) failed=$($stats.fail)"
  if ($stats.fail -gt 0) { exit 1 }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
  $ConfigPath = Join-Path $scriptDir 'startup-tools.json'
} else {
  $ConfigPath = (Resolve-Path -LiteralPath $ConfigPath).Path
}

if ($Remove) {
  Remove-StartupTools
  exit 0
}

try {
  $toolPaths = Read-StartupConfig -Path $ConfigPath
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)"
  exit 1
}

if ($Status) {
  Show-StartupStatus -ToolPaths $toolPaths
  exit 0
}

Sync-StartupTools -ToolPaths $toolPaths
