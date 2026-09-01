@echo off
chcp 65001 >nul
echo ============================================
echo    请用以下方式手动连接部署
echo ============================================
echo.
echo 方式1: Windows PowerShell 或 CMD 直接执行
echo ----------------------------------------
echo ssh root@113.45.64.145
echo (输入密码后连接成功，再粘贴下面的部署脚本)
echo.
echo 方式2: 使用此文件中的命令逐步执行
echo ----------------------------------------
echo.
echo === 完整部署脚本 (复制粘贴到服务器SSH中执行) ===
echo.
echo goto :script
echo.
exit /b
:script
