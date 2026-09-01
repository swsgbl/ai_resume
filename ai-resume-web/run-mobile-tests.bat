@echo off
REM AI简历移动端E2E自动化测试脚本
REM 模拟多种手机设备执行测试

setlocal

set PATH=C:\Program Files\nodejs;%PATH%
set NODE_ENV=test

cd /d D:\ai_resume\ai-resume-web

echo ====================================
echo AI简历移动端E2E自动化测试
echo ====================================
echo.

echo [1/4] 检查依赖...
call node --version
if errorlevel 1 (
    echo 错误: Node.js 未找到
    exit /b 1
)

echo.
echo [2/4] 启动开发服务器...
start /B node node_modules\vite\bin\vite.js > server.log 2>&1

echo 等待服务器启动...
timeout /t 8 /nobreak > nul

echo.
echo [3/4] 运行 iPhone 12 Pro 移动端测试...
call node node_modules\playwright\cli.js test mobile-full-flow.spec.ts --project=mobile-iphone --reporter=list

echo.
echo [4/4] 运行 Pixel 5 移动端测试...
call node node_modules\playwright\cli.js test mobile-full-flow.spec.ts --project=mobile-android --reporter=list

echo.
echo ====================================
echo 测试完成
echo ====================================

REM 关闭开发服务器
taskkill /F /IM node.exe > nul 2>&1

endlocal
