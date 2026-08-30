# Install skills from yichong108/agent-skills into .agents/skills (skip if exists)
param(
  [string[]]$Skill,
  [string]$ProjectRoot = (Get-Location).Path,
  [switch]$List
)

$ErrorActionPreference = 'Stop'
$RepoUrl = 'https://github.com/yichong108/agent-skills.git'
$CatalogUrl = 'https://raw.githubusercontent.com/yichong108/agent-skills/main/catalog.yaml'
$ZipUrl = 'https://github.com/yichong108/agent-skills/archive/refs/heads/main.zip'

function Get-CatalogSkills {
  $content = (Invoke-WebRequest -Uri $CatalogUrl -UseBasicParsing).Content
  $skills = [System.Collections.Generic.List[hashtable]]::new()
  $current = $null
  foreach ($line in ($content -split "`n")) {
    if ($line -match '^\s*-\s*name:\s*(.+)$') {
      if ($null -ne $current) { $skills.Add($current) }
      $current = @{ Name = $matches[1].Trim(); Path = $null }
    } elseif ($null -ne $current -and $line -match '^\s*path:\s*(.+)$') {
      $current.Path = $matches[1].Trim()
    }
  }
  if ($null -ne $current) { $skills.Add($current) }
  return $skills
}

function Test-GitAvailable {
  return $null -ne (Get-Command git -ErrorAction SilentlyContinue)
}

function Invoke-Git {
  param([Parameter(Mandatory)][string[]]$Arguments)

  $prevEA = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    & git @Arguments 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "git $($Arguments -join ' ') failed (exit $LASTEXITCODE)"
    }
  } finally {
    $ErrorActionPreference = $prevEA
  }
}

function Get-SkillsSource {
  param([string[]]$SkillPaths)

  if (Test-GitAvailable) {
    $tempDir = Join-Path $env:TEMP ("agent-skills-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    try {
      Invoke-Git -Arguments @('clone', '--depth', '1', '--filter=blob:none', '--sparse', $RepoUrl, $tempDir)
      Push-Location $tempDir
      try {
        if ($SkillPaths -and $SkillPaths.Count -gt 0) {
          $sparseArgs = @('sparse-checkout', 'set') + $SkillPaths
          Invoke-Git -Arguments $sparseArgs
        } else {
          Invoke-Git -Arguments @('sparse-checkout', 'set', 'skills')
        }
      } finally {
        Pop-Location
      }
      return @{ Root = $tempDir; Cleanup = $true }
    } catch {
      if (Test-Path $tempDir) { Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
      throw
    }
  }

  $zipPath = Join-Path $env:TEMP ("agent-skills-" + [guid]::NewGuid().ToString('N') + '.zip')
  $extractDir = Join-Path $env:TEMP ("agent-skills-" + [guid]::NewGuid().ToString('N'))
  try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force
    $repoRoot = Get-ChildItem -LiteralPath $extractDir -Directory | Select-Object -First 1
    if (-not $repoRoot) { throw "failed to extract repository archive" }
    return @{ Root = $repoRoot.FullName; Cleanup = $true; ZipPath = $zipPath; ExtractDir = $extractDir }
  } catch {
    if (Test-Path $zipPath) { Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue }
    if (Test-Path $extractDir) { Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue }
    throw
  }
}

function Remove-SkillsSource {
  param($Source)
  if (-not $Source.Cleanup) { return }
  if ($Source.Root -and (Test-Path -LiteralPath $Source.Root)) {
    Remove-Item -LiteralPath $Source.Root -Recurse -Force -ErrorAction SilentlyContinue
  }
  if ($Source.ZipPath -and (Test-Path -LiteralPath $Source.ZipPath)) {
    Remove-Item -LiteralPath $Source.ZipPath -Force -ErrorAction SilentlyContinue
  }
  if ($Source.ExtractDir -and (Test-Path -LiteralPath $Source.ExtractDir)) {
    Remove-Item -LiteralPath $Source.ExtractDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Install-SkillCopy {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$SourceDir,
    [Parameter(Mandatory)][string]$TargetDir
  )

  $dest = Join-Path $TargetDir $Name
  if (Test-Path -LiteralPath $dest) {
    Write-Host "[SKIP] $Name already exists"
    return 'skip'
  }
  if (-not (Test-Path -LiteralPath $SourceDir)) {
    Write-Host "[FAIL] $Name source not found: $SourceDir"
    return 'fail'
  }
  try {
    Copy-Item -LiteralPath $SourceDir -Destination $dest -Recurse -Force
    Write-Host "[OK] $Name -> $dest"
    return 'ok'
  } catch {
    Write-Host "[FAIL] $Name $($_.Exception.Message)"
    return 'fail'
  }
}

$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$targetDir = Join-Path $projectRoot '.agents/skills'

try {
  $catalog = Get-CatalogSkills
} catch {
  Write-Host "[FAIL] cannot fetch catalog: $($_.Exception.Message)"
  exit 1
}

if ($List) {
  Write-Host "Available skills from yichong108/agent-skills:"
  foreach ($item in $catalog) {
  Write-Host "  - $($item.Name)"
  }
  Write-Host ""
  Write-Host "Target: $targetDir"
  exit 0
}

$toInstall = if ($Skill -and $Skill.Count -gt 0) {
  $requested = @{}
  foreach ($name in $Skill) { $requested[$name.Trim()] = $true }
  $catalog | Where-Object { $requested.ContainsKey($_.Name) }
} else {
  $catalog
}

if ($Skill -and $Skill.Count -gt 0) {
  $found = @($toInstall | ForEach-Object { $_.Name })
  foreach ($name in $Skill) {
    $trimmed = $name.Trim()
    if ($trimmed -and $found -notcontains $trimmed) {
      Write-Host "[FAIL] unknown skill: $trimmed (use -List to see available skills)"
    }
  }
}

if (-not $toInstall -or $toInstall.Count -eq 0) {
  Write-Host "No skills to install."
  exit 0
}

if (-not (Test-Path -LiteralPath $targetDir)) {
  New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$skillPaths = @($toInstall | ForEach-Object { $_.Path })
$source = $null
$stats = @{ ok = 0; skip = 0; fail = 0 }

Write-Host "=== Install agent-skills ==="
Write-Host "Project: $projectRoot"
Write-Host "Target:  $targetDir"
Write-Host ""

try {
  $source = Get-SkillsSource -SkillPaths $skillPaths
  foreach ($item in $toInstall) {
    $sourceDir = Join-Path $source.Root $item.Path
    $result = Install-SkillCopy -Name $item.Name -SourceDir $sourceDir -TargetDir $targetDir
    $stats[$result]++
  }
} catch {
  Write-Host "[FAIL] $($_.Exception.Message)"
  exit 1
} finally {
  if ($null -ne $source) { Remove-SkillsSource -Source $source }
}

Write-Host ""
Write-Host "Done. installed=$($stats.ok) skipped=$($stats.skip) failed=$($stats.fail)"

if ($stats.fail -gt 0) { exit 1 }
