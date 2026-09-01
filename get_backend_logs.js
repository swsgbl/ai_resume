/**
 * 专门获取Backend服务容器日志的脚本
 */

const { chromium } = require('playwright');
const fs = require('fs');

// 配置信息
const DOKPLOY_URL = "http://113.45.64.145:3000";
const EMAIL = "641600780@qq.com";
const PASSWORD = "353980swsgbo";

const getTimestamp = () => {
    const now = new Date();
    return now.toISOString().replace(/[:.]/g, '-').slice(0, -5);
};

const takeScreenshot = async (page, name) => {
    const filename = `backend_logs_${name}_${getTimestamp()}.png`;
    await page.screenshot({ path: filename, fullPage: true });
    console.log(`📸 截图: ${filename}`);
    return filename;
};

const main = async () => {
    console.log("🚀 开始获取Backend容器日志...");

    const browser = await chromium.launch({
        headless: false,
        slowMo: 800,
    });

    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 }
    });

    const page = await context.newPage();

    try {
        // 1. 访问并登录
        console.log("🔐 登录Dokploy...");
        await page.goto(DOKPLOY_URL, { waitUntil: 'networkidle' });
        await page.waitForTimeout(2000);

        // 填写登录表单
        await page.fill('input[name="email"]', EMAIL);
        await page.waitForTimeout(500);
        await page.fill('input[name="password"]', PASSWORD);
        await page.waitForTimeout(500);
        await takeScreenshot(page, "login_filled");

        // 点击登录
        await page.click('button[type="submit"]');
        console.log("⏳ 等待登录完成...");
        await page.waitForTimeout(5000);
        await takeScreenshot(page, "after_login");

        // 2. 导航到项目
        console.log("🔍 导航到项目...");
        const currentUrl = page.url();
        console.log(`当前URL: ${currentUrl}`);

        // 如果已经在dashboard，点击项目
        if (currentUrl.includes('/dashboard') || currentUrl.includes('/projects')) {
            try {
                await page.click('text="AI智能体简历"', { timeout: 5000 });
                console.log("✅ 已点击项目");
                await page.waitForTimeout(3000);
                await takeScreenshot(page, "project_page");
            } catch (error) {
                console.log("⚠️ 无法点击项目，可能已经在项目页面");
            }
        }

        // 3. 查找Backend服务
        console.log("🔍 查找Backend服务...");
        await page.waitForTimeout(2000);

        // 尝试多种方式查找backend服务
        const backendSelectors = [
            'text="backend"',
            'text="Backend"',
            'div:has-text("backend")',
            'a:has-text("backend")',
            '[role="button"]:has-text("backend")',
        ];

        let backendFound = false;
        for (const selector of backendSelectors) {
            try {
                const element = await page.$(selector);
                if (element) {
                    console.log(`✅ 找到Backend服务: ${selector}`);
                    await element.click();
                    await page.waitForTimeout(3000);
                    await takeScreenshot(page, "backend_clicked");
                    backendFound = true;
                    break;
                }
            } catch (error) {
                console.log(`⚠️ ${selector} 未找到`);
            }
        }

        if (!backendFound) {
            console.log("❌ 未找到Backend服务，列出所有元素...");
            const pageText = await page.textContent('body');
            console.log("页面内容（前2000字符）:");
            console.log(pageText.substring(0, 2000));
        }

        // 4. 查找并点击日志标签页
        console.log("📋 查找日志标签页...");
        await page.waitForTimeout(2000);
        await takeScreenshot(page, "before_logs_tab");

        // 查找可能的日志标签
        const logTabSelectors = [
            'text="Logs"',
            'text="logs"',
            'text="日志"',
            'text="Log"',
            'text="log"',
            'button:has-text("Logs")',
            'button:has-text("logs")',
            'button:has-text("日志")',
            'a:has-text("Logs")',
            'a:has-text("logs")',
            'tab:has-text("Logs")',
            '[role="tab"]:has-text("Logs")',
            '[data-testid="logs"]',
            '[data-tab="logs"]',
            '[class*="logs"]',
        ];

        let logsTabFound = false;
        for (const selector of logTabSelectors) {
            try {
                console.log(`🔍 尝试: ${selector}`);
                const element = await page.$(selector);
                if (element) {
                    console.log(`✅ 找到日志标签: ${selector}`);
                    await element.click();
                    console.log("✅ 已点击日志标签");
                    await page.waitForTimeout(3000);
                    await takeScreenshot(page, "logs_tab_opened");
                    logsTabFound = true;
                    break;
                }
            } catch (error) {
                console.log(`⚠️ ${selector} 失败: ${error.message}`);
            }
        }

        if (!logsTabFound) {
            console.log("❌ 未找到日志标签，尝试其他方法...");

            // 列出所有标签页
            const tabs = await page.$$('button, a, [role="tab"], [data-tab]');
            console.log(`🔍 找到 ${tabs.length} 个可能的标签/按钮`);

            for (let i = 0; i < Math.min(tabs.length, 20); i++) {
                try {
                    const text = await tabs[i].textContent();
                    const className = await tabs[i].getAttribute('class');
                    const dataTab = await tabs[i].getAttribute('data-tab');
                    const role = await tabs[i].getAttribute('role');

                    if (text && text.trim()) {
                        console.log(`  ${i + 1}. text="${text.trim()}", class="${className}", data-tab="${dataTab}", role="${role}"`);

                        // 如果找到logs相关的，尝试点击
                        if (text.toLowerCase().includes('log')) {
                            console.log(`✅ 点击日志相关标签: ${text.trim()}`);
                            await tabs[i].click();
                            await page.waitForTimeout(3000);
                            await takeScreenshot(page, "logs_clicked");
                            logsTabFound = true;
                            break;
                        }
                    }
                } catch (error) {
                    // 忽略
                }
            }
        }

        // 5. 提取日志内容
        console.log("📋 提取日志内容...");
        await page.waitForTimeout(2000);
        await takeScreenshot(page, "logs_content");

        // 尝试多种方式提取日志
        const logContentSelectors = [
            '[class*="log-content"]',
            '[class*="logs-content"]',
            '[class*="terminal"]',
            '[class*="console"]',
            'pre',
            'code',
            '[id*="logs"]',
            '[id*="log"]',
            '[role="log"]',
            '[data-testid="logs-content"]',
            '[class*="output"]',
        ];

        let logsContent = '';
        let logsExtracted = false;

        for (const selector of logContentSelectors) {
            try {
                console.log(`🔍 尝试提取日志: ${selector}`);
                const elements = await page.$$(selector);
                if (elements.length > 0) {
                    console.log(`✅ 找到 ${elements.length} 个元素: ${selector}`);

                    for (let i = 0; i < elements.length; i++) {
                        const text = await elements[i].textContent();
                        if (text && text.trim().length > 0) {
                            if (!logsExtracted) {
                                console.log("📄 日志内容预览（前2000字符）:");
                                console.log(text.substring(0, 2000));
                                logsExtracted = true;
                            }
                            logsContent += `\n\n=== ${selector} ${i + 1} ===\n${text}`;
                        }
                    }

                    if (logsExtracted) break;
                }
            } catch (error) {
                console.log(`⚠️ ${selector} 失败: ${error.message}`);
            }
        }

        // 如果没有找到特定的日志容器，获取整个页面
        if (!logsExtracted) {
            console.log("📄 获取整个页面内容...");
            const pageContent = await page.textContent('body');
            logsContent = pageContent;
            console.log("📄 页面内容预览（前3000字符）:");
            console.log(pageContent.substring(0, 3000));
        }

        // 保存日志
        if (logsContent) {
            const logFile = `backend_container_logs_${getTimestamp()}.txt`;
            fs.writeFileSync(logFile, logsContent, 'utf8');
            console.log(`💾 容器日志已保存: ${logFile}`);

            // 分析日志
            analyzeLogs(logsContent);
        }

        // 6. 尝试查找状态和错误信息
        console.log("🔍 查找服务状态信息...");
        const statusSelectors = [
            '[class*="status"]',
            '[data-testid="status"]',
            '[class*="health"]',
            'text="starting"',
            'text="running"',
            'text="stopped"',
            'text="error"',
            'text="failed"',
        ];

        for (const selector of statusSelectors) {
            try {
                const elements = await page.$$(selector);
                if (elements.length > 0) {
                    console.log(`✅ 找到状态信息: ${selector}`);
                    for (let i = 0; i < Math.min(elements.length, 5); i++) {
                        const text = await elements[i].textContent();
                        console.log(`  状态 ${i + 1}: ${text}`);
                    }
                    break;
                }
            } catch (error) {
                // 忽略
            }
        }

        // 7. 尝试查找重启、停止等操作按钮
        console.log("🔍 查找操作按钮...");
        const actionSelectors = [
            'button:has-text("Restart")',
            'button:has-text("restart")',
            'button:has-text("Stop")',
            'button:has-text("stop")',
            'button:has-text("Logs")',
            'button:has-text("Console")',
            'button:has-text("Terminal")',
        ];

        for (const selector of actionSelectors) {
            try {
                const element = await page.$(selector);
                if (element) {
                    const text = await element.textContent();
                    console.log(`  找到操作按钮: ${text.trim()}`);
                }
            } catch (error) {
                // 忽略
            }
        }

        console.log("✅ 日志收集完成");
        await takeScreenshot(page, "final_state");

    } catch (error) {
        console.log(`❌ 发生错误: ${error.message}`);
        console.error(error);
        await takeScreenshot(page, "error");
    } finally {
        console.log("⏸️ 等待20秒后关闭...");
        await page.waitForTimeout(20000);
        await browser.close();
    }

    console.log("🏁 脚本执行完成");
};

const analyzeLogs = (content) => {
    console.log("\n🔍 分析日志内容...");

    const errorPatterns = [
        'error', 'exception', 'failed', 'traceback', 'fatal',
        'warning', 'timeout', 'connection refused', 'cannot connect',
        'port already', 'address already', 'no such file',
        'module not found', 'import error', 'permission denied',
        'authentication failed', 'database error', 'sql error',
        'python', 'django', 'flask', 'gunicorn', 'uvicorn',
        'fastapi', 'starting', 'started', 'listening',
        'application error', 'startup error', 'boot error'
    ];

    const lines = content.split('\n');
    const findings = [];

    lines.forEach((line, index) => {
        const lowerLine = line.toLowerCase().trim();
        if (lowerLine.length > 5) { // 忽略太短的行
            for (const pattern of errorPatterns) {
                if (lowerLine.includes(pattern)) {
                    findings.push({
                        line: index + 1,
                        pattern: pattern,
                        text: line.trim().substring(0, 150)
                    });
                    break;
                }
            }
        }
    });

    if (findings.length > 0) {
        console.log(`📊 发现 ${findings.length} 个相关问题:`);

        const critical = findings.filter(f =>
            ['error', 'exception', 'fatal', 'traceback', 'failed'].some(p =>
                f.pattern.includes(p))
        );

        const info = findings.filter(f =>
            ['starting', 'started', 'listening'].some(p =>
                f.pattern.includes(p))
        );

        console.log(`\n🔴 严重问题 (${critical.length}):`);
        critical.slice(0, 10).forEach(f => {
            console.log(`  行 ${f.line}: ${f.text}`);
        });

        console.log(`\n🔵 启动信息 (${info.length}):`);
        info.slice(0, 10).forEach(f => {
            console.log(`  行 ${f.line}: ${f.text}`);
        });

        // 保存分析结果
        const analysisFile = `backend_log_analysis_${getTimestamp()}.json`;
        fs.writeFileSync(analysisFile, JSON.stringify({
            timestamp: new Date().toISOString(),
            totalFindings: findings.length,
            critical: critical.length,
            info: info.length,
            findings: findings.slice(0, 100)
        }, null, 2), 'utf8');
        console.log(`\n💾 分析结果已保存: ${analysisFile}`);
    } else {
        console.log("✅ 未发现明显的日志内容");
    }
};

main().catch(console.error);