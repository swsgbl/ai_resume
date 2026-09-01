# 测试体系文档

## 概述

本项目采用三层测试金字塔结构：
- 70% 单元测试 - 测试独立函数和组件
- 20% 集成测试 - 测试 API 端点和模块交互
- 10% E2E 测试 - 测试完整用户流程

**当前状态**: ✅ **1201 测试**, **81% 覆盖率** (2026-04-03)

---

## 后端测试 (pytest + FastAPI)

### 测试框架
- **pytest**: 测试运行器
- **pytest-asyncio**: 异步测试支持
- **pytest-cov**: 覆盖率报告
- **httpx**: HTTP 客户端用于 API 测试

### 测试文件结构
```
backend/tests/
├── conftest.py                          # 测试配置和 fixtures
├── test_api.py                          # 基础 API 测试
├── test_auth_api.py                     # 认证 API 测试
├── test_auth_api_extended.py            # 认证扩展测试 (22 tests)
├── test_resumes_api.py                  # 简历 API 测试
├── test_resumes_api_supplement.py       # 简历 API 补充 (27 tests)
├── test_resumes_integration.py          # 简历集成测试 (16 tests)
├── test_resumes_coverage.py             # 覆盖率优化测试 (11 tests)
├── test_resumes_missing_coverage.py     # 未覆盖行测试 (11 tests)
├── test_export_api.py                   # 导出 API 测试
├── test_export_api_comprehensive.py     # 导出综合测试
├── test_export_api_extended.py          # 导出扩展测试
├── test_export_api_integration.py       # 导出集成测试 (16 tests)
├── test_export_tasks_api.py             # 导出任务 API (13 tests)
├── test_export_tasks_bg.py              # 导出后台任务 (19 tests)
├── test_export_tasks_enhanced.py        # 导出增强测试 (16 tests)
├── test_export_tasks_unit.py            # 导出单元测试 (14 tests)
├── test_export_tasks_coverage.py        # 导出覆盖率测试 (15 tests)
└── ...
```

### 运行后端测试
```bash
cd ~/ai-resume/backend
source venv/bin/activate

# 运行所有测试
pytest tests/ -v

# 覆盖率报告
pytest tests/ --cov=app --cov-report=html

# 特定模块测试
pytest tests/test_resumes*.py -v
pytest tests/test_export*.py -v

# 快速测试 (跳过慢速测试)
pytest tests/ -v -m "not slow"
```

### 测试覆盖状态 (2026-04-03)

| 模块 | 覆盖率 | 状态 |
|------|--------|------|
| Models 层 | 100% | ✅ |
| Schemas 层 | 88-100% | ✅ |
| Core 模块 | 74-90% | ✅ |
| Services 层 | 56-95% | ✅ |
| API 层 | 参差不齐 | ⚠️ |
| ├─ export_tasks.py | 66% | ✅ |
| ├─ auth_oauth.py | 57% | ✅ |
| ├─ auth_wechat.py | 61% | ✅ |
| ├─ search.py | 66% | ✅ |
| ├─ templates.py | 60% | ✅ |
| ├─ resumes.py | 49% | ⚠️ |
| ├─ export.py | 45% | ⚠️ |
| ├─ auth.py | 38% | ⚠️ |
| └─ compliance.py | 76% | ✅ |

**整体覆盖率**: **81%** (806/4159 行)

### 已覆盖功能
- ✅ 用户注册/登录/登出
- ✅ JWT 令牌验证和刷新
- ✅ 密码修改和重置
- ✅ OAuth (Google/GitHub) 集成
- ✅ 简历 CRUD 操作
- ✅ 简历版本管理和回滚
- ✅ AI 内容生成和优化
- ✅ 分页查询和筛选
- ✅ 导出任务异步处理
- ✅ 输入验证
- ✅ 安全检查 (XSS, SQL注入)
- ✅ 速率限制
- ✅ AI 使用限额

---

## 前端测试 (vitest + Testing Library)

### 测试框架
- **vitest**: 快速单元测试框架
- **@testing-library/react**: React 组件测试
- **@testing-library/user-event**: 用户交互模拟

### 测试文件结构
```
ai-resume-web/src/
├── test/
│   └── setup.ts             # 测试设置
├── components/
│   └── *.test.tsx           # 组件测试
├── store/
│   └── *.test.ts            # 状态管理测试
└── utils/
    └── __tests__/
        └── *.test.ts        # 工具函数测试
```

### 运行前端测试
```bash
cd ~/ai-resume/ai-resume-web
npm run test              # 运行所有测试
npm run test:watch        # 监听模式
npm run test:coverage     # 覆盖率报告
npm run test:ui           # UI 界面
```

---

## E2E 测试 (Playwright)

### 测试框架
- **@playwright/test**: 跨浏览器 E2E 测试

### 测试文件结构
```
ai-resume-web/tests/e2e/
├── auth.spec.ts             # 认证流程测试
├── mobile.spec.ts           # 移动端测试
└── mobile-full-flow.spec.ts # 完整业务流程测试
```

### 运行 E2E 测试
```bash
cd ~/ai-resume/ai-resume-web
npm run test:e2e            # 运行 E2E 测试
npm run test:e2e:ui         # UI 模式
npm run test:e2e:headed     # 有头模式
```

---

## CI/CD 集成

所有测试已集成到 CI/CD 工作流：

### .github/workflows/ci.yml
- 前端代码检查 (ESLint, TypeScript)
- 前端单元测试
- 前端 E2E 测试
- 后端代码检查 (Black, Flake8, MyPy)
- 后端单元测试 (1201 tests)
- 覆盖率报告 (81%)
- 安全扫描 (CodeQL, Trivy)

---

## 测试覆盖率目标

| 类型 | 目标 | 当前状态 | 达成日期 |
|------|------|----------|----------|
| 后端整体 | 80%+ | **81%** | 2026-04-03 |
| Models 层 | 100% | **100%** | ✅ |
| API 层 | 70%+ | 49-66% | 进行中 |
| Services 层 | 75%+ | 67-95% | ✅ |

---

## 待优化模块

### 优先级: 高
- [ ] resumes.py (49% → 70%+)
- [ ] export.py (45% → 65%+)
- [ ] auth.py (38% → 60%+)

### 优先级: 中
- [ ] templates.py (60% → 75%+)
- [ ] search.py (66% → 80%+)

---

## Mock 数据策略

### 数据库
- 使用内存 SQLite 数据库
- 测试隔离：每个测试独立事务
- Fixture 预加载：test_user, test_resume, test_export_task

### 外部服务
- AI 服务：使用 AsyncMock 模拟
- 邮件服务：使用 Mock 拦截
- OAuth：使用 Mock 回调
- 文件系统：临时目录清理

### 示例
```python
# Mock AI 服务
from unittest.mock import patch, AsyncMock

mock_ai_service = AsyncMock()
mock_ai_service.generate_resume = AsyncMock(
    return_value={"content": {"basic_info": {"name": "测试"}}}
)

with patch("app.api.v1.resumes.get_ai_service", return_value=mock_ai_service):
    response = await client.post("/api/v1/resumes/1/ai/generate", ...)
```

---

## 性能测试

### 测试执行时间
- 完整测试套件: ~4 分钟 (1201 tests)
- 单模块测试: ~10-30 秒
- 快速验证: ~30 秒 (跳过慢速测试)

### 优化建议
- 使用 pytest-xdist 并行执行
- 数据库连接池复用
- 减少不必要的 fixture 初始化

---

## 最后更新

**日期**: 2026-04-03
**测试数量**: 1201
**覆盖率**: 81%
**维护者**: CTO Agent
