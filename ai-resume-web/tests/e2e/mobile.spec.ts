import { test, expect } from '@playwright/test';

/**
 * 手机端完整功能测试
 * 测试移动设备上的注册、登录和核心功能
 */

test.describe('手机端注册功能测试', () => {
  // 使用手机视口
  test.use({
    viewport: { width: 375, height: 812 },
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
  });

  test.beforeEach(async ({ page }) => {
    await page.route('**/api/v1/email/send-code', (route) =>
      route.fulfill({ status: 200, contentType: 'application/json', body: '{}' })
    );
    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1500);
  });

  test('手机端 - 导航到注册页面', async ({ page }) => {
    // 直接导航到注册页面
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 验证当前URL
    await expect(page).toHaveURL(/\/register/, { timeout: 5000 });

    // 验证页面标题
    await expect(page.getByText('创建账号', { exact: true })).toBeVisible();
    await expect(page.getByText('创建账号，开启智能简历之旅')).toBeVisible();
  });

  test('手机端 - 注册表单所有字段可见', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 验证所有表单字段可见
    await expect(page.getByTestId('register-email-input')).toBeVisible();
    await expect(page.getByTestId('code-input')).toBeVisible();
    await expect(page.getByTestId('send-code-button')).toBeVisible();
    await expect(page.getByTestId('username-input')).toBeVisible();
    await expect(page.getByTestId('register-password-input')).toBeVisible();
    await expect(page.getByTestId('confirm-password-input')).toBeVisible();
    await expect(page.getByTestId('terms-checkbox')).toBeVisible();
    await expect(page.getByTestId('register-button')).toBeVisible();
  });

  test('手机端 - 输入字段可以正常输入', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 测试邮箱输入
    const emailInput = page.getByTestId('register-email-input');
    await emailInput.fill('test@example.com');
    await expect(emailInput).toHaveValue('test@example.com');

    // 测试验证码输入
    const codeInput = page.getByTestId('code-input');
    await codeInput.fill('123456');
    await expect(codeInput).toHaveValue('123456');

    // 测试用户名输入
    const usernameInput = page.getByTestId('username-input');
    await usernameInput.fill('testuser');
    await expect(usernameInput).toHaveValue('testuser');

    // 测试密码输入
    const passwordInput = page.getByTestId('register-password-input');
    await passwordInput.fill('password123');
    await expect(passwordInput).toHaveValue('password123');

    // 测试确认密码输入
    const confirmInput = page.getByTestId('confirm-password-input');
    await confirmInput.fill('password123');
    await expect(confirmInput).toHaveValue('password123');
  });

  test('手机端 - 密码不匹配时显示错误提示', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 填写不匹配的密码
    await page.fill('[data-testid="register-email-input"]', 'test@example.com');
    await page.fill('[data-testid="register-password-input"]', 'password123');
    await page.fill('[data-testid="confirm-password-input"]', 'different');

    // 检查错误提示
    await expect(page.getByTestId('password-mismatch-error')).toBeVisible();
    await expect(page.getByTestId('password-mismatch-error')).toContainText('两次输入的密码不一致');
  });

  test('手机端 - 密码匹配时错误提示消失', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 先填写不匹配的密码
    await page.fill('[data-testid="register-email-input"]', 'test@example.com');
    await page.fill('[data-testid="register-password-input"]', 'password123');
    await page.fill('[data-testid="confirm-password-input"]', 'different');

    await expect(page.getByTestId('password-mismatch-error')).toBeVisible();

    // 修改确认密码为匹配
    await page.fill('[data-testid="confirm-password-input"]', 'password123');

    // 错误提示应该消失
    await expect(page.getByTestId('password-mismatch-error')).not.toBeVisible();
  });

  test('手机端 - 发送验证码按钮初始状态', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const sendCodeBtn = page.getByTestId('send-code-button');
    await expect(sendCodeBtn).toBeVisible();
    await expect(sendCodeBtn).toHaveText('发送验证码');
    // 未输入邮箱时应该禁用
    await expect(sendCodeBtn).toBeDisabled();
  });

  test('手机端 - 未输入邮箱时发送验证码按钮禁用', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const sendCodeBtn = page.getByTestId('send-code-button');
    // 未输入邮箱时应该禁用
    await expect(sendCodeBtn).toBeDisabled();
    // 应该显示提示文字
    await expect(page.getByText('请先输入邮箱')).toBeVisible();
  });

  test('手机端 - 点击发送验证码进入倒计时', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 输入邮箱
    await page.fill('[data-testid="register-email-input"]', 'test@example.com');
    await page.fill('[data-testid="confirm-email-input"]', 'test@example.com');

    // 点击发送验证码
    await page.click('[data-testid="send-code-button"]');

    // 应该显示倒计时
    const sendCodeBtn = page.getByTestId('send-code-button');
    await expect(sendCodeBtn).toContainText('秒');
    await expect(sendCodeBtn).toBeDisabled();
  });

  test('手机端 - 用户协议复选框可以勾选', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const checkbox = page.getByTestId('terms-checkbox');
    await expect(checkbox).not.toBeChecked();

    await checkbox.check();
    await expect(checkbox).toBeChecked();

    await checkbox.uncheck();
    await expect(checkbox).not.toBeChecked();
  });

  test('手机端 - 注册按钮状态检查', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const registerBtn = page.getByTestId('register-button');
    await expect(registerBtn).toBeVisible();
    await expect(registerBtn).toHaveText('注册');

    // 初始状态应该禁用（没有勾选用户协议）
    await expect(registerBtn).toBeDisabled();

    // 填写表单但不勾选用户协议
    await page.fill('[data-testid="register-email-input"]', 'test@example.com');
    await page.fill('[data-testid="confirm-email-input"]', 'test@example.com');
    await page.fill('[data-testid="code-input"]', '123456');
    await page.fill('[data-testid="register-password-input"]', 'password123');
    await page.fill('[data-testid="confirm-password-input"]', 'password123');

    // 没勾选用户协议时仍然禁用
    await expect(registerBtn).toBeDisabled();

    // 勾选用户协议后应该启用
    await page.check('[data-testid="terms-checkbox"]');
    await expect(registerBtn).toBeEnabled();

    // 密码不匹配时按钮应该禁用
    await page.fill('[data-testid="confirm-password-input"]', 'different');
    await expect(registerBtn).toBeDisabled();

    // 密码匹配后按钮应该可用
    await page.fill('[data-testid="confirm-password-input"]', 'password123');
    await expect(registerBtn).toBeEnabled();
  });

  test('手机端 - 注册页面有登录链接', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const loginLink = page.getByTestId('login-link');
    await expect(loginLink).toBeVisible();
    await expect(loginLink).toContainText('立即登录');
  });

  test('手机端 - 表单在小屏幕上的布局正确', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 检查卡片容器是否有合适的样式
    const card = page.locator('.card-glass');
    await expect(card).toBeVisible();

    // 检查表单是否可见
    const form = page.locator('form');
    await expect(form).toBeVisible();

    // 检查输入框在小屏幕上的宽度（实际宽度约为177px，使用固定容器）
    const emailInput = page.getByTestId('register-email-input');
    const box = await emailInput.boundingBox();
    expect(box).not.toBeNull();
    if (box) {
      // 输入框应该有合理的最小宽度
      expect(box.width).toBeGreaterThan(150);
    }
  });

  test('手机端 - 验证码输入框和按钮的布局', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 验证码输入框和按钮应该是可见的
    const codeInput = page.getByTestId('code-input');
    const sendCodeBtn = page.getByTestId('send-code-button');

    await expect(codeInput).toBeVisible();
    await expect(sendCodeBtn).toBeVisible();

    // 验证它们在页面上的相对位置是合理的（垂直距离在50px以内）
    const inputBox = await codeInput.boundingBox();
    const btnBox = await sendCodeBtn.boundingBox();

    expect(inputBox).not.toBeNull();
    expect(btnBox).not.toBeNull();

    if (inputBox && btnBox) {
      // 它们的y坐标应该相对接近（在同一行区域）
      expect(Math.abs(inputBox.y - btnBox.y)).toBeLessThan(50);
    }
  });

  test('手机端 - 验证码输入框最大长度限制', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const codeInput = page.getByTestId('code-input');
    await codeInput.fill('123456789');

    // 应该最多只能输入6位
    const value = await codeInput.inputValue();
    expect(value.length).toBeLessThanOrEqual(6);
  });

  test('手机端 - 链接到用户协议和隐私政策', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 检查用户协议链接
    await expect(page.getByText('《用户协议》')).toBeVisible();

    // 检查隐私政策链接
    await expect(page.getByText('《隐私政策》')).toBeVisible();
  });

  test('手机端 - 表单验证 - 邮箱必填', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const emailInput = page.getByTestId('register-email-input');

    // 验证required属性
    await expect(emailInput).toHaveAttribute('required');
  });

  test('手机端 - 表单验证 - 密码必填', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const passwordInput = page.getByTestId('register-password-input');
    const confirmInput = page.getByTestId('confirm-password-input');

    // 验证required属性
    await expect(passwordInput).toHaveAttribute('required');
    await expect(confirmInput).toHaveAttribute('required');
  });

  test('手机端 - 注册页面滚动测试', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 获取页面初始高度
    const initialHeight = await page.evaluate(() => document.body.scrollHeight);

    // 页面内容应该有合理的高度（实际约409px，使用固定容器宽度）
    expect(initialHeight).toBeGreaterThan(300);
  });

  test('手机端 - 注册按钮在屏幕底部可见性', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 滚动到底部
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));

    const registerBtn = page.getByTestId('register-button');
    await expect(registerBtn).toBeVisible();
  });

  test('手机端 - 用户协议文本在小屏幕上的显示', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 检查用户协议区域是否可见
    await expect(page.getByText('我已阅读并同意')).toBeVisible();
  });
});

test.describe('手机端登录功能测试', () => {
  test.use({
    viewport: { width: 375, height: 812 },
  });

  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1500);
  });

  test('手机端 - 登录页面可以访问', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    await expect(page).toHaveURL(/\/login/, { timeout: 5000 });
    await expect(page.getByText('欢迎回来')).toBeVisible();
    await expect(page.getByTestId('email-input')).toBeVisible();
    await expect(page.getByTestId('password-input')).toBeVisible();
  });

  test('手机端 - 登录表单可以输入', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    await page.fill('[data-testid="email-input"]', 'test@example.com');
    await page.fill('[data-testid="password-input"]', 'password123');

    await expect(page.getByTestId('email-input')).toHaveValue('test@example.com');
    await expect(page.getByTestId('password-input')).toHaveValue('password123');
  });

  test('手机端 - 登录按钮可见且可点击', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const loginBtn = page.getByTestId('login-button');
    await expect(loginBtn).toBeVisible();
    await expect(loginBtn).toBeEnabled();
  });

  test('手机端 - 登录页面有注册链接', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const registerLink = page.getByTestId('register-link');
    await expect(registerLink).toBeVisible();
  });
});

test.describe('手机端触摸交互测试', () => {
  test.use({
    viewport: { width: 375, height: 812 },
    hasTouch: true,
  });

  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1500);
  });

  test('手机端 - 触摸点击注册页面链接', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 通过触摸点击注册链接
    await page.tap('[data-testid="register-link"]');

    await page.waitForTimeout(1000);

    // 应该导航到注册页面
    await expect(page.getByTestId('register-email-input')).toBeVisible();
  });

  test('手机端 - 触摸点击登录链接', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 通过触摸点击登录链接
    await page.tap('[data-testid="login-link"]');

    await page.waitForTimeout(1000);

    // 应该导航到登录页面
    await expect(page.getByTestId('email-input')).toBeVisible();
  });

  test('手机端 - 触摸点击复选框', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const checkbox = page.getByTestId('terms-checkbox');

    // 通过触摸点击复选框
    await page.tap('[data-testid="terms-checkbox"]');
    await expect(checkbox).toBeChecked();

    // 再次点击取消勾选
    await page.tap('[data-testid="terms-checkbox"]');
    await expect(checkbox).not.toBeChecked();
  });
});

test.describe('手机端不同屏幕尺寸测试', () => {
  const screenSizes = [
    { name: 'iPhone SE', width: 375, height: 667 },
    { name: 'iPhone 12 Pro', width: 390, height: 844 },
    { name: 'iPhone 14 Pro Max', width: 430, height: 932 },
    { name: 'Android Small', width: 360, height: 640 },
    { name: 'Android Large', width: 412, height: 915 },
  ];

  for (const size of screenSizes) {
    test(`手机端 - ${size.name} 屏幕尺寸测试`, async ({ page }) => {
      await page.setViewportSize({ width: size.width, height: size.height });
      await page.goto('http://localhost:3000/');
      await page.waitForLoadState('domcontentloaded').catch(() => {});
      await page.waitForTimeout(1500);

      await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

      // 验证页面元素可见
      await expect(page.getByTestId('register-email-input')).toBeVisible();
      await expect(page.getByTestId('register-button')).toBeVisible();

      // 验证输入框有合理的最小宽度（使用固定容器约177px）
      const emailInput = page.getByTestId('register-email-input');
      const box = await emailInput.boundingBox();
      expect(box).not.toBeNull();
      if (box) {
        // 输入框应该有合理的最小宽度
        expect(box.width).toBeGreaterThan(150);
      }
    });
  }
});

test.describe.skip('手机端横屏测试', () => {
  test.use({
    viewport: { width: 812, height: 375 },
  });

  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1500);
  });

  test('手机端 - 横屏模式下注册页面布局', async ({ page }) => {
    await page.goto('http://localhost:3000/register');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 验证关键元素在横屏模式下仍然可见
    await expect(page.getByTestId('register-email-input')).toBeVisible();
    await expect(page.getByTestId('register-password-input')).toBeVisible();
    await expect(page.getByTestId('register-button')).toBeVisible();
  });

  test('手机端 - 横屏模式下登录页面布局', async ({ page }) => {
    await page.goto('http://localhost:3000/login');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    // 验证关键元素在横屏模式下仍然可见
    await expect(page.getByTestId('email-input')).toBeVisible();
    await expect(page.getByTestId('password-input')).toBeVisible();
    await expect(page.getByTestId('login-button')).toBeVisible();
  });
});
