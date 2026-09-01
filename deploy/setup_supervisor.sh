#!/bin/bash
# Setup supervisor config for AI Resume Backend

rm -f /etc/supervisor/conf.d/ai-resume-backend.conf

cat > /etc/supervisor/conf.d/ai-resume-backend.conf << 'ENDCONFIG'
[program:ai-resume-backend]
command=/var/www/ai-resume/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1
directory=/var/www/ai-resume/backend
user=root
autostart=true
autorestart=true
stderr_logfile=/var/www/ai-resume/logs/backend-error.log
stdout_logfile=/var/www/ai-resume/logs/backend.log
environment=PYTHONPATH="/var/www/ai-resume/backend",USE_SQLITE="True"
ENDCONFIG

supervisorctl reread
supervisorctl update
supervisorctl start ai-resume-backend
supervisorctl status ai-resume-backend
