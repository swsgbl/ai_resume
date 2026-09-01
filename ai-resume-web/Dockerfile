# 前端 Dockerfile - 多阶段构建
FROM node:20-alpine AS builder

WORKDIR /app

# 复制共享包
RUN mkdir -p ai-resume-shared
COPY ai-resume-shared/package.json ai-resume-shared/
COPY ai-resume-shared/src ai-resume-shared/src
COPY ai-resume-shared/tsconfig.json ai-resume-shared/

# 复制前端代码
COPY ai-resume-web/package.json package.json
COPY ai-resume-web/package-lock.json* package-lock.json*
COPY ai-resume-web/tsconfig.json tsconfig.json
COPY ai-resume-web/tsconfig.node.json tsconfig.node.json
COPY ai-resume-web/vite.config.ts vite.config.ts
COPY ai-resume-web/index.html index.html
COPY ai-resume-web/src src/

# 更新 package.json 中的共享包路径
RUN sed -i 's|"@ai-resume/shared": "file:../ai-resume-shared"|"@ai-resume/shared": "file:./ai-resume-shared"|g' package.json

# 安装依赖
RUN npm install

# 构建应用 (使用 vite build，跳过 tsc)
RUN npx vite build

# 生产镜像 - 使用 Nginx
FROM nginx:alpine

# 复制自定义 Nginx 配置
COPY ai-resume-web/nginx.conf /etc/nginx/nginx.conf

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 暴露端口
EXPOSE 80

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1
