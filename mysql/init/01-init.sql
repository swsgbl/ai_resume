-- AI Resume Platform MySQL 初始化脚本
-- 创建数据库和用户

CREATE DATABASE IF NOT EXISTS ai_resume CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ai_resume;

-- 创建用户（如果不存在）
-- 注意: 生产环境应修改密码
CREATE USER IF NOT EXISTS 'airesume'@'%' IDENTIFIED BY 'airesume_password';
GRANT ALL PRIVILEGES ON ai_resume.* TO 'airesume'@'%';
FLUSH PRIVILEGES;
