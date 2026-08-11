# Daily work apps launcher: Clash first, then others
$ErrorActionPreference = 'Continue'

function Start-AppIfNeeded {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$ProcessName
  )
  if ([string]::IsNullOrWhiteSpace($Path)) {
    Write-Host "[FAIL] $Name path empty"
    return
  }
  if (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
    Write-Host "[SKIP] $Name already running"
    return
  }
  if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "[FAIL] $Name not found: $Path"
    return
  }
  try {
    Start-Process -FilePath $Path -ErrorAction Stop
    Write-Host "[OK] $Name"
  } catch {
    Write-Host "[FAIL] $Name $($_.Exception.Message)"
  }
}

$yuqueExe = Get-ChildItem -LiteralPath 'D:\Program Files\Yuque\yuque-desktop' -Filter '*.exe' -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -notmatch 'uninstall|Update|crash|elevate' } |
  Select-Object -First 1

$yuquePath = if ($yuqueExe) { $yuqueExe.FullName } else { '' }
$yuqueProc = if ($yuqueExe) { [System.IO.Path]::GetFileNameWithoutExtension($yuqueExe.Name) } else { 'yuque' }

$cursorFromRegistry = Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue |
  ForEach-Object { Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue } |
  Where-Object { $_.DisplayName -match '^Cursor' -and $_.InstallLocation } |
  Select-Object -First 1 -ExpandProperty InstallLocation

$cursorCandidates = @(
  $(if ($cursorFromRegistry) { Join-Path $cursorFromRegistry 'Cursor.exe' } else { $null })
  'D:\Users\15357\AppData\Local\Programs\cursor\Cursor.exe'
  "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe"
) | Where-Object { $_ }

$cursorPath = $cursorCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $cursorPath) { $cursorPath = '' }

Write-Host '=== 1/2 Clash for Windows ==='
Start-AppIfNeeded -Name 'Clash for Windows' -Path 'D:\Program Files\Clash for Windows\Clash for Windows.exe' -ProcessName 'Clash for Windows'

Start-Sleep -Seconds 3

Write-Host '=== 2/2 Other apps ==='
Start-AppIfNeeded -Name 'Yuque' -Path $yuquePath -ProcessName $yuqueProc
Start-AppIfNeeded -Name 'Cursor' -Path $cursorPath -ProcessName 'Cursor'
Start-AppIfNeeded -Name 'Yuanbao' -Path 'D:\Program Files\Tencent\Yuanbao\yuanbao.exe' -ProcessName 'yuanbao'
Start-AppIfNeeded -Name 'Docker Desktop' -Path 'C:\Program Files\Docker\Docker\Docker Desktop.exe' -ProcessName 'Docker Desktop'
Start-AppIfNeeded -Name 'WebStorm' -Path 'D:\Program Files\JetBrains\WebStorm 2026.2.0.1\bin\webstorm64.exe' -ProcessName 'webstorm64'

Write-Host 'Done.'
Start-Sleep -Seconds 2