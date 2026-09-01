#!/bin/bash
# ndtool.cn 一键部署脚本
# 本地构建 + scp 到服务器
set -e

echo "=== ndtool.cn deploy ==="
echo "[1/3] Building..."
npm run build --prefix /home/hongfu/ai-resume/ai-resume-web

echo "[2/3] Uploading to server..."
scp -r /home/hongfu/ai-resume/ai-resume-web/dist/* root@113.45.64.145:/var/www/ndtool/

echo "[3/3] Done! https://ndtool.cn/"
