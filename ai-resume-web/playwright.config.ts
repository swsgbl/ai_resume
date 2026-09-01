import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: false, // 禁用并行运行以确保服务器稳定
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1, // 增加重试次数
  workers: 1, // 单个worker避免并发问题
  reporter: [['html', { outputFolder: 'playwright-report' }], ['line']],
  timeout: 120000, // 增加单个测试超时时间到120秒
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
    actionTimeout: 30000, // 操作超时30秒
    navigationTimeout: 120000, // 导航超时120秒
    // 模拟真人操作设置
    launchOptions: {
      slowMo: 50, // 轻微延迟模拟真人操作
    },
  },

  // 使用现有的开发服务器，不启动新服务器
  // 本地已有服务器时复用，CI 中由 Playwright 托管并自动清理
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: true,
    timeout: 60000,
  },

  projects: [
    // 桌面端测试 - 主要测试目标
    {
      name: 'chromium-desktop',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },
    // 移动端模拟测试
    {
      name: 'mobile-iphone',
      use: {
        ...devices['iPhone 12'],
      },
    },
    // Android 设备模拟
    {
      name: 'mobile-android',
      use: {
        ...devices['Pixel 5'],
      },
    },
  ],
});
