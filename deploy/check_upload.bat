@echo off
echo Checking backend directory...
ssh root@113.45.64.145 "ls -la /var/www/ai-resume/ 2>/dev/null || echo 'Directory not found'"
echo.
echo If backend directory is missing or incomplete, we need to re-upload.
pause
