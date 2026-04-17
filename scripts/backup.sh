#!/bin/bash
# AI Resume Platform - 自动备份脚本
# 用途: 备份数据库、上传文件和配置

set -e

# 配置
BACKUP_DIR="$HOME/ai-resume-backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# 确保备份目录存在
mkdir -p "$BACKUP_DIR"/{database,uploads,config}

echo "🔄 开始备份 - $DATE"

# 1. 备份数据库
echo "📦 备份数据库..."
if docker ps | grep -q ai-resume-mysql; then
    docker exec ai-resume-mysql mysqldump -u airesume -pairesume_password ai_resume | gzip > "$BACKUP_DIR/database/backup_$DATE.sql.gz"
    echo "✅ 数据库备份完成"
else
    echo "⚠️  MySQL 容器未运行，使用 SQLite 备份"
    cp /home/hongfu/ai-resume/backend/data/ai_resume.db "$BACKUP_DIR/database/backup_$DATE.db"
fi

# 2. 备份上传文件
echo "📁 备份上传文件..."
if [ -d "/home/hongfu/ai-resume/backend/uploads" ]; then
    tar -czf "$BACKUP_DIR/uploads/uploads_$DATE.tar.gz" -C /home/hongfu/ai-resume/backend/uploads .
    echo "✅ 上传文件备份完成"
fi

# 3. 备份导出文件
echo "📄 备份导出文件..."
if [ -d "/home/hongfu/ai-resume/backend/exports" ]; then
    tar -czf "$BACKUP_DIR/exports/exports_$DATE.tar.gz" -C /home/hongfu/ai-resume/backend/exports .
    echo "✅ 导出文件备份完成"
fi

# 4. 备份环境变量
echo "⚙️  备份配置文件..."
cp /home/hongfu/ai-resume/.env.production "$BACKUP_DIR/config/env_$DATE"

# 5. 清理旧备份
echo "🧹 清理 $RETENTION_DAYS 天前的备份..."
find "$BACKUP_DIR" -name "backup_*" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "env_*" -mtime +$RETENTION_DAYS -delete

# 6. 显示备份信息
echo ""
echo "✅ 备份完成！"
echo "备份位置: $BACKUP_DIR"
echo "备份时间: $DATE"
du -sh "$BACKUP_DIR"/*/

# 7. 可选: 上传到云存储 (需要配置 rclone 或 awscli)
# echo "☁️  上传到云存储..."
# rclone copy "$BACKUP_DIR" remote:ai-resume-backups/$(date +%Y%m%d)

echo "🎉 备份脚本执行完成"
