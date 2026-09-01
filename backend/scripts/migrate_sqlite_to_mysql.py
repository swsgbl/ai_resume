#!/usr/bin/env python3
"""
SQLite 到 MySQL 数据库迁移脚本

用法:
    python scripts/migrate_sqlite_to_mysql.py

依赖:
    pip install aiosqlite aiomysql tqdm
"""
import asyncio
import json
import os
import sys
from pathlib import Path
from datetime import datetime
from typing import Any, Dict, List, Optional

import aiosqlite
import aiomysql
from tqdm import tqdm


# 配置
SQLITE_DB_PATH = os.path.expanduser("~/ai-resume/backend/ai_resume.db")
MYSQL_CONFIG = {
    "host": os.getenv("MYSQL_HOST", "localhost"),
    "port": int(os.getenv("MYSQL_PORT", "3306")),
    "user": os.getenv("MYSQL_USER", "root"),
    "password": os.getenv("MYSQL_PASSWORD", ""),
    "db": os.getenv("MYSQL_DATABASE", "ai_resume"),
    "charset": "utf8mb4",
}


class DataMigrator:
    """数据迁移器"""

    def __init__(self, sqlite_path: str, mysql_config: Dict[str, Any]):
        self.sqlite_path = sqlite_path
        self.mysql_config = mysql_config
        self.sqlite_conn: Optional[aiosqlite.Connection] = None
        self.mysql_conn: Optional[aiomysql.Connection] = None

    async def connect(self):
        """连接数据库"""
        print(f"连接 SQLite: {self.sqlite_path}")
        self.sqlite_conn = await aiosqlite.connect(self.sqlite_path)
        self.sqlite_conn.row_factory = aiosqlite.Row

        print(f"连接 MySQL: {self.mysql_config['host']}:{self.mysql_config['port']}")
        self.mysql_conn = await aiomysql.connect(**self.mysql_config)

    async def close(self):
        """关闭连接"""
        if self.sqlite_conn:
            await self.sqlite_conn.close()
        if self.mysql_conn:
            self.mysql_conn.close()

    async def export_table(self, table_name: str) -> List[Dict[str, Any]]:
        """从 SQLite 导出表数据"""
        cursor = await self.sqlite_conn.execute(f"SELECT * FROM {table_name}")
        rows = await cursor.fetchall()
        columns = [description[0] for description in cursor.description]

        data = []
        for row in rows:
            row_dict = dict(zip(columns, row))
            # 处理 JSON 字段
            for key, value in row_dict.items():
                if isinstance(value, str):
                    # 尝试解析 JSON
                    try:
                        row_dict[key] = json.loads(value)
                    except (json.JSONDecodeError, ValueError):
                        pass
                elif isinstance(value, bytes):
                    row_dict[key] = value.decode('utf-8')
            data.append(row_dict)

        return data

    def _convert_value(self, value: Any) -> Any:
        """转换值为 SQL 格式"""
        if value is None:
            return "NULL"
        elif isinstance(value, bool):
            return "1" if value else "0"
        elif isinstance(value, (int, float)):
            return str(value)
        elif isinstance(value, (dict, list)):
            return f"'{json.dumps(value, ensure_ascii=False).replace(chr(39), chr(39)+chr(39))}'"
        elif isinstance(value, str):
            # 转义单引号
            escaped = value.replace("\\", "\\\\").replace("'", "''")
            return f"'{escaped}'"
        else:
            return f"'{value}'"

    async def import_table(self, table_name: str, data: List[Dict[str, Any]]):
        """导入数据到 MySQL"""
        if not data:
            print(f"  跳过空表: {table_name}")
            return 0

        columns = list(data[0].keys())
        placeholders = ", ".join(["%s"] * len(columns))
        columns_str = ", ".join([f"`{c}`" for c in columns])

        async with self.mysql_conn.cursor() as cursor:
            # 禁用外键检查以允许孤儿数据
            await cursor.execute("SET FOREIGN_KEY_CHECKS=0")
            # 清空现有数据
            await cursor.execute(f"DELETE FROM `{table_name}`")

            # 批量插入
            values = []
            for row in data:
                row_values = []
                for col in columns:
                    val = row.get(col)
                    if val is None:
                        row_values.append(None)
                    elif isinstance(val, (dict, list)):
                        row_values.append(json.dumps(val, ensure_ascii=False))
                    elif isinstance(val, bool):
                        row_values.append(1 if val else 0)
                    else:
                        row_values.append(val)
                values.append(row_values)

            await cursor.executemany(
                f"INSERT INTO `{table_name}` ({columns_str}) VALUES ({placeholders})",
                values
            )
            await self.mysql_conn.commit()
            # 重新启用外键检查
            await cursor.execute("SET FOREIGN_KEY_CHECKS=1")
            return cursor.rowcount

    async def migrate_table(self, table_name: str, order: str = "") -> int:
        """迁移单个表"""
        print(f"{order}迁移表: {table_name}")
        data = await self.export_table(table_name)
        print(f"  从 SQLite 导出 {len(data)} 行")

        count = await self.import_table(table_name, data)
        print(f"  导入 MySQL {count} 行")
        return count

    async def reset_auto_increment(self):
        """重置 MySQL 自增 ID"""
        print("\n重置自增 ID...")
        tables = ["users", "templates", "resumes", "resume_versions", "favorites", "operation_logs"]

        async with self.mysql_conn.cursor() as cursor:
            for table in tables:
                # 获取最大 ID
                await cursor.execute(f"SELECT MAX(id) as max_id FROM `{table}`")
                result = await cursor.fetchone()
                max_id = result[0] if result and result[0] else 0

                # 设置自增值
                next_id = max_id + 1
                await cursor.execute(f"ALTER TABLE `{table}` AUTO_INCREMENT = {next_id}")
                print(f"  {table}: AUTO_INCREMENT = {next_id}")

            await self.mysql_conn.commit()

    async def migrate_all(self):
        """迁移所有表"""
        # 按依赖顺序迁移
        tables_order = [
            "users",
            "templates",
            "resumes",
            "resume_versions",
            "favorites",
            "operation_logs",
        ]

        total_rows = 0
        for i, table in enumerate(tables_order, 1):
            count = await self.migrate_table(table, f"[{i}/{len(tables_order)}] ")
            total_rows += count
            print()

        # 重置自增 ID
        await self.reset_auto_increment()

        print(f"\n✅ 迁移完成! 共迁移 {total_rows} 行数据")
        return total_rows

    async def verify_migration(self):
        """验证迁移结果"""
        print("\n验证迁移结果...")
        tables = ["users", "templates", "resumes", "resume_versions", "favorites", "operation_logs"]

        all_match = True
        for table in tables:
            # SQLite count
            sqlite_cursor = await self.sqlite_conn.execute(f"SELECT COUNT(*) FROM {table}")
            sqlite_count = (await sqlite_cursor.fetchone())[0]

            # MySQL count
            async with self.mysql_conn.cursor() as cursor:
                await cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
                mysql_count = (await cursor.fetchone())[0]

            match = "✅" if sqlite_count == mysql_count else "❌"
            print(f"  {match} {table}: SQLite={sqlite_count}, MySQL={mysql_count}")
            if sqlite_count != mysql_count:
                all_match = False

        return all_match


async def main():
    """主函数"""
    print("=" * 60)
    print("SQLite 到 MySQL 数据库迁移")
    print("=" * 60)
    print()

    # 检查 SQLite 文件
    if not os.path.exists(SQLITE_DB_PATH):
        print(f"❌ 错误: SQLite 数据库文件不存在: {SQLITE_DB_PATH}")
        sys.exit(1)

    # 创建迁移器
    migrator = DataMigrator(SQLITE_DB_PATH, MYSQL_CONFIG)

    try:
        # 连接数据库
        await migrator.connect()
        print()

        # 执行迁移
        await migrator.migrate_all()

        # 验证结果
        success = await migrator.verify_migration()

        if success:
            print("\n✅ 所有验证通过!")
        else:
            print("\n⚠️ 部分验证失败，请检查数据!")

    except Exception as e:
        print(f"\n❌ 迁移失败: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        await migrator.close()


if __name__ == "__main__":
    asyncio.run(main())
