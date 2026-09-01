#!/bin/bash
# AI简历平台应用部署脚本

set -e

# 配置变量
APP_DIR="/var/www/ai-resume"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"
VENV_DIR="$BACKEND_DIR/venv"
DOMAIN="113.45.64.145"  # 修改为你的域名

echo "========================================="
echo "   AI简历平台 - 应用部署"
echo "========================================="
echo

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 1. 创建应用目录
echo ">>> [1/8] 创建应用目录..."
mkdir -p $APP_DIR
mkdir -p $APP_DIR/logs
mkdir -p $APP_DIR/uploads
mkdir -p $APP_DIR/exports

# 2. 部署后端
echo ">>> [2/8] 部署后端..."
if [ -d "$BACKEND_DIR" ]; then
    cd $BACKEND_DIR
    git pull || echo "非git仓库，跳过更新"
else
    echo "请先上传后端代码到 $BACKEND_DIR"
    exit 1
fi

# 创建虚拟环境
if [ ! -d "$VENV_DIR" ]; then
    python3.11 -m venv $VENV_DIR
fi

# 激活虚拟环境并安装依赖
source $VENV_DIR/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 3. 初始化数据库
echo ">>> [3/8] 初始化数据库..."
cd $BACKEND_DIR
export PYTHONPATH="$BACKEND_DIR:$PYTHONPATH"
python3.11 -c "
import asyncio
from app.core.database import init_db, AsyncSessionLocal
from app.data.init_templates_async import init_templates_async

async def setup():
    await init_db()
    async with AsyncSessionLocal() as db:
        await init_templates_async(db)
    print('数据库初始化完成')

asyncio.run(setup())
"

# 4. 构建前端
echo ">>> [4/8] 构建前端..."
if [ -d "$FRONTEND_DIR" ]; then
    cd $FRONTEND_DIR
    npm install
    npm run build
else
    echo "请先上传前端代码到 $FRONTEND_DIR"
    exit 1
fi

# 5. 配置 Supervisor (后端进程管理)
echo ">>> [5/8] 配置 Supervisor..."
cat > /etc/supervisor/conf.d/ai-resume-backend.conf << EOF
[program:ai-resume-backend]
command=$VENV_DIR/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1
directory=$BACKEND_DIR
user=www-data
autostart=true
autorestart=true
stderr_logfile=$APP_DIR/logs/backend-error.log
stdout_logfile=$APP_DIR/logs/backend.log
environment=
    PYTHONPATH="$BACKEND_DIR",
    USE_SQLITE="True"
EOF

# 6. 配置 Nginx
echo ">>> [6/8] 配置 Nginx..."
cat > /etc/nginx/sites-available/ai-resume << 'EOF'
# 后端 API
server {
    listen 80;
    server_name _;

    # 客户端最大请求体大小 (用于简历导出等)
    client_max_body_size 50M;

    # 后端 API 代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket 支持 (如果需要)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # 超时设置
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
    }

    # 前端静态文件
    location / {
        alias /var/www/ai-resume/frontend/dist/;
        try_files $uri $uri/ /index.html;

        # 静态资源缓存
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Gzip 压缩 (节省带宽)
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml font/truetype font/opentype
               application/vnd.ms-fontobject image/svg+xml;

    # 禁用访问日志 (减少IO)
    access_log off;
}
EOF

ln -sf /etc/nginx/sites-available/ai-resume /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 测试 Nginx 配置
nginx -t

# 7. 设置文件权限
echo ">>> [7/8] 设置文件权限..."
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR

# 8. 启动服务
echo ">>> [8/8] 启动服务..."
supervisorctl reread
supervisorctl update
supervisorctl restart ai-resume-backend
systemctl restart nginx

echo
echo "========================================="
echo "   部署完成！"
echo "========================================="
echo
echo "服务地址: http://$DOMAIN"
echo
echo "服务状态:"
echo "  后端:    supervisorctl status ai-resume-backend"
echo "  Nginx:   systemctl status nginx"
echo
echo "查看日志:"
echo "  后端:    tail -f $APP_DIR/logs/backend.log"
echo "  Nginx:   tail -f /var/log/nginx/error.log"
echo
echo "========================================="
