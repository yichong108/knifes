@echo off
setlocal
chcp 65001 >nul
npm config set registry https://registry.npmjs.org
if errorlevel 1 goto :fail
echo [OK] 已还原为原始镜像源（npmjs.org）
echo 当前镜像源：
npm config get registry
echo.
pause
exit /b 0

:fail
echo [失败] 还原镜像源失败，请检查 npm 是否已安装。
pause
exit /b 1
