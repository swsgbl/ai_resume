@echo off
chcp 65001 >nul
echo ============================================
echo    AI简历平台 - 一键部署到服务器
echo ============================================
echo.
echo 服务器: 113.45.64.145
echo 用户: root
echo.

set SERVER=113.45.64.145
set USER=root
set SSH_PATH=C:\Windows\System32\OpenSSH\ssh.exe
set SCP_PATH=C:\Windows\System32\OpenSSH\scp.exe

echo ============================================
echo [步骤 1/10] 测试服务器连接...
echo ============================================
echo.
echo 请输入服务器密码：
%SSH_PATH% -o StrictHostKeyChecking=no %USER%@%SERVER% "echo '连接成功！' && uname -a"
if %errorlevel% neq 0 (
    echo.
    echo 连接失败，请检查密码是否正确
    pause
    exit /b 1
)
echo.

echo ============================================
echo [步骤 2/10] 更新系统并安装基础工具...
echo ============================================
%SSH_PATH% %USER%@%SERVER% "apt update && apt upgrade -y"
%SSH_PATH% %USER%@%SERVER% "apt install -y curl wget git vim htop net-tools software-properties-common"
echo.

echo ============================================
echo [步骤 3/10] 安装 Python 3.11...
echo ============================================
%SSH_PATH% %USER%@%SERVER% "add-apt-repository -y ppa:deadsnakes/ppa || true"
%SSH_PATH% %USER%@%SERVER% "apt update && apt install -y python3.11 python3.11-venv python3.11-dev python3-pip"
echo.

echo ============================================
echo [步骤 4/10] 安装 Node.js 20...
echo ============================================
%SSH_PATH% %USER%@%SERVER% "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
%SSH_PATH% %USER%@%SERVER% "apt install -y nodejs"
echo.

echo ============================================
echo [步骤 5/10] 安装 Nginx 和 Supervisor...
echo ============================================
%SSH_PATH% %USER%@%SERVER% "apt install -y nginx supervisor"
echo.

echo ============================================
echo [步骤 6/10] 创建 2GB 交换空间...
echo ============================================
%SSH_PATH% %USER%@%SERVER% "if [ ! -f /swapfile ]; then fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && echo '/swapfile none swap sw 0 0' >> /etc/fstab; fi"
%SSH_PATH% %USER%@%SERVER% "free -h"
echo.

echo ============================================
echo [步骤 7/10] 创建应用目录...
echo ============================================
%SSH_PATH% %USER%@%SERVER% "mkdir -p /var/www/ai-resume/{backend,frontend,logs,uploads,exports}"
echo.

echo ============================================
echo [步骤 8/10] 上传项目代码...
echo ============================================
echo 正在打包后端代码...
cd /d D:\ai_resume
tar -czf ai-resume-backend.tar.gz -C "AI-\ai-resume-platform" backend 2>nul || powershell "Compress-Archive -Path 'AI-\ai-resume-platform\backend' -DestinationPath ai-resume-backend.zip"
echo 正在上传后端代码...
%SCP_PATH% -r "ai-resume-platform\backend" %USER%@%SERVER%:/var/www/ai-resume/ 2>nul || echo 后端代码已存在或需要手动上传

echo 正在上传前端代码...
%SCP_PATH% -r ai-resume-web %USER%@%SERVER%:/var/www/ai-resume/frontend 2>nul || powershell "Compress-Archive -Path ai-resume-web -DestinationPath frontend.zip"
echo.

echo ============================================
echo [步骤 9/10] 配置后端环境...
echo ============================================
%SSH_PATH% %USER%@%SERVER% "cd /var/www/ai-resume/backend && python3.11 -m venv venv && source venv/bin/activate && pip install --upgrade pip && pip install fastapi uvicorn sqlalchemy pydantic python-jose[cryptography] passlib[bcrypt] python-multipart email-validator"
echo.

echo ============================================
echo [步骤 10/10] 配置 Nginx 和 启动服务...
echo ============================================
%SSH_PATH% %USER%@%SERVER% "cat > /etc/supervisor/conf.d/ai-resume-backend.conf << 'EOF'
[program:ai-resume-backend]
command=/var/www/ai-resume/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1
directory=/var/www/ai-resume/backend
user=root
autostart=true
autorestart=true
stderr_logfile=/var/www/ai-resume/logs/backend-error.log
stdout_logfile=/var/www/ai-resume/logs/backend.log
environment=PYTHONPATH=\"/var/www/ai-resume/backend\",USE_SQLITE=\"True\"
EOF"
%SSH_PATH% %USER%@%SERVER% "cat > /etc/nginx/sites-available/ai-resume << 'EOF'
server {
    listen 80;
    server_name _;
    client_max_body_size 50M;
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location / {
        alias /var/www/ai-resume/frontend/dist/;
        try_files \$uri \$uri/ /index.html;
    }
    gzip on;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript;
}
EOF"
%SSH_PATH% %USER%@%SERVER% "ln -sf /etc/nginx/sites-available/ai-resume /etc/nginx/sites-enabled/ && rm -f /etc/nginx/sites-enabled/default && nginx -t"
%SSH_PATH% %USER%@%SERVER% "supervisorctl reread && supervisorctl update && supervisorctl restart ai-resume-backend && systemctl restart nginx"
echo.

echo ============================================
echo    部署完成！
echo ============================================
echo.
echo 访问地址: http://113.45.64.145
echo 后端状态: %SSH_PATH% %USER%@%SERVER% "supervisorctl status ai-resume-backend"
echo.
pause
