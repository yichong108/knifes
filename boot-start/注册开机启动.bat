@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0register-startup.ps1" %*
if errorlevel 1 pause
