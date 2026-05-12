# AI Resume Platform - 测试策略

> **版本**: v1.0
> **更新日期**: 2026-05-13
> **状态**: 已批准

---

## 1. 测试金字塔

```
        ▲
       / \        E2E Tests (10%)
      /   \       Playwright / Appium
     /-----\
    /       \      Integration Tests (20%)
   /         \     API Tests / Service Tests
  /-----------\
 /             \    Unit Tests (70%)
/_______________\   Vitest / pytest
```

---

## 2. 测试覆盖目标

| 层级 | 工具 | 目标覆盖率 | 当前状态 |
|------|------|-----------|---------|
| 前端单元 | Vitest | 80% | ✅ 31 文件, 362 测试通过 |
| 前端 E2E | Playwright | 核心流程 100% | ✅ 5 文件配置 |
| 后端单元 | pytest | 80% | ⚠️ 需扩展 |
| 后端集成 | pytest-asyncio | API 覆盖 | ⚠️ 需扩展 |
| 桌面端 | Playwright | 核心流程 | ✅ 2 文件 |
| 移动端 | Appium | 核心流程 | ✅ 配置完成 |

---

## 3. 前端测试策略 (ai-resume-web)

### 3.1 单元测试 (Vitest)

**配置文件**: `vitest.config.ts`

**运行命令**:
```bash
npm run test              # 运行所有测试
npm run test:watch        # 监视模式
npm run test:ui           # UI 界面
npm run test:coverage     # 覆盖率报告
```

**测试结构**:
```
src/
├── components/
│   ├── ui/
│   │   ├── Button.tsx
│   │   └── Button.test.tsx      # 组件测试
│   └── editor/
│       └── DraggableSection.test.tsx
├── pages/
│   └── LoginPage.test.tsx       # 页面测试
├── store/
│   └── auth.test.ts             # 状态测试
└── utils/
    └── cn.test.ts               # 工具函数测试
```

**测试标准**:
- 每个组件必须有对应的 `.test.tsx` 文件
- 测试必须覆盖主要用户交互路径
- 使用 `@testing-library/react` 进行 DOM 测试
- Mock 外部依赖 (API, localStorage)

### 3.2 E2E 测试 (Playwright)

**配置文件**: `playwright.config.ts`

**运行命令**:
```bash
npm run test:e2e           # 运行 E2E 测试
npm run test:e2e:ui        # UI 模式
npm run test:e2e:headed    # 有头模式（查看浏览器）
```

**测试场景**:
1. **认证流程**: 登录、注册、密码重置
2. **简历编辑**: 创建、编辑、保存、预览
3. **导出功能**: PDF/DOCX 导出
4. **用户设置**: 个人资料、偏好设置

**设备覆盖**:
- Desktop Chrome (1280x720)
- Mobile iPhone 12
- Mobile Pixel 5 (Android)

---

## 4. 后端测试策略 (backend)

### 4.1 单元测试 (pytest)

**配置文件**: `tests/conftest.py`

**运行命令**:
```bash
pytest                       # 运行所有测试
pytest -v                    # 详细输出
pytest --cov=app            # 覆盖率报告
pytest -x                   # 遇到失败立即停止
```

**测试结构**:
```
tests/
├── conftest.py              # Fixtures 配置
├── test_api.py              # API 端点测试
├── test_services/           # 服务层测试
├── test_models/             # 模型测试
└── test_security/           # 安全测试
```

**Fixtures** (已配置):
- `db_session`: 测试数据库会话 (SQLite 内存)
- `client`: FastAPI 测试客户端
- `test_user`: 测试用户
- `auth_headers`: 认证头
- `test_resume`: 测试简历
- `test_export_task`: 测试导出任务

**Mock 策略**:
- Redis: 使用 `fake://` 协议 mock
- 外部 API: 使用 `pytest-mock` mock
- AI 服务: 使用 Mock 响应

### 4.2 集成测试

**测试场景**:
1. **API 端点**: 所有 `/api/*` 路由
2. **数据库**: CRUD 操作
3. **认证**: JWT 生成和验证
4. **文件处理**: 上传、解析、导出

---

## 5. 桌面端测试策略 (ai-resume-desktop)

**运行命令**:
```bash
npm run test                 # Playwright E2E
```

**测试重点**:
- Tauri API 集成
- 文件系统访问
- 桌面通知
- 离线功能

---

## 6. 移动端测试策略 (ai-resume-harmonyos)

**测试工具**: HarmonyOS 测试框架

**测试脚本**: `scripts/run-tests.sh`

**测试重点**:
- 单元测试 (hvigor-ohos-plugin)
- 设备测试 (真机/模拟器)
- 性能测试

---

## 7. 测试工作流

### 7.1 开发阶段

```bash
# 开发时运行单元测试（监视模式）
npm run test:watch          # 前端
pytest -f                   # 后端（失败停止）

# 提交前运行全部测试
npm run test && npm run test:e2e
pytest --cov=app
```

### 7.2 CI/CD 集成

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  frontend:
    runs-on: ubuntu-latest
    steps:
      - run: npm run test:coverage
      - run: npm run test:e2e

  backend:
    runs-on: ubuntu-latest
    steps:
      - run: pytest --cov=app --cov-report=xml
```

### 7.3 覆盖率门禁

- **最低覆盖率**: 70%
- **新增代码覆盖率**: 80%
- **关键路径覆盖率**: 100%

---

## 8. 测试质量标准

### 8.1 单元测试标准

- ✅ 每个函数/方法至少一个测试
- ✅ 边界条件测试
- ✅ 错误处理测试
- ✅ Mock 所有外部依赖

### 8.2 集成测试标准

- ✅ 端到端业务流程
- ✅ 数据一致性验证
- ✅ 错误恢复测试

### 8.3 E2E 测试标准

- ✅ 核心用户路径
- ✅ 跨浏览器/设备验证
- ✅ 性能基准测试

---

## 9. 待完成事项

### 9.1 前端 (优先级: 中)

- [ ] 修复 `window.scrollTo` mock 警告
- [ ] 更新 React Router v7 兼容性
- [ ] 增加覆盖率报告到 CI

### 9.2 后端 (优先级: 高)

- [ ] 安装 pytest 依赖到 venv
- [ ] 创建 API 端点集成测试
- [ ] 添加 pytest-cov 配置
- [ ] 创建性能测试基准

### 9.3 通用 (优先级: 低)

- [ ] 建立测试报告仪表板
- [ ] 设置覆盖率趋势监控
- [ ] 创建视觉回归测试

---

## 10. 参考资料

- [Vitest 文档](https://vitest.dev/)
- [Playwright 文档](https://playwright.dev/)
- [pytest 文档](https://docs.pytest.org/)
- [Testing Library](https://testing-library.com/)
