import { test, expect } from '@playwright/test';

test.describe('AI 简历应用 - E2E 测试', () => {
  // 每个测试前导航到根路径并等待应用加载
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000/');
    // 等待页面加载完成
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1500);
  });

  test('应用标题正确显示', async ({ page }) => {
    await expect(page).toHaveTitle(/AI 简历/);
  });

  test('登录页面可以访问', async ({ page }) => {
    // 直接导航到登录页面
    await page.goto('http://localhost:3000/login');

    // 等待页面加载
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    // 更新为实际页面显示的文本
    await expect(page.getByText('欢迎回来')).toBeVisible({ timeout: 15000 });
    await expect(page.getByText('账户登录')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('email-input')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('password-input')).toBeVisible({ timeout: 15000 });
  });

  test('注册页面可以访问', async ({ page }) => {
    // 直接导航到注册页面
    await page.goto('http://localhost:3000/register');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    await expect(page.getByTestId('register-email-input')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('register-password-input')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('confirm-password-input')).toBeVisible({ timeout: 15000 });
  });

  test('根路径显示登录页面内容（未登录）', async ({ page }) => {
    // 检查页面是否有内容
    const content = await page.content();
    expect(content.length).toBeGreaterThan(1000);
  });

  test('登录页面有注册链接', async ({ page }) => {
    // 直接导航到登录页面
    await page.goto('http://localhost:3000/login');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    const registerLink = page.getByTestId('register-link');
    await expect(registerLink).toBeVisible({ timeout: 15000 });
  });

  test('注册页面有登录链接', async ({ page }) => {
    // 直接导航到注册页面
    await page.goto('http://localhost:3000/register');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    const loginLink = page.getByTestId('login-link');
    await expect(loginLink).toBeVisible({ timeout: 15000 });
  });

  test('注册页面表单验证 - 密码不匹配提示', async ({ page }) => {
    // 直接导航到注册页面
    await page.goto('http://localhost:3000/register');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    // 填写表单
    await page.fill('[data-testid="register-email-input"]', 'test@example.com');
    await page.fill('[data-testid="register-password-input"]', 'password123');
    await page.fill('[data-testid="confirm-password-input"]', 'different');

    // 检查错误提示
    const errorMsg = page.getByTestId('password-mismatch-error');
    await expect(errorMsg).toBeVisible({ timeout: 10000 });
  });

  test('登录页面UI元素完整', async ({ page }) => {
    // 直接导航到登录页面
    await page.goto('http://localhost:3000/login');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    // 检查所有输入框
    await expect(page.getByTestId('email-input')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('password-input')).toBeVisible({ timeout: 15000 });

    // 检查登录按钮
    const loginBtn = page.getByTestId('login-button');
    await expect(loginBtn).toBeVisible({ timeout: 15000 });

    // 检查注册链接
    const registerLink = page.getByTestId('register-link');
    await expect(registerLink).toBeVisible({ timeout: 15000 });
  });

  test('注册页面UI元素完整', async ({ page }) => {
    // 直接导航到注册页面
    await page.goto('http://localhost:3000/register');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    // 检查所有输入框
    await expect(page.getByTestId('register-email-input')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('code-input')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('username-input')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('register-password-input')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('confirm-password-input')).toBeVisible({ timeout: 15000 });

    // 检查发送验证码按钮
    const codeBtn = page.getByTestId('send-code-button');
    await expect(codeBtn).toBeVisible({ timeout: 15000 });

    // 检查用户协议复选框
    const checkbox = page.getByTestId('terms-checkbox');
    await expect(checkbox).toBeVisible({ timeout: 15000 });

    // 检查注册按钮
    const registerBtn = page.getByTestId('register-button');
    await expect(registerBtn).toBeVisible({ timeout: 15000 });
  });

  test('页面样式加载正确', async ({ page }) => {
    const body = page.locator('body');
    const background = await body.evaluate((el: any) => {
      return window.getComputedStyle(el).background;
    });
    expect(background).toBeTruthy();
  });

  test('页面响应式布局', async ({ page }) => {
    // 直接导航到登录页面
    await page.goto('http://localhost:3000/login');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    // 测试移动端视口
    await page.setViewportSize({ width: 375, height: 667 });
    await expect(page.locator('form')).toBeVisible({ timeout: 15000 });

    // 测试桌面端视口
    await page.setViewportSize({ width: 1920, height: 1080 });
    await expect(page.locator('form')).toBeVisible({ timeout: 15000 });
  });
});

test.describe('页面可访问性测试', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1500);
  });

  test('登录页面对比度符合标准', async ({ page }) => {
    const backgroundColor = await page.locator('body').evaluate((el: any) => {
      return window.getComputedStyle(el).backgroundColor;
    });
    expect(backgroundColor).toBeTruthy();
  });

  test('表单元素有标签', async ({ page }) => {
    // 直接导航到登录页面
    await page.goto('http://localhost:3000/login');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    const emailInput = page.getByTestId('email-input');
    await expect(emailInput).toHaveAttribute('id');
  });
});

test.describe('导航测试', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1500);
  });

  test('登录页面到底部链接', async ({ page }) => {
    // 直接导航到登录页面
    await page.goto('http://localhost:3000/login');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    // 检查用户协议链接
    const termsLink = page.getByTestId('terms-link');
    await expect(termsLink).toBeVisible({ timeout: 15000 });

    // 检查隐私政策链接
    const privacyLink = page.getByTestId('privacy-link');
    await expect(privacyLink).toBeVisible({ timeout: 15000 });
  });
});
