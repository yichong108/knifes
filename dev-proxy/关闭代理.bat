@echo off
setlocal
where py >nul 2>&1 && (
  py -3 "%~dp0proxy_manager.py" disable %*
) || (
  python "%~dp0proxy_manager.py" disable %*
)
if errorlevel 1 pause
