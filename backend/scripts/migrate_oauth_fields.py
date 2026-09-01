#!/usr/bin/env python3
"""
数据库迁移脚本：添加 Gitee / Discord OAuth 字段

使用方法：
  cd backend
  python scripts/migrate_oauth_fields.py

SQLite 和 MySQL 均兼容
"""
import sqlite3
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data', 'ai_resume.db')


def migrate_sqlite():
    """SQLite 迁移：逐列添加"""
    if not os.path.exists(DB_PATH):
        print(f"数据库文件不存在: {DB_PATH}")
        print("将在应用启动时自动创建")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute("PRAGMA table_info(users)")
    existing_columns = {row[1] for row in cursor.fetchall()}

    new_columns = [
        ("gitee_id", "INTEGER UNIQUE"),
        ("gitee_login", "VARCHAR(100)"),
        ("gitee_email", "VARCHAR(255)"),
        ("discord_id", "VARCHAR(50) UNIQUE"),
        ("discord_username", "VARCHAR(100)"),
        ("discord_email", "VARCHAR(255)"),
        ("discord_avatar", "VARCHAR(500)"),
    ]

    added = 0
    for col_name, col_type in new_columns:
        if col_name not in existing_columns:
            try:
                cursor.execute(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}")
                print(f"  + 添加列: {col_name} ({col_type})")
                added += 1
            except sqlite3.OperationalError as e:
                print(f"  x 跳过 {col_name}: {e}")
        else:
            print(f"  = 已存在: {col_name}")

    conn.commit()
    conn.close()
    print(f"\n迁移完成: 新增 {added} 列")


def print_mysql_sql():
    """输出 MySQL 迁移 SQL"""
    print("""
-- MySQL 迁移 SQL：添加 Gitee / Discord OAuth 字段
ALTER TABLE users
  ADD COLUMN gitee_id INT UNIQUE DEFAULT NULL,
  ADD COLUMN gitee_login VARCHAR(100) DEFAULT NULL,
  ADD COLUMN gitee_email VARCHAR(255) DEFAULT NULL,
  ADD COLUMN discord_id VARCHAR(50) UNIQUE DEFAULT NULL,
  ADD COLUMN discord_username VARCHAR(100) DEFAULT NULL,
  ADD COLUMN discord_email VARCHAR(255) DEFAULT NULL,
  ADD COLUMN discord_avatar VARCHAR(500) DEFAULT NULL;

CREATE INDEX ix_users_gitee_id ON users(gitee_id);
CREATE INDEX ix_users_discord_id ON users(discord_id);
""")


if __name__ == "__main__":
    print("=" * 50)
    print("AI Resume - OAuth 字段迁移脚本")
    print("=" * 50 + "\n")

    db_url = os.environ.get("DATABASE_URL", "")
    if "mysql" in db_url.lower():
        print("检测到 MySQL 数据库，请手动执行以下 SQL:")
        print_mysql_sql()
    else:
        print(f"检测到 SQLite 数据库: {DB_PATH}")
        migrate_sqlite()
