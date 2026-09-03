@echo off
setlocal
where py >nul 2>&1 && (
  py -3 "%~dp0proxy_manager.py" enable %*
) || (
  python "%~dp0proxy_manager.py" enable %*
)
if errorlevel 1 pause
