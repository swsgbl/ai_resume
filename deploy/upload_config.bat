@echo off
echo Uploading supervisor config to server...
scp D:\ai_resume\deploy\supervisor.conf root@113.45.64.145:/etc/supervisor/conf.d/ai-resume-backend.conf
echo.
echo Starting backend service...
ssh root@113.45.64.145 "supervisorctl reread && supervisorctl update && supervisorctl start ai-resume-backend && supervisorctl status ai-resume-backend"
echo.
pause
