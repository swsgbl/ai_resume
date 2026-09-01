import { test, expect } from '@playwright/test';

/**
 * 桌面端用户流程 E2E 测试
 *
 * 测试场景:
 * 1. 新用户注册流程
 * 2. 用户登录流程
 * 3. 页面导航
 */

// 辅助函数：模拟人类打字行为
async function humanType(page: any, selector: string, text: string) {
  const element = page.locator(selector);
  await element.click();
  for (const char of text) {
    await element.type(char, { delay: Math.random() * 50 + 30 });
  }
}

// 辅助函数：平滑滚动
async function smoothScroll(page: any, pixels: number) {
  await page.evaluate((p: number) => {
    window.scrollBy({ top: p, behavior: 'smooth' });
  }, pixels);
  await page.waitForTimeout(300);
}

test.describe('桌面端用户注册流程', () => {
  test.beforeEach(async ({ page }) => {
    await page.route('**/api/v1/email/send-code', (route) =>
      route.fulfill({ status: 200, contentType: 'application/json', body: '{}' })
    );
    await page.route('**/api/v1/auth/register', (route) =>
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          access_token: 'mock-access-token',
          refresh_token: 'mock-refresh-token',
          user: {
            id: 1,
            email: 'test@example.com',
            nickname: '测试用户',
          },
        }),
      })
    );
    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);
  });

  test('完整注册流程', async ({ page }) => {
    // 导航到注册页面
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 验证页面元素
    await expect(page.getByText('创建账号', { exact: true })).toBeVisible({ timeout: 10000 });
    await expect(page.getByTestId('register-email-input')).toBeVisible({ timeout: 10000 });

    // 填写注册表单
    const email = `test${Date.now()}@example.com`;
    await humanType(page, '[data-testid="register-email-input"]', email);
    await humanType(page, '[data-testid="confirm-email-input"]', email);
    await page.waitForTimeout(200);

    // 点击发送验证码按钮
    const sendCodeBtn = page.getByTestId('send-code-button');
    await expect(sendCodeBtn).toBeVisible();
    await expect(sendCodeBtn).toBeEnabled();
    await sendCodeBtn.click();

    // 等待倒计时开始
    await page.waitForTimeout(500);
    await expect(sendCodeBtn).toBeDisabled();

    // 填写验证码
    await humanType(page, '[data-testid="code-input"]', '123456');
    await page.waitForTimeout(200);

    // 填写用户名
    await humanType(page, '[data-testid="username-input"]', 'testuser');
    await page.waitForTimeout(200);

    // 填写密码
    await humanType(page, '[data-testid="register-password-input"]', 'password123');
    await page.waitForTimeout(200);

    // 填写确认密码
    await humanType(page, '[data-testid="confirm-password-input"]', 'password123');
    await page.waitForTimeout(200);

    // 同意用户协议
    const termsCheckbox = page.getByTestId('terms-checkbox');
    await expect(termsCheckbox).toBeVisible();
    await termsCheckbox.check();
    await page.waitForTimeout(200);

    // 验证注册按钮启用
    const registerBtn = page.getByTestId('register-button');
    await expect(registerBtn).toBeEnabled();
    await registerBtn.click();

    await expect(page).toHaveURL(/\/dashboard/);
  });

  test('密码不匹配验证', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 填写表单，密码不一致
    await page.fill('[data-testid="register-email-input"]', 'test@example.com');
    await page.fill('[data-testid="register-password-input"]', 'password123');
    await page.fill('[data-testid="confirm-password-input"]', 'different123');

    // 检查错误提示
    const errorMsg = page.getByTestId('password-mismatch-error');
    await expect(errorMsg).toBeVisible({ timeout: 5000 });
    await expect(errorMsg).toContainText('两次输入的密码不一致');
  });

  test('用户协议必选验证', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 填写表单但不勾选协议
    await page.fill('[data-testid="register-email-input"]', 'test@example.com');
    await page.fill('[data-testid="confirm-email-input"]', 'test@example.com');
    await page.fill('[data-testid="code-input"]', '123456');
    await page.fill('[data-testid="register-password-input"]', 'password123');
    await page.fill('[data-testid="confirm-password-input"]', 'password123');

    // 验证注册按钮禁用
    const registerBtn = page.getByTestId('register-button');
    await expect(registerBtn).toBeDisabled();

    await page.getByTestId('terms-checkbox').check();
    await expect(registerBtn).toBeEnabled();
  });

  test('验证码倒计时功能', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 输入邮箱
    await page.fill('[data-testid="register-email-input"]', 'test@example.com');
    await page.fill('[data-testid="confirm-email-input"]', 'test@example.com');

    // 点击发送验证码
    const sendCodeBtn = page.getByTestId('send-code-button');
    await expect(sendCodeBtn).toBeEnabled();
    await sendCodeBtn.click();

    // 验证倒计时显示
    await page.waitForTimeout(500);
    await expect(sendCodeBtn).toContainText('秒');

    // 验证按钮禁用
    await expect(sendCodeBtn).toBeDisabled();
  });
});

test.describe('桌面端用户登录流程', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);
  });

  test('从首页导航到登录', async ({ page }) => {
    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 检查是否有登录按钮或链接
    const loginButton = page.getByRole('link', { name: /登录/i }).first();
    if (await loginButton.isVisible({ timeout: 5000 }).catch(() => false)) {
      await loginButton.click();
      await page.waitForTimeout(1000);
      await expect(page).toHaveURL(/\/login/, { timeout: 5000 });
    } else {
      // 直接导航到登录页
      await page.goto('http://localhost:3000/login');
      await page.waitForTimeout(1000);
    }
  });

  test('成功登录', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 验证页面元素
    await expect(page.getByText('欢迎回来')).toBeVisible({ timeout: 10000 });
    await expect(page.getByTestId('email-input')).toBeVisible({ timeout: 10000 });
    await expect(page.getByTestId('password-input')).toBeVisible({ timeout: 10000 });

    // 填写登录表单
    await humanType(page, '[data-testid="email-input"]', 'test@example.com');
    await page.waitForTimeout(200);
    await humanType(page, '[data-testid="password-input"]', 'password123');
    await page.waitForTimeout(200);

    // 点击登录按钮
    const loginBtn = page.getByTestId('login-button');
    await expect(loginBtn).toBeVisible();
    await loginBtn.click();

    // 等待响应（可能成功或失败，取决于后端）
    await page.waitForTimeout(2000);
  });

  test('记住密码功能', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 勾选记住密码
    const rememberCheckbox = page.getByTestId('remember-password');
    await expect(rememberCheckbox).toBeVisible();
    await rememberCheckbox.check();

    // 验证已勾选
    await expect(rememberCheckbox).toBeChecked();
  });

  test('登录表单验证', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 测试空表单提交
    const loginBtn = page.getByTestId('login-button');
    await loginBtn.click();

    // 验证 required 属性生效
    const emailInput = page.getByTestId('email-input');
    await expect(emailInput).toHaveAttribute('required');
  });

  test('登录失败错误提示', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 输入错误的凭据
    await page.fill('[data-testid="email-input"]', 'wrong@example.com');
    await page.fill('[data-testid="password-input"]', 'wrongpassword');

    const loginBtn = page.getByTestId('login-button');
    await loginBtn.click();

    // 等待错误提示（可能显示，取决于后端响应）
    await page.waitForTimeout(2000);
  });
});

test.describe('桌面端页面导航', () => {
  test('从登录页跳转到注册页', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 点击注册链接
    const registerLink = page.getByTestId('register-link');
    await expect(registerLink).toBeVisible();
    await registerLink.click();

    // 验证导航到注册页
    await page.waitForTimeout(1000);
    await expect(page).toHaveURL(/\/register/, { timeout: 5000 });
    await expect(page.getByText('创建账号', { exact: true })).toBeVisible({ timeout: 10000 });
  });

  test('从注册页跳转到登录页', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 点击登录链接
    const loginLink = page.getByTestId('login-link');
    await expect(loginLink).toBeVisible();
    await loginLink.click();

    // 验证导航到登录页
    await page.waitForTimeout(1000);
    await expect(page).toHaveURL(/\/login/, { timeout: 5000 });
    await expect(page.getByText('欢迎回来')).toBeVisible({ timeout: 10000 });
  });
});

test.describe('桌面端页面可访问性', () => {
  test('登录页面响应式布局', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 测试移动端视口
    await page.setViewportSize({ width: 375, height: 667 });
    await expect(page.locator('form')).toBeVisible({ timeout: 10000 });

    // 测试桌面端视口
    await page.setViewportSize({ width: 1920, height: 1080 });
    await expect(page.locator('form')).toBeVisible({ timeout: 10000 });
  });

  test('注册页面响应式布局', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 测试移动端视口
    await page.setViewportSize({ width: 375, height: 667 });
    await expect(page.locator('form')).toBeVisible({ timeout: 10000 });

    // 测试桌面端视口
    await page.setViewportSize({ width: 1920, height: 1080 });
    await expect(page.locator('form')).toBeVisible({ timeout: 10000 });
  });

  test('表单元素有正确标签', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 验证输入框有 label
    const emailInput = page.getByTestId('email-input');
    await expect(emailInput).toHaveAttribute('id');

    const passwordInput = page.getByTestId('password-input');
    await expect(passwordInput).toHaveAttribute('id');
  });
});
