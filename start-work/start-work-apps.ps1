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

Write-Host '=== 1/2 Clash for Windows ==='
Start-AppIfNeeded -Name 'Clash for Windows' -Path 'D:\Program Files\Clash for Windows\Clash for Windows.exe' -ProcessName 'Clash for Windows'

Start-Sleep -Seconds 3

Write-Host '=== 2/2 Other apps ==='
Start-AppIfNeeded -Name 'Yuque' -Path $yuquePath -ProcessName $yuqueProc
Start-AppIfNeeded -Name 'Cursor' -Path "$env:LOCALAPPDATA\Programs\cursor\Cursor.exe" -ProcessName 'Cursor'
Start-AppIfNeeded -Name 'Yuanbao' -Path 'D:\Program Files\Tencent\Yuanbao\yuanbao.exe' -ProcessName 'yuanbao'
Start-AppIfNeeded -Name 'Docker Desktop' -Path 'C:\Program Files\Docker\Docker\Docker Desktop.exe' -ProcessName 'Docker Desktop'
Start-AppIfNeeded -Name 'Rebased' -Path 'D:\Program Files\detachhead\Rebased\bin\idea64.exe' -ProcessName 'idea64'

Write-Host 'Done.'
Start-Sleep -Seconds 2