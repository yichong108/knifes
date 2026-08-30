@echo off
cd /d "%~dp0"
where py >nul 2>&1 && (
  py -3 "%~dp0start_work_apps.py"
) || (
  python "%~dp0start_work_apps.py"
)
if errorlevel 1 pause
