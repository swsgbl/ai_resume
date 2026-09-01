#!/bin/bash
# AI简历平台部署脚本 - 适配 2核2GB 配置
# 服务器: Ubuntu 24.04

set -e

echo "========================================="
echo "   AI简历平台 - 服务器部署脚本"
echo "   适用: Ubuntu 24.04 | 2核2GB"
echo "========================================="
echo

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 1. 更新系统
echo ">>> [1/7] 更新系统软件包..."
apt update && apt upgrade -y

# 2. 安装基础工具
echo ">>> [2/7] 安装基础工具..."
apt install -y curl wget git vim htop net-tools

# 3. 安装 Python 3.11
echo ">>> [3/7] 安装 Python 3.11..."
apt install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
apt update
apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

# 4. 安装 Node.js 20 (用于构建前端)
echo ">>> [4/7] 安装 Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# 5. 安装 Nginx (轻量级Web服务器)
echo ">>> [5/7] 安装 Nginx..."
apt install -y nginx

# 6. 安装 Supervisor (进程管理，防止服务崩溃)
echo ">>> [6/7] 安装 Supervisor..."
apt install -y supervisor

# 7. 配置系统参数 (针对2GB内存优化)
echo ">>> [7/7] 优化系统配置..."

# 创建交换空间 (增加2GB虚拟内存，防止内存不足)
if [ ! -f /swapfile ]; then
    echo "创建 2GB 交换空间..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# 设置最大文件句柄
echo "* soft nofile 65535" >> /etc/security/limits.conf
echo "* hard nofile 65535" >> /etc/security/limits.conf

# 配置时区
timedatectl set-timezone Asia/Shanghai

echo
echo "========================================="
echo "   基础环境安装完成！"
echo "========================================="
echo
echo "版本信息："
echo "  Python: $(python3.11 --version)"
echo "  Node.js: $(node --version)"
echo "  Nginx: $(nginx -v 2>&1)"
echo "  交换空间: $(free -h | grep Swap | awk '{print $2}')"
echo
echo "========================================="
echo "  下一步: 上传项目并运行 deploy_app.sh"
echo "========================================="
