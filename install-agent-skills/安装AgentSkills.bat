@echo off
setlocal
if "%~1"=="" (
  set "TARGET=%CD%"
  where py >nul 2>&1 && (
    py -3 "%~dp0install_agent_skills.py" --project-root "%TARGET%"
  ) || (
    python "%~dp0install_agent_skills.py" --project-root "%TARGET%"
  )
) else (
  set "TARGET=%~1"
  shift
  where py >nul 2>&1 && (
    py -3 "%~dp0install_agent_skills.py" --project-root "%TARGET%" %*
  ) || (
    python "%~dp0install_agent_skills.py" --project-root "%TARGET%" %*
  )
)
if errorlevel 1 pause
