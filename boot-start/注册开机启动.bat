@echo off
setlocal
where py >nul 2>&1 && (
  py -3 "%~dp0register_startup.py" %*
) || (
  python "%~dp0register_startup.py" %*
)
if errorlevel 1 pause
