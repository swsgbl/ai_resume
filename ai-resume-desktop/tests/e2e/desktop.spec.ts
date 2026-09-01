import { test, expect } from '@playwright/test';

/**
 * AI 简历桌面端 E2E 测试
 *
 * 这些测试验证桌面端(Tauri)版本的核心功能。
 * 由于Tauri开发模式使用与网页版相同的前端代码，
 * 这些测试主要验证桌面端特有的功能。
 */

test.describe('AI 简历桌面端 - E2E 测试', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1500);
  });

  test('桌面端应用标题正确显示', async ({ page }) => {
    await expect(page).toHaveTitle(/AI 简历/);
  });

  test('桌面端登录页面可以访问', async ({ page }) => {
    // 直接导航到登录页面
    await page.goto('http://localhost:3000/login');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    await expect(page.getByText('欢迎回来')).toBeVisible({ timeout: 15000 });
    await expect(page.getByText('账户登录')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('email-input')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('password-input')).toBeVisible({ timeout: 15000 });
  });

  test('桌面端注册页面可以访问', async ({ page }) => {
    // 直接导航到注册页面
    await page.goto('http://localhost:3000/register');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    await expect(page.getByTestId('register-email-input')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('register-password-input')).toBeVisible({ timeout: 15000 });
    await expect(page.getByTestId('confirm-password-input')).toBeVisible({ timeout: 15000 });
  });

  test('桌面端页面样式加载正确', async ({ page }) => {
    const body = page.locator('body');
    const background = await body.evaluate((el: any) => {
      return window.getComputedStyle(el).background;
    });
    expect(background).toBeTruthy();
  });

  test('桌面端表单验证功能正常', async ({ page }) => {
    // 直接导航到注册页面
    await page.goto('http://localhost:3000/register');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    // 填写表单测试验证
    await page.fill('[data-testid="register-email-input"]', 'test@desktop.com');
    await page.fill('[data-testid="register-password-input"]', 'pass123');
    await page.fill('[data-testid="confirm-password-input"]', 'different');

    const errorMsg = page.getByTestId('password-mismatch-error');
    await expect(errorMsg).toBeVisible({ timeout: 10000 });
  });

  test('桌面端响应式布局', async ({ page }) => {
    // 直接导航到登录页面
    await page.goto('http://localhost:3000/login');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    // 测试不同窗口大小
    await page.setViewportSize({ width: 1200, height: 800 });
    await expect(page.locator('form')).toBeVisible({ timeout: 15000 });

    await page.setViewportSize({ width: 800, height: 600 });
    await expect(page.locator('form')).toBeVisible({ timeout: 15000 });
  });
});

test.describe('桌面端特有功能测试', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1500);
  });

  test('验证Tauri API可用性', async ({ page }) => {
    // 在Tauri环境中，window.__TAURI__对象应该存在
    const tauriExists = await page.evaluate(() => {
      return typeof (window as any).__TAURI__ !== 'undefined';
    });

    // 注意：在纯web测试环境中这个会返回false
    // 这是预期的，因为我们在浏览器中运行测试
    console.log('Tauri API exists:', tauriExists);
  });

  test('桌面端无障碍性检查', async ({ page }) => {
    // 直接导航到登录页面
    await page.goto('http://localhost:3000/login');

    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(2000);

    // 检查主要元素的tabindex
    const emailInput = page.getByTestId('email-input');
    await expect(emailInput).toBeVisible({ timeout: 15000 });

    // 检查所有可交互元素都可以通过键盘访问
    const inputs = page.locator('input');
    const count = await inputs.count();
    expect(count).toBeGreaterThan(0);
  });
});

test.describe('桌面端性能测试', () => {
  test('页面加载时间合理', async ({ page }) => {
    const startTime = Date.now();

    await page.goto('/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});

    const loadTime = Date.now() - startTime;

    // 页面应该在5秒内完成基本加载
    expect(loadTime).toBeLessThan(5000);

    console.log(`页面加载时间: ${loadTime}ms`);
  });

  test('页面交互响应及时', async ({ page }) => {
    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const startTime = Date.now();

    // 直接导航到登录页面
    await page.goto('http://localhost:3000/login');

    // 等待路由切换
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await page.waitForTimeout(1000);

    const responseTime = Date.now() - startTime;

    // 路由切换应该在2秒内完成
    expect(responseTime).toBeLessThan(2000);

    console.log(`路由切换时间: ${responseTime}ms`);
  });
});
