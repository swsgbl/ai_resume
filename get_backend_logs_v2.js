const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const browser = await chromium.launch({
    headless: false,
    slowMo: 500
  });

  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 }
  });

  const page = await context.newPage();

  try {
    console.log('步骤1: 导航到Dokploy登录页面...');
    await page.goto('http://113.45.64.145:3000', {
      waitUntil: 'networkidle',
      timeout: 60000
    });

    console.log('步骤2: 填写登录凭据...');
    await page.fill('input[name="email"]', '641600780@qq.com');
    await page.fill('input[name="password"]', '353980swsgbo');
    await page.click('button[type="submit"]');

    console.log('步骤3: 等待登录完成...');
    await page.waitForLoadState('networkidle', { timeout: 30000 });
    console.log('登录完成，当前URL:', page.url());

    await page.screenshot({ path: 'step1-after-login.png' });

    console.log('步骤4: 查找并点击"AI智能体简历"项目...');
    const projectFound = await page.waitForSelector('text=AI智能体简历', { timeout: 15000 });
    if (projectFound) {
      await page.click('text=AI智能体简历');
      await page.waitForLoadState('networkidle', { timeout: 30000 });
      console.log('已进入项目页面');
    }

    await page.screenshot({ path: 'step2-project-page.png' });

    console.log('步骤5: 查找Backend服务...');
    // 尝试多种选择器
    const backendSelectors = [
      'text=Backend',
      '[data-service-name*="Backend"]',
      'a:has-text("Backend")',
      'div:has-text("Backend")'
    ];

    let backendClicked = false;
    for (const selector of backendSelectors) {
      try {
        const element = await page.$(selector);
        if (element) {
          console.log(`找到Backend服务: ${selector}`);
          await element.click();
          await page.waitForLoadState('networkidle', { timeout: 30000 });
          backendClicked = true;
          break;
        }
      } catch (e) {
        continue;
      }
    }

    if (!backendClicked) {
      console.log('无法找到Backend服务，尝试查找所有服务...');
      const allServices = await page.$$eval('a, div, button', elements =>
        elements.map(el => ({
          tag: el.tagName,
          text: el.textContent?.trim(),
          className: el.className
        }))
      );
      console.log('页面上的所有元素:', JSON.stringify(allServices.slice(0, 20), null, 2));
    }

    await page.screenshot({ path: 'step3-backend-service.png' });

    console.log('步骤6: 查找并点击日志标签...');
    // 等待页面稳定后查找日志相关内容
    await page.waitForTimeout(2000);

    const logsSelectors = [
      'text=Logs',
      'text=日志',
      'text=Console',
      '[data-testid="logs"]',
      'button:has-text("Logs")',
      'a:has-text("Logs")',
      'tab:has-text("Logs")'
    ];

    let logsClicked = false;
    for (const selector of logsSelectors) {
      try {
        const element = await page.$(selector);
        if (element) {
          console.log(`找到日志标签: ${selector}`);
          await element.click();
          await page.waitForTimeout(3000); // 等待日志加载
          logsClicked = true;
          break;
        }
      } catch (e) {
        continue;
      }
    }

    await page.screenshot({ path: 'step4-logs-page.png' });

    console.log('步骤7: 尝试多种方法提取日志内容...');

    // 方法1: 查找常见的日志容器
    const logsContainerSelectors = [
      'pre',
      'code',
      '[data-logs]',
      '.logs',
      '.console',
      '#logs',
      '.log-output',
      '[class*="log"]',
      '[class*="console"]',
      '[class*="output"]',
      'textarea',
      '[role="log"]',
      '[aria-label*="log" i]',
      '[aria-label*="console" i]'
    ];

    let logsFound = false;
    for (const selector of logsContainerSelectors) {
      try {
        const elements = await page.$$(selector);
        console.log(`找到${elements.length}个${selector}元素`);

        for (const element of elements) {
          const isVisible = await element.isVisible();
          if (isVisible) {
            const textContent = await element.textContent();
            const innerHTML = await element.innerHTML();

            console.log(`检查元素 ${selector}:`);
            console.log(`文本长度: ${textContent?.length || 0}`);
            console.log(`HTML长度: ${innerHTML?.length || 0}`);

            if (textContent && textContent.trim().length > 100) {
              console.log('=== 找到可能的日志内容 ===');
              console.log(textContent.substring(0, 500));

              // 保存到文件
              fs.writeFileSync(`backend_logs_${selector.replace(/[^a-zA-Z0-9]/g, '_')}.txt`, textContent);
              console.log(`已保存到: backend_logs_${selector.replace(/[^a-zA-Z0-9]/g, '_')}.txt`);
              logsFound = true;
              break;
            }
          }
        }

        if (logsFound) break;
      } catch (e) {
        console.log(`检查${selector}时出错:`, e.message);
        continue;
      }
    }

    // 方法2: 如果没有找到，尝试获取整个页面的文本
    if (!logsFound) {
      console.log('未找到特定的日志容器，尝试获取页面内容...');

      const pageText = await page.evaluate(() => {
        // 查找所有可能包含日志的元素
        const allElements = document.querySelectorAll('*');
        let logs = [];

        allElements.forEach(el => {
          const text = el.textContent;
          const className = el.className;
          const id = el.id;

          // 查找包含常见日志模式的元素
          if (text && (
            text.includes('ERROR') ||
            text.includes('error') ||
            text.includes('Exception') ||
            text.includes('Traceback') ||
            text.includes('Failed') ||
            text.includes('Starting') ||
            text.includes('Database') ||
            text.includes('Redis') ||
            text.includes('Connection')
          )) {
            logs.push({
              tagName: el.tagName,
              className: className,
              id: id,
              text: text.substring(0, 200) // 前200个字符
            });
          }
        });

        return logs;
      });

      console.log('页面中包含日志相关文本的元素:');
      console.log(JSON.stringify(pageText, null, 2));

      if (pageText.length > 0) {
        const fullText = pageText.map(item => item.text).join('\n\n');
        fs.writeFileSync('backend_logs_page_content.txt', fullText);
        console.log('已保存页面内容到: backend_logs_page_content.txt');
      }
    }

    // 方法3: 尝试滚动页面查看是否有懒加载的日志
    console.log('尝试滚动页面...');
    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });
    await page.waitForTimeout(2000);

    await page.screenshot({ path: 'step5-after-scroll.png' });

    // 方法4: 检查是否有iframe包含日志
    console.log('检查iframe...');
    const frames = page.frames();
    console.log(`找到${frames.length}个iframe`);

    for (const frame of frames) {
      try {
        const frameContent = await frame.content();
        if (frameContent && (
          frameContent.includes('ERROR') ||
          frameContent.includes('Exception') ||
          frameContent.includes('Traceback')
        )) {
          console.log('=== 在iframe中找到可能的日志 ===');
          fs.writeFileSync('backend_logs_iframe.txt', frameContent);
          console.log('已保存iframe内容到: backend_logs_iframe.txt');
          break;
        }
      } catch (e) {
        continue;
      }
    }

    // 方法5: 尝试访问Network日志
    console.log('检查网络请求...');
    page.on('response', async response => {
      const url = response.url();
      if (url.includes('log') || url.includes('api')) {
        console.log('发现API请求:', url);
        try {
          const contentType = response.headers()['content-type'];
          if (contentType && contentType.includes('application/json')) {
            const jsonData = await response.json();
            console.log('API响应数据:', JSON.stringify(jsonData, null, 2));
            fs.writeFileSync('backend_api_response.json', JSON.stringify(jsonData, null, 2));
          }
        } catch (e) {
          // 忽略非JSON响应
        }
      }
    });

    console.log('日志获取完成，保持浏览器打开以便进一步检查...');
    console.log('按Ctrl+C退出脚本');

    // 保持浏览器打开
    await new Promise(() => {});

  } catch (error) {
    console.error('发生错误:', error);
    await page.screenshot({ path: 'error-screenshot.png' });
  } finally {
    // await browser.close();
  }
})();