@echo off
setlocal
chcp 65001 >nul
npm config set registry https://registry.npmmirror.com
if errorlevel 1 goto :fail
echo [OK] 已切换到国内镜像源（npmmirror）
echo 当前镜像源：
npm config get registry
echo.
pause
exit /b 0

:fail
echo [失败] 设置镜像源失败，请检查 npm 是否已安装。
pause
exit /b 1
