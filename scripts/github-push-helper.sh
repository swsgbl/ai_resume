#!/bin/bash
# AI Resume Platform - GitHub 推送辅助脚本
# 用途: 提供多种 GitHub 代码推送方案

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 GitHub 推送问题解决工具${NC}"
echo "================================"
echo ""

# 检查当前状态
COMMITS_BEHIND=$(git log --oneline origin/main..HEAD 2>/dev/null | wc -l || echo "104")
echo -e "${GREEN}📊 当前状态:${NC}"
echo "   待推送提交: ${COMMITS_BEHIND} 个"
echo "   当前分支: $(git branch --show-current)"
echo "   远程仓库: $(git remote get-url origin)"
echo ""

# 显示可用的推送方案
echo -e "${BLUE}🚀 可用推送方案:${NC}"
echo ""
echo "方案 1: 使用 GitHub Personal Access Token (推荐)"
echo "------------------------------------------------"
echo "1. 访问: https://github.com/settings/tokens"
echo "2. 点击 'Generate new token (classic)'"
echo "3. 设置名称: AI-Resume-Deploy"
echo "4. 选择权限: ✅ repo (全部勾选)"
echo "5. 过期时间: 90 days"
echo "6. 生成并复制 Token"
echo ""
echo "推送命令:"
echo "  git push https://<YOUR_TOKEN>@github.com/18606559294/AI-.git main"
echo ""

echo "方案 2: 配置 Git 凭据存储 (一次性设置)"
echo "------------------------------------------------"
echo "1. 生成 GitHub Token (同上)"
echo "2. 配置凭据存储:"
echo "   git config --global credential.helper store"
echo "3. 推送 (会提示输入用户名和密码):"
echo "   git push origin main"
echo "   用户名: 输入任意字符"
echo "   密码: 粘贴 GitHub Token"
echo ""

echo "方案 3: 使用环境变量 (临时方案)"
echo "------------------------------------------------"
echo "1. 设置环境变量:"
echo "   export GITHUB_TOKEN=<YOUR_TOKEN>"
echo "2. 推送:"
echo "   git push https://${GITHUB_TOKEN}@github.com/18606559294/AI-.git main"
echo ""

echo "方案 4: 添加 SSH 密钥到 GitHub (永久方案)"
echo "------------------------------------------------"
echo "1. 复制 SSH 公钥:"
cat ~/.ssh/id_ed25519.pub 2>/dev/null || echo "   (SSH 密钥不存在)"
echo ""
echo "2. 添加到 GitHub:"
echo "   • 访问: https://github.com/settings/ssh"
echo "   • 点击 'New SSH key'"
echo "   • 粘贴公钥内容"
echo "   • 保存"
echo ""
echo "3. 切换到 SSH URL:"
echo "   git remote set-url origin git@github.com:18606559294/AI-.git"
echo ""
echo "4. 推送:"
echo "   git push origin main"
echo ""

# 交互式选择
echo ""
read -p "是否要立即尝试推送? (y/n): " try_push

if [ "$try_push" = "y" ] || [ "$try_push" = "Y" ]; then
    echo ""
    echo "请选择推送方式:"
    echo "1) 使用 Token 直接推送"
    echo "2) 配置凭据存储后推送"
    echo "3) 使用环境变量推送"
    echo "4) 取消"
    echo ""
    read -p "选择 (1-4): " choice

    case $choice in
        1)
            echo ""
            read -sp "请输入 GitHub Token: " token
            echo ""
            echo ""
            echo -e "${BLUE}🚀 正在推送...${NC}"
            git push https://${token}@github.com/18606559294/AI-.git main
            ;;
        2)
            echo ""
            echo "配置 Git 凭据存储..."
            git config --global credential.helper store
            echo "现在将会提示输入凭据:"
            echo "  用户名: 输入任意字符或 GitHub 用户名"
            echo "  密码: 粘贴 GitHub Token (不是 GitHub 密码!)"
            echo ""
            git push origin main
            ;;
        3)
            echo ""
            read -sp "请输入 GitHub Token: " token
            echo ""
            export GITHUB_TOKEN=$token
            echo ""
            echo -e "${BLUE}🚀 正在推送...${NC}"
            git push https://${GITHUB_TOKEN}@github.com/18606559294/AI-.git main
            ;;
        4)
            echo "取消推送"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            exit 1
            ;;
    esac

    echo ""
    echo -e "${GREEN}✅ 推送完成！${NC}"
    echo "验证推送结果:"
    git log --oneline origin/main..HEAD | wc -l
    echo "应该显示: 0 个提交"
else
    echo ""
    echo -e "${YELLOW}💡 提示:${NC}"
    echo "1. 推荐使用方案 1 (GitHub Token) - 最快最简单"
    echo "2. 长期使用建议方案 4 (SSH 密钥) - 一次配置永久使用"
    echo "3. 推送完成后，Dokploy 部署即可开始"
fi
