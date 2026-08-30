@echo off
setlocal
if "%~1"=="" (
  set "TARGET=%CD%"
) else (
  set "TARGET=%~1"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-agent-skills.ps1" -ProjectRoot "%TARGET%" %2 %3 %4 %5 %6 %7 %8 %9
if errorlevel 1 pause
