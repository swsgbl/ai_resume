# Views 层测试规划

**文档版本**: 1.0
**创建时间**: 2026-03-29 21:55
**工程师**: 鸿蒙开发工程师 (3c488c61-7b1a-48ea-86d3-09a311315cf1)
**项目**: AI Resume HarmonyOS

---

## 📋 概述

本文档规划了 Views 层（UI 组件）的测试策略和实施方案。

### 当前状态

| 组件 | 文件 | 状态 | 测试 |
|------|------|------|------|
| HomePage | HomePage.cj | ✅ 完成 | ❌ 无 |
| LoginPage | LoginPage.cj | ✅ 完成 | ❌ 无 |
| ProfilePage | ProfilePage.cj | ✅ 完成 | ❌ 无 |
| RegisterPage | RegisterPage.cj | ✅ 完成 | ❌ 无 |
| ResumeEditorPage | ResumeEditorPage.cj | ✅ 完成 | ❌ 无 |
| TemplateSelectPage | TemplateSelectPage.cj | ✅ 完成 | ❌ 无 |

**覆盖率**: 0% (Views 层目前没有测试)

---

## 🎯 测试目标

### 主要目标

1. **UI 组件测试覆盖率达到 60%+**
2. **关键用户流程的端到端测试**
3. **UI 交互的正确性验证**
4. **状态管理和数据流测试**

### 测试类型

| 测试类型 | 目标覆盖率 | 优先级 | 工具 |
|---------|-----------|--------|------|
| 单元测试 | 50% | 高 | Hypium |
| 集成测试 | 30% | 中 | Hypium |
| UI 测试 | 20% | 中 | ArkUI Test |
| E2E 测试 | 10% | 低 | Playwright |

---

## 🧪 测试策略

### 1. LoginPage 测试

#### 功能需求
- 邮箱输入验证
- 密码输入验证
- 登录按钮状态
- 错误消息显示
- 加载状态
- 成功跳转

#### 测试用例设计

```cangjie
@TestCase
public class LoginPageTest {
    private var page: LoginPage = LoginPage()
    private var viewModel: AuthViewModel = AuthViewModel()

    @Test
    public func testInitialization(): Unit {
        // Arrange & Act & Assert
        Assert.assertNotNull(page)
        Assert.assertEquals("", page.getEmail())
        Assert.assertEquals("", page.getPassword())
    }

    @Test
    public func testEmailInputValidation(): Unit {
        // Arrange
        let invalidEmail = "invalid-email"

        // Act
        page.onEmailChanged(invalidEmail)

        // Assert
        Assert.assertEquals(invalidEmail, page.getEmail())
        Assert.assertTrue(page.isEmailError())
    }

    @Test
    public func testPasswordInputValidation(): Unit {
        // Arrange
        let shortPassword = "123"

        // Act
        page.onPasswordChanged(shortPassword)

        // Assert
        Assert.assertEquals(shortPassword, page.getPassword())
        Assert.assertTrue(page.isPasswordError())
    }

    @Test
    public func testLoginButtonDisabledWhenEmpty(): Unit {
        // Arrange & Act
        page.onEmailChanged("")
        page.onPasswordChanged("")

        // Assert
        Assert.assertFalse(page.isLoginButtonEnabled())
    }

    @Test
    public func testLoginButtonEnabledWhenValid(): Unit {
        // Arrange & Act
        page.onEmailChanged("test@example.com")
        page.onPasswordChanged("password123")

        // Assert
        Assert.assertTrue(page.isLoginButtonEnabled())
    }

    @Test
    public func testShowErrorMessage(): Unit {
        // Arrange
        let errorMessage = "邮箱或密码错误"

        // Act
        page.onLoginFailed(errorMessage)

        // Assert
        Assert.assertEquals(errorMessage, page.getErrorMessage())
        Assert.assertTrue(page.isErrorVisible())
    }

    @Test
    public func testShowLoadingState(): Unit {
        // Arrange
        Assert.assertFalse(page.isLoading())

        // Act
        page.onLoginStart()

        // Assert
        Assert.assertTrue(page.isLoading())
        Assert.assertFalse(page.isLoginButtonEnabled())
    }

    @Test
    public func testHideLoadingState(): Unit {
        // Arrange
        page.onLoginStart()

        // Act
        page.onLoginComplete()

        // Assert
        Assert.assertFalse(page.isLoading())
    }

    @Test
    public func testNavigateToRegister(): Unit {
        // Arrange & Act
        page.onRegisterClick()

        // Assert
        Assert.assertTrue(page.isNavigatingToRegister())
    }

    @Test
    public func testNavigateToHome(): Unit {
        // Arrange & Act
        page.onLoginSuccess()

        // Assert
        Assert.assertTrue(page.isNavigatingToHome())
    }

    @Test
    public func testClearErrorMessage(): Unit {
        // Arrange
        page.onLoginFailed("错误")

        // Act
        page.onEmailChanged("new@email.com")

        // Assert
        Assert.assertEquals("", page.getErrorMessage())
    }

    @Test
    public func testPasswordVisibilityToggle(): Unit {
        // Arrange
        Assert.assertFalse(page.isPasswordVisible())

        // Act
        page.onPasswordVisibilityClick()

        // Assert
        Assert.assertTrue(page.isPasswordVisible())

        // Act again
        page.onPasswordVisibilityClick()

        // Assert
        Assert.assertFalse(page.isPasswordVisible())
    }
}
```

### 2. RegisterPage 测试

#### 功能需求
- 用户名、邮箱、密码输入验证
- 密码确认匹配验证
- 注册按钮状态
- 错误消息显示
- 加载状态
- 成功跳转

#### 测试用例设计 (10个测试方法)

```cangjie
@TestCase
public class RegisterPageTest {
    private var page: RegisterPage = RegisterPage()

    @Test
    public func testInitialization(): Unit { /* ... */ }

    @Test
    public func testUsernameValidation(): Unit { /* ... */ }

    @Test
    public func testEmailValidation(): Unit { /* ... */ }

    @Test
    public func testPasswordValidation(): Unit { /* ... */ }

    @Test
    public func testPasswordConfirmMatch(): Unit { /* ... */ }

    @Test
    public func testRegisterButtonDisabledWhenInvalid(): Unit { /* ... */ }

    @Test
    public func testRegisterButtonEnabledWhenValid(): Unit { /* ... */ }

    @Test
    public func testShowErrorMessage(): Unit { /* ... */ }

    @Test
    public func testLoadingState(): Unit { /* ... */ }

    @Test
    public func testNavigateToLogin(): Unit { /* ... */ }
}
```

### 3. HomePage 测试

#### 功能需求
- 简历列表显示
- 空状态显示
- 加载状态
- 点击简历跳转
- 创建简历按钮
- 下拉刷新
- 上拉加载更多

#### 测试用例设计 (12个测试方法)

```cangjie
@TestCase
public class HomePageTest {
    private var page: HomePage = HomePage()
    private var viewModel: ResumeViewModel = ResumeViewModel()

    @Test
    public func testInitialization(): Unit { /* ... */ }

    @Test
    public func testShowResumeList(): Unit { /* ... */ }

    @Test
    public func testShowEmptyState(): Unit { /* ... */ }

    @Test
    public func testShowLoadingState(): Unit { /* ... */ }

    @Test
    public func testResumeItemClick(): Unit { /* ... */ }

    @Test
    public func testCreateButtonClick(): Unit { /* ... */ }

    @Test
    public func testPullToRefresh(): Unit { /* ... */ }

    @Test
    public func testLoadMore(): Unit { /* ... */ }

    @Test
    public func testLogout(): Unit { /* ... */ }

    @Test
    public func testProfileNavigation(): Unit { /* ... */ }

    @Test
    public func testErrorDisplay(): Unit { /* ... */ }

    @Test
    public func testSwipeToDelete(): Unit { /* ... */ }
}
```

### 4. ResumeEditorPage 测试

#### 功能需求
- 简历信息编辑
- 实时保存
- AI 生成功能
- 模板切换
- 预览功能
- 导出功能
- 表单验证

#### 测试用例设计 (15个测试方法)

```cangjie
@TestCase
public class ResumeEditorPageTest {
    private var page: ResumeEditorPage = ResumeEditorPage()

    @Test
    public func testInitialization(): Unit { /* ... */ }

    @Test
    public func testLoadResumeData(): Unit { /* ... */ }

    @Test
    public func testEditPersonalInfo(): Unit { /* ... */ }

    @Test
    public func testAddWorkExperience(): Unit { /* ... */ }

    @Test
    public func testEditWorkExperience(): Unit { /* ... */ }

    @Test
    public func testDeleteWorkExperience(): Unit { /* ... */ }

    @Test
    public func testAddEducation(): Unit { /* ... */ }

    @Test
    public func testAIGenerateContent(): Unit { /* ... */ }

    @Test
    public func testTemplateSwitch(): Unit { /* ... */ }

    @Test
    public func testPreviewResume(): Unit { /* ... */ }

    @Test
    public func testExportToPDF(): Unit { /* ... */ }

    @Test
    public func testSaveResume(): Unit { /* ... */ }

    @Test
    public func testAutoSave(): Unit { /* ... */ }

    @Test
    public func testFormValidation(): Unit { /* ... */ }

    @Test
    public func testBackNavigationWithUnsavedChanges(): Unit { /* ... */ }
}
```

### 5. TemplateSelectPage 测试

#### 功能需求
- 模板列表显示
- 模板预览
- 模板选择
- 模板筛选
- 模板搜索

#### 测试用例设计 (8个测试方法)

```cangjie
@TestCase
public class TemplateSelectPageTest {
    private var page: TemplateSelectPage = TemplateSelectPage()

    @Test
    public func testInitialization(): Unit { /* ... */ }

    @Test
    public func testShowTemplateList(): Unit { /* ... */ }

    @Test
    public func testTemplatePreview(): Unit { /* ... */ }

    @Test
    public func testTemplateSelection(): Unit { /* ... */ }

    @Test
    public func testTemplateFilter(): Unit { /* ... */ }

    @Test
    public func testTemplateSearch(): Unit { /* ... */ }

    @Test
    public func testApplyTemplate(): Unit { /* ... */ }

    @Test
    public func testCancelSelection(): Unit { /* ... */ }
}
```

### 6. ProfilePage 测试

#### 功能需求
- 用户信息显示
- 退出登录
- 设置菜单
- 个人信息编辑

#### 测试用例设计 (6个测试方法)

```cangjie
@TestCase
public class ProfilePageTest {
    private var page: ProfilePage = ProfilePage()

    @Test
    public func testInitialization(): Unit { /* ... */ }

    @Test
    public func testShowUserInfo(): Unit { /* ... */ }

    @Test
    public func testLogout(): Unit { /* ... */ }

    @Test
    public func testEditProfile(): Unit { /* ... */ }

    @Test
    public func testSettingsNavigation(): Unit { /* ... */ }

    @Test
    public func testAboutPage(): Unit { /* ... */ }
}
```

---

## 🔧 测试工具和框架

### Hypium 测试框架

```cangjie
import { testing } from '@ohos/hypium'

@TestCase
public class MyViewTest {
    @Test
    public func testViewBehavior(): Unit {
        // 测试代码
    }
}
```

### ArkUI Test Framework

```cangjie
import { uiTest } from '@ohos/uiTest'

@TestCase
public class MyUITest {
    @Test
    public func testUIInteraction(): Unit {
        // UI 测试代码
    }
}
```

### Mock 对象

```cangjie
// Mock ViewModel
class MockAuthViewModel {
    public var loginResult: Result<AuthToken> = Result.error("Not mocked")

    public func login(email: String, password: String): Result<AuthToken> {
        return loginResult
    }
}
```

---

## 📊 测试覆盖目标

### Views 层测试覆盖目标

| 组件 | 测试方法 | 目标 | 优先级 |
|------|----------|------|--------|
| LoginPage | 12 | 85% | 高 |
| RegisterPage | 10 | 80% | 高 |
| HomePage | 12 | 75% | 高 |
| ResumeEditorPage | 15 | 70% | 中 |
| TemplateSelectPage | 8 | 65% | 中 |
| ProfilePage | 6 | 60% | 低 |
| **总计** | **63** | **70%** | - |

---

## 🚀 实施计划

### Phase 1: 基础测试 (2周)

**优先级: 高**

- [x] LoginPage 测试 (12个方法)
- [ ] RegisterPage 测试 (10个方法)
- [ ] HomePage 测试 (12个方法)

**目标**: 覆盖核心用户流程

### Phase 2: 复杂测试 (2周)

**优先级: 中**

- [ ] ResumeEditorPage 测试 (15个方法)
- [ ] TemplateSelectPage 测试 (8个方法)

**目标**: 覆盖编辑和模板功能

### Phase 3: 补充测试 (1周)

**优先级: 低**

- [ ] ProfilePage 测试 (6个方法)
- [ ] UI 集成测试
- [ ] E2E 测试

**目标**: 完善所有测试覆盖

---

## 🎯 验收标准

### 测试完整性

- ✅ 所有 63 个测试方法实现
- ✅ 测试通过率达到 100%
- ✅ Views 层覆盖率达到 70%+

### 代码质量

- ✅ 所有测试遵循 AAA 模式
- ✅ 使用 Mock 隔离 ViewModel
- ✅ 测试命名清晰明确
- ✅ 包含边界条件测试

### 文档完善

- ✅ 测试文档完整
- ✅ 测试用例说明清晰
- ✅ Mock 对象文档齐全

---

## 📝 测试最佳实践

### 1. 测试独立性

每个测试应该独立运行，不依赖其他测试：

```cangjie
@Test
public func testFeatureA(): Unit {
    // Arrange
    let page = createNewPage()  // 每次创建新实例

    // Act & Assert
    // ...
}
```

### 2. Mock ViewModel

使用 Mock ViewModel 隔离业务逻辑：

```cangjie
class MockAuthViewModel {
    public func setLoginResult(result: Result<AuthToken>): Unit {
        this.mockResult = result
    }
}
```

### 3. 状态验证

验证 UI 状态变化：

```cangjie
@Test
public func testLoadingState(): Unit {
    Assert.assertFalse(page.isLoading())
    page.onLoginStart()
    Assert.assertTrue(page.isLoading())
}
```

### 4. 用户交互模拟

模拟用户交互行为：

```cangjie
@Test
public func testButtonClick(): Unit {
    page.onEmailChanged("test@example.com")
    page.onPasswordChanged("password123")
    page.onLoginClick()

    Assert.assertTrue(page.isNavigatingToHome())
}
```

### 5. 错误场景测试

测试错误处理：

```cangjie
@Test
public func testNetworkError(): Unit {
    mockViewModel.setNetworkError()
    page.onLoginClick()

    Assert.assertTrue(page.isErrorVisible())
    Assert.assertEquals("网络错误，请重试", page.getErrorMessage())
}
```

---

## 🔄 下一步行动

### 立即执行

1. **创建测试文件**
   - 创建 `entry/src/test/cj/views/` 目录
   - 创建 `LoginPageTest.cj`

2. **实现基础测试**
   - 实现 LoginPage 的 12 个测试方法
   - 运行并验证测试通过

3. **编写 Mock 类**
   - 创建 MockAuthViewModel
   - 创建 MockResumeViewModel

### 本周完成

- [ ] LoginPage 测试
- [ ] RegisterPage 测试
- [ ] HomePage 测试

### 下周规划

- [ ] ResumeEditorPage 测试
- [ ] TemplateSelectPage 测试
- [ ] ProfilePage 测试

---

## 📈 预期成果

### 测试覆盖提升

```
当前测试覆盖:
Utils: 90% ███████████████████████
Services: 50% ██████████░░░░░░░░░░░
Models: 80% ████████████████░░░░░░
ViewModels: 60% ████████████░░░░░░░
Views: 0% ░░░░░░░░░░░░░░░░░░░░░░
────────────────────────────────
总体: 55% ████████████░░░░░░░░░░

完成 Views 测试后:
Utils: 90% ███████████████████████
Services: 50% ██████████░░░░░░░░░░░
Models: 80% ████████████████░░░░░░
ViewModels: 60% ████████████░░░░░░░
Views: 70% ████████████████░░░░░░
────────────────────────────────
总体: 70% ████████████████░░░░░░
```

### 项目质量提升

- **测试方法**: 255 → 318 (+63)
- **测试代码**: 5,146 → ~6,500 行
- **测试覆盖率**: 55% → 70%
- **Views 层覆盖**: 0% → 70%

---

**文档维护**: 本文档应随测试开发进度持续更新

**责任人**: 鸿蒙开发工程师
**审核人**: 技术负责人
**更新频率**: 每周更新进度
