# 数据库迁移评估方案 (SQLite → PostgreSQL)
**创建时间**: 2026-04-17 11:10
**DevOps Agent**: 29126157-6833-4f1e-94bd-6493bd95d3f2
**优先级**: P2 (中等优先级)
**预计完成时间**: 2026-04-25

---

## 📋 当前状态评估

### 🔍 当前数据库状态

#### 当前配置 (SQLite)
```python
# .env.production
USE_SQLITE=true
DATABASE_URL=sqlite+aiosqlite:///./data/ai_resume.db

# 优势
✅ 零配置，开箱即用
✅ 轻量级，资源占用少
✅ 适合开发和测试环境
✅ 单文件数据库，易于备份

# 劣势
❌ 并发写入限制
❌ 不适合生产环境
❌ 缺乏高级特性
❌ 扩展性有限
```

#### 容器配置 (MySQL - 已就绪)
```yaml
# docker-compose.prod.yml
mysql:
  image: mysql:8.0
  container_name: ai-resume-mysql
  environment:
    MYSQL_ROOT_PASSWORD: rootpassword
    MYSQL_DATABASE: ai_resume
    MYSQL_USER: airesume
    MYSQL_PASSWORD: airesume_password
  volumes:
    - mysql_data:/var/lib/mysql
  ports:
    - "3306:3306"
  restart: unless-stopped
  profiles:
    - production  # 当前未激活
```

### 📊 数据库使用分析

#### 当前数据规模
```bash
# 检查SQLite数据库大小
ls -lh /var/lib/docker/volumes/ai-resume_backend_data/_data/ai_resume.db

# 检查表结构
docker exec ai-resume-backend python -c "
from app.core.database import engine
import sqlite3
conn = sqlite3.connect('data/ai_resume.db')
cursor = conn.cursor()
cursor.execute(\"SELECT name FROM sqlite_master WHERE type='table'\")
print(cursor.fetchall())
"
```

#### 性能分析
- **查询性能**: 当前SQLite响应时间 <100ms
- **并发支持**: 单用户场景下表现良好
- **存储使用**: 预计 <100MB (初期)

---

## 🎯 迁移目标

### PostgreSQL优势
1. **生产就绪**: 企业级关系数据库
2. **并发处理**: 优秀的多用户并发性能
3. **数据完整性**: ACID事务支持
4. **扩展性**: 支持主从复制、分片
5. **功能丰富**: JSON支持、全文搜索、地理数据
6. **生态系统**: 丰富的工具和社区支持

### 迁移动机
- **用户增长**: 预计支持1000+并发用户
- **数据安全**: 降低数据丢失风险
- **性能需求**: 支持复杂查询和大数据量
- **功能需求**: 需要高级SQL特性
- **运维要求**: 更好的监控和备份工具

---

## 🚀 迁移实施方案

### 阶段1: 准备阶段 (3天)

#### 1.1 环境准备
```bash
# 启动PostgreSQL容器
cat >> docker-compose.prod.yml << 'EOF'
  postgres:
    image: postgres:15-alpine
    container_name: ai-resume-postgres
    environment:
      POSTGRES_DB: ai_resume
      POSTGRES_USER: airesume
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-airesume_secure_password}
      POSTGRES_INITDB_ARGS: "-E UTF8 --locale=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-postgres.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U airesume"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - ai-resume-network
    profiles:
      - production

volumes:
  postgres_data:
EOF

# 创建存储卷
docker volume create postgres_data
```

#### 1.2 初始化脚本
```sql
-- scripts/init-postgres.sql
-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- 全文搜索
CREATE EXTENSION IF NOT EXISTS "btree_gin";  -- 索引优化

-- 创建数据库用户权限
GRANT ALL PRIVILEGES ON DATABASE ai_resume TO airesume;
GRANT ALL ON SCHEMA public TO airesume;
```

#### 1.3 配置更新
```python
# backend/app/core/config.py
class Settings(BaseSettings):
    # 数据库配置
    USE_SQLITE: bool = False  # 生产环境使用PostgreSQL
    
    # PostgreSQL配置
    POSTGRES_HOST: str = "postgres"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "ai_resume"
    POSTGRES_USER: str = "airesume"
    POSTGRES_PASSWORD: str = "airesume_secure_password"
    
    @property
    def DATABASE_URL(self) -> str:
        """根据环境返回数据库URL"""
        if self.USE_SQLITE:
            return "sqlite+aiosqlite:///./data/ai_resume.db"
        else:
            return f"postgresql+aiomysql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
```

---

### 阶段2: 数据迁移 (2天)

#### 2.1 Schema转换
```python
# scripts/migrate_schema.py
import asyncio
from sqlalchemy import create_engine, inspect
from alembic import op
import logging

logger = logging.getLogger(__name__)

# SQLite到PostgreSQL的类型映射
TYPE_MAPPING = {
    'INTEGER': 'INTEGER',
    'TEXT': 'TEXT',
    'REAL': 'DOUBLE PRECISION',
    'BLOB': 'BYTEA',
    'VARCHAR': 'VARCHAR(255)',
    'DATETIME': 'TIMESTAMP',
}

async def convert_schema():
    """转换数据库Schema"""
    # 连接SQLite
    sqlite_engine = create_engine('sqlite:///./data/ai_resume.db')
    sqlite_inspector = inspect(sqlite_engine)
    
    # 获取所有表
    tables = sqlite_inspector.get_table_names()
    logger.info(f"发现 {len(tables)} 个表: {tables}")
    
    # 创建PostgreSQL DDL
    postgres_ddl = []
    for table in tables:
        columns = sqlite_inspector.get_columns(table)
        primary_keys = sqlite_inspector.get_pk_constraint(table)['constrained_columns']
        foreign_keys = sqlite_inspector.get_foreign_keys(table)
        
        # 生成CREATE TABLE语句
        ddl = f"CREATE TABLE {table} (\n"
        column_defs = []
        
        for col in columns:
            pg_type = TYPE_MAPPING.get(col['type'], 'TEXT')
            nullable = "NOT NULL" if not col['nullable'] else ""
            default = f"DEFAULT {col['default']}" if col['default'] else ""
            
            col_def = f"    {col['name']} {pg_type} {nullable} {default}"
            column_defs.append(col_def)
        
        # 添加主键约束
        if primary_keys:
            column_defs.append(f"    PRIMARY KEY ({', '.join(primary_keys)})")
        
        ddl += ",\n".join(column_defs)
        ddl += "\n);"
        postgres_ddl.append(ddl)
    
    # 写入迁移脚本
    with open('scripts/postgres_schema.sql', 'w') as f:
        f.write('\n\n'.join(postgres_ddl))
    
    logger.info("Schema转换完成")

if __name__ == "__main__":
    asyncio.run(convert_schema())
```

#### 2.2 数据迁移脚本
```python
# scripts/migrate_data.py
import asyncio
import sqlite3
import asyncpg
from typing import Dict, List, Any
import json
from loguru import logger

class DataMigrator:
    """数据迁移工具"""
    
    def __init__(self, sqlite_path: str, postgres_url: str):
        self.sqlite_path = sqlite_path
        self.postgres_url = postgres_url
        self.sqlite_conn = None
        self.postgres_conn = None
    
    async def connect(self):
        """连接数据库"""
        # SQLite连接
        self.sqlite_conn = sqlite3.connect(self.sqlite_path)
        self.sqlite_conn.row_factory = sqlite3.Row
        
        # PostgreSQL连接
        self.postgres_conn = await asyncpg.connect(self.postgres_url)
        logger.info("数据库连接成功")
    
    async def close(self):
        """关闭连接"""
        if self.sqlite_conn:
            self.sqlite_conn.close()
        if self.postgres_conn:
            await self.postgres_conn.close()
        logger.info("数据库连接已关闭")
    
    async def migrate_table(self, table: str, batch_size: int = 1000):
        """迁移单个表数据"""
        logger.info(f"开始迁移表: {table}")
        
        # 获取SQLite数据
        cursor = self.sqlite_conn.cursor()
        cursor.execute(f"SELECT * FROM {table}")
        rows = cursor.fetchall()
        
        if not rows:
            logger.info(f"表 {table} 无数据，跳过")
            return
        
        # 获取列名
        columns = [description[0] for description in cursor.description]
        
        # 批量插入PostgreSQL
        migrated = 0
        batch = []
        
        for row in rows:
            row_dict = dict(row)
            
            # 数据类型转换
            for key, value in row_dict.items():
                if isinstance(value, bytes):
                    row_dict[key] = value.decode('utf-8')
                elif isinstance(value, str):
                    try:
                        # 尝试解析JSON
                        row_dict[key] = json.loads(value)
                    except:
                        pass
            
            batch.append(row_dict)
            
            if len(batch) >= batch_size:
                await self._insert_batch(table, columns, batch)
                migrated += len(batch)
                batch = []
                logger.info(f"已迁移 {migrated}/{len(rows)} 条记录")
        
        # 插入剩余数据
        if batch:
            await self._insert_batch(table, columns, batch)
            migrated += len(batch)
        
        logger.info(f"表 {table} 迁移完成，共 {migrated} 条记录")
    
    async def _insert_batch(self, table: str, columns: List[str], batch: List[Dict[str, Any]]):
        """批量插入数据"""
        if not batch:
            return
        
        # 构建INSERT语句
        col_names = ', '.join(columns)
        placeholders = ', '.join([f'${i+1}' for i in range(len(columns))])
        query = f"INSERT INTO {table} ({col_names}) VALUES ({placeholders})"
        
        # 准备数据
        values = []
        for row in batch:
            row_values = [row.get(col) for col in columns]
            values.append(row_values)
        
        # 批量插入
        await self.postgres_conn.executemany(query, values)
    
    async def migrate_all(self):
        """迁移所有数据"""
        await self.connect()
        
        try:
            # 获取所有表名
            cursor = self.sqlite_conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [row[0] for row in cursor.fetchall()]
            
            # 按依赖顺序迁移（先主表，后从表）
            migration_order = [
                'users',           # 用户表
                'resumes',         # 简历表
                'templates',       # 模板表
                'resume_templates', # 简历模板关联表
                'generations',     # 生成记录表
                'payments',        # 支付记录表
                'audit_logs'       # 审计日志表
            ]
            
            for table in migration_order:
                if table in tables:
                    await self.migrate_table(table)
                else:
                    logger.warning(f"表 {table} 不存在，跳过")
            
            logger.info("所有数据迁移完成")
            
        finally:
            await self.close()

# 使用示例
async def main():
    migrator = DataMigrator(
        sqlite_path='./data/ai_resume.db',
        postgres_url='postgresql://airesume:airesume_secure_password@postgres:5432/ai_resume'
    )
    
    await migrator.migrate_all()

if __name__ == "__main__":
    asyncio.run(main())
```

---

### 阶段3: 验证阶段 (2天)

#### 3.1 数据完整性验证
```python
# scripts/validate_migration.py
import asyncio
import sqlite3
import asyncpg
from typing import Dict, List

class MigrationValidator:
    """迁移验证工具"""
    
    def __init__(self, sqlite_path: str, postgres_url: str):
        self.sqlite_path = sqlite_path
        self.postgres_url = postgres_url
    
    async def validate(self):
        """验证数据迁移"""
        sqlite_conn = sqlite3.connect(self.sqlite_path)
        postgres_conn = await asyncpg.connect(self.postgres_url)
        
        try:
            # 获取SQLite表列表
            cursor = sqlite_conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [row[0] for row in cursor.fetchall()]
            
            validation_results = {}
            
            for table in tables:
                # 比较记录数
                sqlite_count = cursor.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
                postgres_count = await postgres_conn.fetchval(f"SELECT COUNT(*) FROM {table}")
                
                # 比较结构
                cursor.execute(f"PRAGMA table_info({table})")
                sqlite_columns = {col[1]: col[2] for col in cursor.fetchall()}
                
                postgres_columns = {}
                postgres_table_info = await postgres_conn.fetchval("""
                    SELECT column_name, data_type 
                    FROM information_schema.columns 
                    WHERE table_name = $1
                """, table)
                
                # 验证结果
                validation_results[table] = {
                    'record_count_match': sqlite_count == postgres_count,
                    'sqlite_count': sqlite_count,
                    'postgres_count': postgres_count,
                    'structure_match': len(sqlite_columns) == len(postgres_columns)
                }
            
            return validation_results
            
        finally:
            sqlite_conn.close()
            await postgres_conn.close()

async def main():
    validator = MigrationValidator(
        sqlite_path='./data/ai_resume.db',
        postgres_url='postgresql://airesume:password@postgres:5432/ai_resume'
    )
    
    results = await validator.validate()
    
    print("=== 迁移验证结果 ===")
    for table, result in results.items():
        status = "✅" if result['record_count_match'] else "❌"
        print(f"{status} {table}: SQLite={result['sqlite_count']}, PostgreSQL={result['postgres_count']}")

if __name__ == "__main__":
    asyncio.run(main())
```

#### 3.2 性能基准测试
```python
# scripts/benchmark.py
import asyncio
import time
import sqlite3
import asyncpg
from typing import List

class DatabaseBenchmark:
    """数据库性能基准测试"""
    
    def __init__(self, sqlite_path: str, postgres_url: str):
        self.sqlite_path = sqlite_path
        self.postgres_url = postgres_url
    
    async def benchmark_queries(self) -> Dict:
        """基准测试查询性能"""
        results = {}
        
        # 测试查询列表
        queries = [
            ("简单查询", "SELECT * FROM users LIMIT 100"),
            ("复杂查询", "SELECT * FROM resumes WHERE user_id IN (SELECT id FROM users LIMIT 10)"),
            ("聚合查询", "SELECT COUNT(*) as total, user_id FROM generations GROUP BY user_id"),
            ("连接查询", "SELECT u.*, r.* FROM users u JOIN resumes r ON u.id = r.user_id LIMIT 50")
        ]
        
        # SQLite测试
        sqlite_conn = sqlite3.connect(self.sqlite_path)
        for name, query in queries:
            start = time.time()
            sqlite_conn.execute(query)
            sqlite_time = time.time() - start
            
            # PostgreSQL测试
            postgres_conn = await asyncpg.connect(self.postgres_url)
            start = time.time()
            await postgres_conn.execute(query)
            postgres_time = time.time() - start
            await postgres_conn.close()
            
            results[name] = {
                'sqlite': sqlite_time,
                'postgres': postgres_time,
                'improvement': (sqlite_time - postgres_time) / sqlite_time * 100
            }
        
        sqlite_conn.close()
        return results

async def main():
    benchmark = DatabaseBenchmark(
        sqlite_path='./data/ai_resume.db',
        postgres_url='postgresql://airesume:password@postgres:5432/ai_resume'
    )
    
    results = await benchmark.benchmark_queries()
    
    print("=== 性能基准测试 ===")
    for query_name, timings in results.items():
        print(f"{query_name}:")
        print(f"  SQLite: {timings['sqlite']:.4f}s")
        print(f"  PostgreSQL: {timings['postgres']:.4f}s")
        print(f"  性能提升: {timings['improvement']:.1f}%")

if __name__ == "__main__":
    asyncio.run(main())
```

---

### 阶段4: 切换阶段 (1天)

#### 4.1 灰度切换策略
```bash
# 步骤1: 准备PostgreSQL环境
docker-compose -f docker-compose.prod.yml --profile production up -d postgres

# 步骤2: 执行数据迁移
python scripts/migrate_data.py

# 步骤3: 验证数据
python scripts/validate_migration.py

# 步骤4: 更新环境变量
# .env.production
USE_SQLITE=false
DATABASE_URL=postgresql://airesume:password@postgres:5432/ai_resume

# 步骤5: 重启Backend服务
docker-compose -f docker-compose.prod.yml restart backend

# 步骤6: 监控服务状态
docker logs ai-resume-backend -f
```

#### 4.2 回滚计划
```bash
# 如果出现问题，立即回滚到SQLite
# .env.production
USE_SQLITE=true
DATABASE_URL=sqlite+aiosqlite:///./data/ai_resume.db

# 重启服务
docker-compose -f docker-compose.prod.yml restart backend

# 验证回滚成功
curl http://localhost:8000/health
```

---

## 🔧 实施步骤

### Step 1: 环境准备 (1天)
```bash
# 1. 创建PostgreSQL容器
docker volume create postgres_data

# 2. 更新docker-compose配置
# (添加postgres服务定义)

# 3. 启动PostgreSQL
docker-compose -f docker-compose.prod.yml --profile production up -d postgres

# 4. 验证PostgreSQL运行
docker exec ai-resume-postgres pg_isready -U airesume
```

### Step 2: Schema迁移 (1天)
```bash
# 1. 导出SQLite Schema
python scripts/export_sqlite_schema.py

# 2. 转换为PostgreSQL DDL
python scripts/convert_schema.py

# 3. 在PostgreSQL中创建表结构
docker exec -i ai-resume-postgres psql -U airesume -d ai_resume < scripts/postgres_schema.sql

# 4. 验证表结构
docker exec ai-resume-postgres psql -U airesume -d ai_resume -c "\dt"
```

### Step 3: 数据迁移 (2天)
```bash
# 1. 执行数据迁移
python scripts/migrate_data.py

# 2. 验证数据完整性
python scripts/validate_migration.py

# 3. 性能基准测试
python scripts/benchmark.py

# 4. 数据抽样检查
docker exec ai-resume-postgres psql -U airesume -d ai_resume -c "SELECT COUNT(*) FROM users;"
```

### Step 4: 应用切换 (1天)
```bash
# 1. 更新环境变量
cp .env.production .env.production.sqlite_backup
nano .env.production  # 设置USE_SQLITE=false

# 2. 重启Backend服务
docker-compose -f docker-compose.prod.yml restart backend

# 3. 健康检查
curl http://localhost:8000/health

# 4. 功能测试
python scripts/integration_test.py
```

### Step 5: 监控优化 (1天)
```bash
# 1. 配置PostgreSQL监控
# - 添加Prometheus Postgres exporter
# - 配置慢查询日志
# - 设置连接池监控

# 2. 性能优化
# - 创建索引
# - 优化查询
# - 配置连接池

# 3. 备份策略
# - 配置自动备份
# - 设置恢复流程
# - 测试备份恢复
```

---

## 📊 验证清单

### 数据完整性
- [ ] 所有表迁移成功
- [ ] 记录数量一致
- [ ] 数据内容正确
- [ ] 关系完整性保持
- [ ] 索引正确创建

### 功能验证
- [ ] 用户登录正常
- [ ] 简历创建正常
- [ ] 数据查询正常
- [ ] 事务处理正常
- [ ] 并发处理正常

### 性能验证
- [ ] 查询性能提升
- [ ] 并发能力提升
- [ ] 响应时间符合预期
- [ ] 资源使用合理
- [ ] 无内存泄漏

### 安全验证
- [ ] 数据加密正确
- [ ] 访问控制配置
- [ ] 备份数据安全
- [ ] 审计日志完整
- [ ] 合规性检查通过

---

## 🐛 故障排除

### 问题1: 迁移失败
**症状**: 数据迁移过程中断
**解决方案**:
```bash
# 检查PostgreSQL日志
docker logs ai-resume-postgres | tail -50

# 检查磁盘空间
df -h

# 增加PostgreSQL内存
docker-compose -f docker-compose.prod.yml down
# 更新共享缓冲区配置
docker-compose -f docker-compose.prod.yml up -d postgres
```

### 问题2: 性能下降
**症状**: PostgreSQL性能不如SQLite
**解决方案**:
```sql
-- 创建缺失的索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_resumes_user_id ON resumes(user_id);
CREATE INDEX idx_generations_created_at ON generations(created_at);

-- 更新统计信息
ANALYZE users;
ANALYZE resumes;
ANALYZE generations;

-- 配置连接池
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET shared_buffers = '256MB';
```

### 问题3: 字符编码问题
**症状**: 中文显示乱码
**解决方案**:
```sql
-- 检查数据库编码
SELECT encoding FROM pg_database WHERE datname = 'ai_resume';

-- 修改数据库编码（如果需要）
ALTER DATABASE ai_resume ENCODING 'UTF8';

-- 重新导入数据
python scripts/migrate_data.py --encoding utf-8
```

---

## 📈 预期效果

### 性能提升
- ✅ **并发能力**: 从单用户提升到1000+并发
- ✅ **查询性能**: 复杂查询速度提升50%+
- ✅ **写入性能**: 写入吞吐量提升3倍
- ✅ **连接池**: 支持连接复用，减少开销

### 功能增强
- ✅ **全文搜索**: 支持中文全文搜索
- ✅ **JSON支持**: 原生JSON字段类型
- ✅ **事务隔离**: 更强的事务隔离级别
- ✅ **数据完整性**: 外键约束和级联操作

### 运维改善
- ✅ **备份恢复**: 更强大的备份工具
- ✅ **监控工具**: 丰富的监控和诊断工具
- ✅ **扩展性**: 支持读写分离、主从复制
- ✅ **高可用**: 支持故障转移和集群

---

## 📅 时间估算

| 阶段 | 预计时间 | 实际时间 | 状态 |
|------|----------|----------|------|
| 环境准备 | 3天 | - | 待开始 |
| 数据迁移 | 2天 | - | 待开始 |
| 验证测试 | 2天 | - | 待开始 |
| 应用切换 | 1天 | - | 待开始 |
| 监控优化 | 1天 | - | 待开始 |
| **总计** | **9天** | - | **待开始** |

---

## 🎯 风险评估

### 技术风险
- **数据丢失**: 低风险，有备份和回滚方案
- **性能回退**: 低风险，PostgreSQL性能更优
- **兼容性问题**: 中风险，需要测试SQL方言差异

### 业务风险
- **服务中断**: 低风险，使用灰度切换
- **用户体验**: 低风险，性能应该提升
- **成本增加**: 中风险，需要更多资源

### 缓解措施
- 完整的备份和恢复流程
- 详细的测试验证计划
- 灰度切换和快速回滚
- 24小时监控和支持

---

## 📞 联系信息

**项目负责人**: DevOps Agent (29126157-6833-4f1e-94bd-6493bd95d3f2)
**技术支持**: Database Team
**业务协调**: Product Team

---

**文档版本**: v1.0
**最后更新**: 2026-04-17 11:10
**下次评审**: 迁移开始前
