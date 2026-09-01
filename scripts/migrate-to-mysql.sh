#!/bin/bash
# MySQL 数据库迁移一键脚本
# 用法: ./scripts/migrate-to-mysql.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  AI Resume Platform - MySQL 迁移工具"
echo "=========================================="
echo ""

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    exit 1
fi

# 检查 docker-compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}错误: Docker Compose 未安装${NC}"
    exit 1
fi

# 1. 备份 SQLite 数据库
echo -e "${YELLOW}[1/6] 备份现有 SQLite 数据库...${NC}"
SQLITE_DB="$PROJECT_ROOT/backend/ai_resume.db"
if [ -f "$SQLITE_DB" ]; then
    BACKUP_NAME="$SQLITE_DB.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$SQLITE_DB" "$BACKUP_NAME"
    echo -e "${GREEN}✓ 备份完成: $BACKUP_NAME${NC}"
else
    echo -e "${YELLOW}⚠ SQLite 数据库不存在，跳过备份${NC}"
fi

# 2. 启动 MySQL 容器
echo -e "${YELLOW}[2/6] 启动 MySQL 数据库...${NC}"
cd "$PROJECT_ROOT"
docker-compose --profile production up -d db

echo "等待 MySQL 启动..."
for i in {1..30}; do
    if docker-compose exec -T db mysqladmin ping -h localhost --silent 2>/dev/null; then
        echo -e "${GREEN}✓ MySQL 已就绪${NC}"
        break
    fi
    echo "等待中... ($i/30)"
    sleep 1
done

# 3. 检查 MySQL 连接
echo -e "${YELLOW}[3/6] 检查 MySQL 连接...${NC}"
if docker-compose exec -T db mysql -u airesume -pairesume_password -e "USE ai_resume; SELECT 1;" &> /dev/null; then
    echo -e "${GREEN}✓ MySQL 连接正常${NC}"
else
    echo -e "${RED}错误: 无法连接到 MySQL${NC}"
    exit 1
fi

# 4. 安装迁移依赖
echo -e "${YELLOW}[4/6] 检查迁移依赖...${NC}"
cd "$PROJECT_ROOT/backend"
if ! python -c "import aiosqlite, aiomysql, tqdm" 2>/dev/null; then
    echo "安装迁移依赖..."
    pip install aiosqlite aiomysql tqdm
fi
echo -e "${GREEN}✓ 迁移依赖已就绪${NC}"

# 5. 执行迁移
echo -e "${YELLOW}[5/6] 执行数据迁移...${NC}"
export MYSQL_HOST=localhost
export MYSQL_PORT=3306
export MYSQL_USER=airesume
export MYSQL_PASSWORD=airesume_password
export MYSQL_DATABASE=ai_resume

if python scripts/migrate_sqlite_to_mysql.py; then
    echo -e "${GREEN}✓ 数据迁移完成${NC}"
else
    echo -e "${RED}错误: 数据迁移失败${NC}"
    exit 1
fi

# 6. 验证结果
echo -e "${YELLOW}[6/6] 验证迁移结果...${NC}"
docker-compose exec -T db mysql -u airesume -pairesume_password ai_resume <<'EOF'
SELECT '=== 迁移验证 ===' as '';
SELECT 'users:' as table_name, COUNT(*) as row_count FROM users
UNION ALL
SELECT 'templates:', COUNT(*) FROM templates
UNION ALL
SELECT 'resumes:', COUNT(*) FROM resumes
UNION ALL
SELECT 'resume_versions:', COUNT(*) FROM resume_versions
UNION ALL
SELECT 'favorites:', COUNT(*) FROM favorites
UNION ALL
SELECT 'operation_logs:', COUNT(*) FROM operation_logs;
EOF

echo ""
echo "=========================================="
echo -e "${GREEN}✓ MySQL 迁移完成！${NC}"
echo "=========================================="
echo ""
echo "后续步骤:"
echo "1. 更新 backend/.env 配置:"
echo "   USE_SQLITE=false"
echo "   DATABASE_URL=mysql+aiomysql://airesume:airesume_password@db:3306/ai_resume"
echo ""
echo "2. 重启后端服务:"
echo "   docker-compose restart backend"
echo ""
echo "3. 如需回滚，使用备份:"
echo "   cp $BACKUP_NAME $SQLITE_DB"
echo ""
echo "详细文档: [MYSQL_MIGRATION_GUIDE.md](MYSQL_MIGRATION_GUIDE.md)"
