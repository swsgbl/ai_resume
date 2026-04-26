# 步骤4: 配置前端服务

## 服务信息

- **服务名称**: ai-resume-frontend
- **服务类型**: Nginx (Docker)
- **容器名称**: ai-resume-frontend
- **端口映射**: 8081:80
- **静态文件目录**: /usr/share/nginx/html

## Dokploy配置步骤

### 4.1 创建前端服务

1. 在Dokploy面板中，进入 **"AI智能体简历"** 项目
2. 点击 **"Create Service"** 按钮
3. 选择 **"Docker Compose"** 类型
4. 填写基本信息:

```
Name: ai-resume-frontend
Type: Docker Compose
```

### 4.2 配置Docker Compose

在 **"Docker Compose Configuration"** 中填入:

```yaml
version: '3.8'

services:
  ai-resume-frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: ai-resume-frontend
    restart: unless-stopped
    ports:
      - "8081:80"
    volumes:
      - ./frontend/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - ai-resume-network
    depends_on:
      - ai-resume-backend

networks:
  ai-resume-network:
    external: true
```

**注意**: 这里使用了 `external: true`，因为网络 `ai-resume-network` 已在后端服务中创建。

### 4.3 创建Nginx配置文件

在项目根目录创建 `frontend/nginx.conf`:

```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API代理 (指向后端服务)
    location /api/ {
        proxy_pass http://ai-resume-backend:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # SPA路由支持 (Vue/React Router)
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 4.4 前端Dockerfile

确保 `frontend/Dockerfile` 内容:

```dockerfile
# 构建阶段
FROM node:18-alpine AS builder

WORKDIR /app

# 复制package文件
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 生产阶段
FROM nginx:alpine

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制Nginx配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80

# 启动Nginx
CMD ["nginx", "-g", "daemon off;"]
```

### 4.5 环境变量配置

前端应用的环境变量在**构建时**注入，需要在Dockerfile中处理:

```dockerfile
# 在构建阶段添加环境变量
ARG VITE_API_BASE_URL=http://113.45.64.145:8001
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}

# 或者使用 .env.production 文件
```

在 `frontend/.env.production`:

```bash
VITE_API_BASE_URL=http://113.45.64.145:8001
VITE_APP_TITLE=AI智能体简历
VITE_APP_VERSION=1.0.0
```

### 4.6 端口配置

**容器端口**: 80 (Nginx默认端口)
**主机端口**: 8081
**协议**: TCP

### 4.7 部署配置

- **自动部署**: 启用
- **部署策略**: Rolling Update
- **副本数量**: 1

### 4.8 域名配置 (可选)

在Dokploy中为前端服务添加域名:

1. 进入 **"ai-resume-frontend"** 服务
2. 点击 **"Domains"** 标签
3. 添加域名:
   - **Domain**: `happy.ndtool.cn`
   - **HTTPS**: 启用 (Let's Encrypt)

### 4.9 保存并部署

1. 点击 **"Save"** 保存配置
2. 点击 **"Deploy"** 开始部署
3. 观察部署日志

## 验证部署

部署完成后，运行以下命令验证:

```bash
# 检查容器状态
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker ps | grep ai-resume-frontend"

# 检查前端可访问性
curl -I http://113.45.64.145:8081

# 检查Nginx日志
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "docker logs ai-resume-frontend --tail 20"
```

预期结果:
- 容器状态为 `Up`
- HTTP状态码 200
- Nginx日志无错误

## 测试前端功能

```bash
# 1. 测试首页
curl http://113.45.64.145:8081 | head -20

# 2. 测试API代理
curl http://113.45.64.145:8081/api/health

# 3. 测试静态资源
curl -I http://113.45.64.145:8081/assets/index.js
```

## 故障排查

**问题1: 构建失败**
- 检查package.json是否存在
- 验证npm版本兼容性
- 查看构建日志中的npm错误

**问题2: 容器启动失败**
- 验证nginx.conf语法: `docker run --rm -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro nginx nginx -t`
- 检查端口8081是否被占用
- 查看容器日志

**问题3: 页面404**
- 确认构建产物正确复制
- 检查nginx root路径
- 验证index.html存在

**问题4: API调用失败**
- 检查nginx proxy_pass配置
- 确认后端服务运行正常
- 验证网络连接: `docker network inspect ai-resume-network`

**问题5: SPA路由不工作**
- 确认try_files配置正确
- 检查前端路由模式
- 验证nginx配置生效

## 前端优化建议

1. **资源优化**
   - 启用Gzip压缩 (已配置)
   - 设置浏览器缓存 (已配置)
   - 使用CDN加速静态资源

2. **性能优化**
   - 代码分割 (Code Splitting)
   - 懒加载 (Lazy Loading)
   - 图片优化

3. **SEO优化**
   - 添加meta标签
   - 配置sitemap
   - 启用SSR (如需要)

## 完成标志

✅ 前端服务状态为 "Running"
✅ HTTP状态码200
✅ 页面正常显示
✅ API代理工作正常
✅ 可以继续配置环境变量

---

**当前生产环境状态**:
- 前端已部署在: /var/www/ai-resume/frontend
- 容器名: ai-resume-frontend
- 端口: 8081 (主机) → 80 (容器)
- Web服务器: Nginx (Alpine)
- 配置文件: frontend-nginx.conf
