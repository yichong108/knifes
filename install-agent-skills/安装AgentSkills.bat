@echo off
setlocal
where py >nul 2>&1 && (
  py -3 "%~dp0install_agent_skills.py" %*
) || (
  python "%~dp0install_agent_skills.py" %*
)
if errorlevel 1 pause
