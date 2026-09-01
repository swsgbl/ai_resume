/**
 * 改进版：使用Playwright自动化浏览器检查Dokploy中Backend服务的详细状态
 * 针对单页应用(SPA)进行优化
 */

const { chromium } = require('playwright');
const fs = require('fs');

// 配置信息
const DOKPLOY_URL = "http://113.45.64.145:3000";
const EMAIL = "641600780@qq.com";
const PASSWORD = "353980swsgbo";

// 生成时间戳
const getTimestamp = () => {
    const now = new Date();
    return now.toISOString().replace(/[:.]/g, '-').slice(0, -5);
};

// 截图保存函数
const takeScreenshot = async (page, name) => {
    const filename = `backend_debug_${name}_${getTimestamp()}.png`;
    await page.screenshot({ path: filename, fullPage: true });
    console.log(`📸 截图已保存: ${filename}`);
    return filename;
};

// 等待页面稳定
const waitForPageStable = async (page, maxTimeout = 30000) => {
    console.log("⏳ 等待页面加载完成...");

    // 等待网络空闲
    try {
        await page.waitForLoadState('networkidle', { timeout: maxTimeout });
    } catch (error) {
        console.log("⚠️ 网络空闲超时，继续执行");
    }

    // 额外等待JavaScript执行
    await page.waitForTimeout(3000);
};

// 智能查找元素并填写
const smartFill = async (page, value, selectors) => {
    for (const selector of selectors) {
        try {
            console.log(`🔍 尝试选择器: ${selector}`);

            // 先等待元素可见
            await page.waitForSelector(selector, { timeout: 2000, state: 'visible' });

            // 清空并填写
            await page.fill(selector, '');
            await page.fill(selector, value);

            console.log(`✅ 成功填写: ${selector}`);
            return { success: true, selector };
        } catch (error) {
            console.log(`⚠️ 选择器失败 ${selector}: ${error.message}`);
            continue;
        }
    }

    return { success: false };
};

// 智能点击
const smartClick = async (page, selectors, description = "元素") => {
    for (const selector of selectors) {
        try {
            console.log(`🔍 尝试点击: ${selector}`);

            // 先等待元素可见和可点击
            await page.waitForSelector(selector, { timeout: 2000, state: 'visible' });

            // 滚动到元素
            const element = await page.$(selector);
            if (element) {
                await element.scrollIntoViewIfNeeded();
                await page.waitForTimeout(500);
            }

            // 点击
            await page.click(selector);

            console.log(`✅ 成功点击: ${selector}`);
            return { success: true, selector };
        } catch (error) {
            console.log(`⚠️ 点击失败 ${selector}: ${error.message}`);
            continue;
        }
    }

    console.log(`❌ 无法点击${description}`);
    return { success: false };
};

// 登录到Dokploy
const loginToDokploy = async (page) => {
    console.log("🔐 开始登录Dokploy...");

    // 访问登录页面
    console.log(`🌐 正在访问 ${DOKPLOY_URL}...`);
    await page.goto(DOKPLOY_URL, { waitUntil: 'domcontentloaded' });

    await waitForPageStable(page);

    // 截图当前页面
    await takeScreenshot(page, "initial_page");

    const currentUrl = page.url();
    console.log(`🔍 当前URL: ${currentUrl}`);

    // 检查是否有登录表单
    const hasLoginForm = await page.$('input[type="email"], input[type="password"], input[name="email"], input[name="password"]');
    const hasSignInText = await page.textContent('body').then(text =>
        text.toLowerCase().includes('sign in') ||
        text.toLowerCase().includes('login') ||
        text.toLowerCase().includes('登录')
    );

    if (!hasLoginForm && !hasSignInText) {
        console.log("✅ 可能已经登录，检查仪表板...");
        await takeScreenshot(page, "possibly_logged_in");
        return true;
    }

    console.log("📋 需要登录...");

    // 获取页面标题和内容
    const pageTitle = await page.title();
    console.log(`📄 页面标题: ${pageTitle}`);

    // 列出所有输入框
    const allInputs = await page.$$('input');
    console.log(`🔍 页面共有 ${allInputs.length} 个输入框`);

    for (let i = 0; i < allInputs.length; i++) {
        try {
            const attrs = await page.evaluate(el => {
                return {
                    type: el.type || '',
                    name: el.name || '',
                    id: el.id || '',
                    placeholder: el.placeholder || '',
                    className: el.className || ''
                };
            }, allInputs[i]);

            console.log(`  输入框 ${i + 1}: type="${attrs.type}", name="${attrs.name}", id="${attrs.id}", placeholder="${attrs.placeholder}", class="${attrs.className}"`);
        } catch (error) {
            console.log(`  输入框 ${i + 1}: 无法获取属性`);
        }
    }

    // 尝试填写邮箱
    console.log("📧 尝试填写邮箱...");
    const emailSelectors = [
        'input[type="email"]',
        'input[name="email"]',
        'input[placeholder*="email" i]',
        'input[placeholder*="Email" i]',
        'input#email',
        'input:first-of-type'
    ];

    const emailResult = await smartFill(page, EMAIL, emailSelectors);
    if (!emailResult.success) {
        console.log("❌ 无法填写邮箱");
        return false;
    }

    await page.waitForTimeout(1000);
    await takeScreenshot(page, "email_filled");

    // 尝试填写密码
    console.log("🔑 尝试填写密码...");
    const passwordSelectors = [
        'input[type="password"]',
        'input[name="password"]',
        'input[placeholder*="password" i]',
        'input[placeholder*="Password" i]',
        'input#password',
        'input:last-of-type'
    ];

    const passwordResult = await smartFill(page, PASSWORD, passwordSelectors);
    if (!passwordResult.success) {
        console.log("❌ 无法填写密码");
        return false;
    }

    await page.waitForTimeout(1000);
    await takeScreenshot(page, "password_filled");

    // 查找并点击登录按钮
    console.log("🔘 查找登录按钮...");

    // 列出所有按钮
    const allButtons = await page.$$('button, [type="submit"], [role="button"]');
    console.log(`🔍 页面共有 ${allButtons.length} 个按钮`);

    for (let i = 0; i < Math.min(allButtons.length, 10); i++) {
        try {
            const buttonText = await allButtons[i].textContent();
            const buttonAttrs = await page.evaluate(el => {
                return {
                    type: el.type || '',
                    text: el.textContent?.trim() || '',
                    className: el.className || ''
                };
            }, allButtons[i]);
            console.log(`  按钮 ${i + 1}: type="${buttonAttrs.type}", text="${buttonAttrs.text}", class="${buttonAttrs.className}"`);
        } catch (error) {
            // 忽略
        }
    }

    const loginButtonSelectors = [
        'button[type="submit"]',
        'button:has-text("Sign in")',
        'button:has-text("Sign In")',
        'button:has-text("Login")',
        'button:has-text("登录")',
        'button:has-text("Log in")',
        'button:has-text("Log In")',
        'button:has-text("登录")',
        '[type="submit"]',
        'button:has-text("Sign")',
        'button:has-text("in")',
    ];

    const loginResult = await smartClick(page, loginButtonSelectors, "登录按钮");
    if (!loginResult.success) {
        console.log("❌ 无法点击登录按钮");
        return false;
    }

    console.log("⏳ 等待登录完成...");
    await page.waitForTimeout(5000);

    await waitForPageStable(page);
    await takeScreenshot(page, "after_login");

    // 检查登录是否成功
    const finalUrl = page.url();
    console.log(`🔍 登录后URL: ${finalUrl}`);

    const stillHasLoginForm = await page.$('input[type="email"], input[type="password"]').catch(() => null);
    if (!stillHasLoginForm && !finalUrl.toLowerCase().includes('login')) {
        console.log("✅ 登录成功");
        return true;
    } else {
        console.log("❌ 登录可能失败，仍在登录页面");
        return false;
    }
};

// 查找并导航到项目
const findAndNavigateToProject = async (page) => {
    console.log("🔍 查找项目...");
    await waitForPageStable(page);

    // 截图主页面
    await takeScreenshot(page, "main_dashboard");

    // 尝试获取页面内容
    const pageContent = await page.textContent('body');
    console.log("📄 页面内容预览（前2000字符）:");
    console.log(pageContent.substring(0, 2000));

    // 查找可能的项目链接
    const possibleProjectTexts = [
        'AI智能体简历',
        'ai-resume',
        'resume',
        'AI',
        '智能体',
        '简历'
    ];

    for (const projectText of possibleProjectTexts) {
        console.log(`🔍 搜索项目文本: "${projectText}"`);

        if (pageContent.toLowerCase().includes(projectText.toLowerCase())) {
            console.log(`✅ 找到包含"${projectText}"的文本`);

            // 尝试点击包含该文本的元素
            const selectors = [
                `text="${projectText}"`,
                `a:has-text("${projectText}")`,
                `button:has-text("${projectText}")`,
                `[role="button"]:has-text("${projectText}")`,
                `div:has-text("${projectText}")`,
            ];

            for (const selector of selectors) {
                try {
                    const element = await page.$(selector);
                    if (element) {
                        console.log(`✅ 点击项目元素: ${selector}`);
                        await element.click();
                        await page.waitForTimeout(3000);
                        await takeScreenshot(page, `project_${projectText}`);
                        return true;
                    }
                } catch (error) {
                    console.log(`⚠️ 点击失败 ${selector}: ${error.message}`);
                }
            }
        }
    }

    // 列出所有可能的导航链接
    console.log("🔍 列出所有导航链接...");
    const links = await page.$$('a, button, [role="button"], [class*="nav"], [class*="menu"]');
    console.log(`📋 找到 ${links.length} 个导航元素`);

    const projectLinks = [];
    for (let i = 0; i < Math.min(links.length, 20); i++) {
        try {
            const text = await links[i].textContent();
            const href = await links[i].getAttribute('href');
            const className = await links[i].getAttribute('class');

            if (text && text.trim().length > 0) {
                const linkInfo = {
                    index: i + 1,
                    text: text.trim().substring(0, 50),
                    href: href || '',
                    className: className || ''
                };

                if (linkInfo.text.toLowerCase().includes('ai') ||
                    linkInfo.text.toLowerCase().includes('resume') ||
                    linkInfo.text.toLowerCase().includes('简历') ||
                    linkInfo.text.toLowerCase().includes('智能体')) {
                    projectLinks.push(linkInfo);
                    console.log(`  🎯 可能的项目链接: ${JSON.stringify(linkInfo)}`);
                } else if (i < 10) { // 只显示前10个其他链接
                    console.log(`  ${JSON.stringify(linkInfo)}`);
                }
            }
        } catch (error) {
            // 忽略
        }
    }

    if (projectLinks.length > 0) {
        console.log(`✅ 找到 ${projectLinks.length} 个可能的项目链接，尝试点击第一个...`);
        try {
            const firstProjectLink = links[projectLinks[0].index - 1];
            await firstProjectLink.click();
            await page.waitForTimeout(3000);
            await takeScreenshot(page, "project_clicked");
            return true;
        } catch (error) {
            console.log(`❌ 点击项目链接失败: ${error.message}`);
        }
    }

    return false;
};

// 查找Backend服务
const findBackendService = async (page) => {
    console.log("🔍 查找Backend服务...");
    await waitForPageStable(page);

    await takeScreenshot(page, "service_list");

    const pageContent = await page.textContent('body');

    // 查找Backend相关的服务
    const backendKeywords = [
        'backend',
        'Backend',
        'BACKEND',
        '后端',
        'api',
        'API',
        'server',
        'Server'
    ];

    for (const keyword of backendKeywords) {
        if (pageContent.toLowerCase().includes(keyword.toLowerCase())) {
            console.log(`✅ 找到包含"${keyword}"的文本`);

            // 尝试点击
            const selectors = [
                `text="${keyword}"`,
                `div:has-text("${keyword}")`,
                `[role="button"]:has-text("${keyword}")`,
                `a:has-text("${keyword}")`,
                `button:has-text("${keyword}")`,
            ];

            for (const selector of selectors) {
                try {
                    const element = await page.$(selector);
                    if (element) {
                        console.log(`✅ 点击Backend服务: ${selector}`);
                        await element.click();
                        await page.waitForTimeout(3000);
                        await takeScreenshot(page, "backend_service");
                        return true;
                    }
                } catch (error) {
                    console.log(`⚠️ 点击失败 ${selector}: ${error.message}`);
                }
            }
        }
    }

    // 列出所有可能的服务
    console.log("🔍 列出所有可能的服务...");
    const serviceElements = await page.$$('[class*="service"], [class*="app"], [class*="container"], [role="listitem"]');
    console.log(`📋 找到 ${serviceElements.length} 个可能的服务元素`);

    for (let i = 0; i < Math.min(serviceElements.length, 15); i++) {
        try {
            const text = await serviceElements[i].textContent();
            const className = await serviceElements[i].getAttribute('class');
            if (text && text.trim().length > 0) {
                console.log(`  服务 ${i + 1}: class="${className}", text="${text.trim().substring(0, 80)}"`);
            }
        } catch (error) {
            // 忽略
        }
    }

    return false;
};

// 检查服务详情和日志
const checkServiceDetails = async (page) => {
    console.log("📊 检查服务详情...");
    await waitForPageStable(page);

    await takeScreenshot(page, "service_details");

    // 查找日志相关按钮
    const logSelectors = [
        'button:has-text("日志")',
        'button:has-text("Logs")',
        'button:has-text("Log")',
        'a:has-text("日志")',
        'a:has-text("Logs")',
        'tab:has-text("日志")',
        'tab:has-text("Logs")',
        '[aria-label*="log" i]',
        '[title*="log" i]',
    ];

    for (const selector of logSelectors) {
        try {
            if (await smartClick(page, [selector], "日志按钮")) {
                console.log("✅ 已打开日志页面");
                await waitForPageStable(page);
                await extractLogs(page);
                return true;
            }
        } catch (error) {
            console.log(`⚠️ 打开日志失败 ${selector}: ${error.message}`);
        }
    }

    // 如果没找到日志按钮，尝试获取页面所有文本
    console.log("📄 获取服务页面所有内容...");
    const pageContent = await page.textContent('body');
    const logFile = `backend_service_page_${getTimestamp()}.txt`;
    fs.writeFileSync(logFile, pageContent, 'utf8');
    console.log(`💾 服务页面内容已保存: ${logFile}`);

    return false;
};

// 提取日志
const extractLogs = async (page) => {
    console.log("📋 提取日志内容...");

    await takeScreenshot(page, "logs_page");

    const logSelectors = [
        '[class*="log"]',
        '[class*="terminal"]',
        '[class*="console"]',
        'pre',
        'code',
        '[role="log"]',
        '[id*="log"]',
        '[class*="output"]',
    ];

    let logsContent = "";
    let foundLogs = false;

    for (const selector of logSelectors) {
        try {
            const elements = await page.$$(selector);
            if (elements.length > 0) {
                console.log(`✅ 找到 ${elements.length} 个日志元素: ${selector}`);

                for (let i = 0; i < elements.length; i++) {
                    const text = await elements[i].textContent();
                    if (text && text.trim().length > 0) {
                        if (!foundLogs) {
                            console.log(`📄 日志内容预览（前1000字符）:`);
                            console.log(text.substring(0, 1000));
                            foundLogs = true;
                        }
                        logsContent += `\n\n--- ${selector} ${i + 1} ---\n${text}`;
                    }
                }

                if (foundLogs) break;
            }
        } catch (error) {
            console.log(`⚠️ 提取日志失败 ${selector}: ${error.message}`);
        }
    }

    if (!foundLogs) {
        console.log("📄 获取整个页面内容...");
        try {
            const pageContent = await page.textContent('body');
            logsContent = pageContent || "";
            console.log(`📄 页面内容预览（前1000字符）:`);
            console.log(pageContent.substring(0, 1000));
        } catch (error) {
            console.log("❌ 获取页面内容失败");
        }
    }

    if (logsContent) {
        const logFile = `backend_logs_${getTimestamp()}.txt`;
        fs.writeFileSync(logFile, logsContent, 'utf8');
        console.log(`💾 日志已保存: ${logFile}`);

        analyzeLogs(logsContent);
    }
};

// 分析日志错误
const analyzeLogs = (logsContent) => {
    console.log("\n🔍 分析日志中的错误...");

    const errorPatterns = [
        { pattern: 'error', type: 'ERROR' },
        { pattern: 'exception', type: 'CRITICAL' },
        { pattern: 'failed', type: 'ERROR' },
        { pattern: 'traceback', type: 'CRITICAL' },
        { pattern: 'fatal', type: 'CRITICAL' },
        { pattern: 'warning', type: 'WARNING' },
        { pattern: 'timeout', type: 'WARNING' },
        { pattern: 'connection refused', type: 'ERROR' },
        { pattern: 'cannot connect', type: 'ERROR' },
        { pattern: 'port already', type: 'ERROR' },
        { pattern: 'address already', type: 'ERROR' },
        { pattern: 'no such file', type: 'ERROR' },
        { pattern: 'module not found', type: 'ERROR' },
        { pattern: 'import error', type: 'ERROR' },
        { pattern: 'permission denied', type: 'ERROR' },
        { pattern: 'authentication failed', type: 'ERROR' },
        { pattern: 'database error', type: 'CRITICAL' },
        { pattern: 'sql error', type: 'CRITICAL' },
    ];

    const lines = logsContent.split('\n');
    const errors = [];

    lines.forEach((line, index) => {
        const lowerLine = line.toLowerCase();
        errorPatterns.forEach(({ pattern, type }) => {
            if (lowerLine.includes(pattern)) {
                errors.push({
                    lineNumber: index + 1,
                    type: type,
                    pattern: pattern,
                    text: line.trim().substring(0, 200)
                });
            }
        });
    });

    if (errors.length > 0) {
        console.log(`❌ 发现 ${errors.length} 个错误/警告:`);

        const critical = errors.filter(e => e.type === 'CRITICAL');
        const error = errors.filter(e => e.type === 'ERROR');
        const warning = errors.filter(e => e.type === 'WARNING');

        console.log(`\n🔴 严重错误 (${critical.length}):`);
        critical.slice(0, 10).forEach(e => {
            console.log(`  行 ${e.lineNumber}: ${e.text}`);
        });

        console.log(`\n🟠 错误 (${error.length}):`);
        error.slice(0, 10).forEach(e => {
            console.log(`  行 ${e.lineNumber}: ${e.text}`);
        });

        console.log(`\n🟡 警告 (${warning.length}):`);
        warning.slice(0, 5).forEach(e => {
            console.log(`  行 ${e.lineNumber}: ${e.text}`);
        });

        // 保存错误报告
        const errorReport = {
            timestamp: new Date().toISOString(),
            summary: {
                total: errors.length,
                critical: critical.length,
                error: error.length,
                warning: warning.length
            },
            errors: errors.slice(0, 100)
        };

        const reportFile = `backend_errors_${getTimestamp()}.json`;
        fs.writeFileSync(reportFile, JSON.stringify(errorReport, null, 2), 'utf8');
        console.log(`\n💾 错误报告已保存: ${reportFile}`);
    } else {
        console.log("✅ 未发现明显错误");
    }
};

// 主函数
const main = async () => {
    console.log("🚀 开始检查Dokploy Backend服务状态...");
    console.log(`📅 时间: ${new Date().toLocaleString('zh-CN')}`);
    console.log(`🌐 目标: ${DOKPLOY_URL}`);
    console.log(`📧 邮箱: ${EMAIL}`);

    const browser = await chromium.launch({
        headless: false,
        slowMo: 500,
    });

    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    });

    const page = await context.newPage();

    try {
        // 1. 登录
        const loginSuccess = await loginToDokploy(page);
        if (!loginSuccess) {
            console.log("❌ 登录失败，但继续尝试...");
            await takeScreenshot(page, "login_failed");
        }

        // 2. 查找项目
        const projectFound = await findAndNavigateToProject(page);
        if (!projectFound) {
            console.log("❌ 未找到项目，尝试直接查找服务...");
        }

        // 3. 查找Backend服务
        const backendFound = await findBackendService(page);
        if (!backendFound) {
            console.log("❌ 未找到Backend服务");
        } else {
            // 4. 检查服务详情
            await checkServiceDetails(page);
        }

        console.log("✅ 检查完成");

    } catch (error) {
        console.log(`❌ 发生错误: ${error.message}`);
        console.error(error);
        await takeScreenshot(page, "error_page");
    } finally {
        console.log("⏸️ 等待30秒后关闭浏览器...");
        await page.waitForTimeout(30000);
        await browser.close();
    }

    console.log(`🏁 检查结束于: ${new Date().toLocaleString('zh-CN')}`);
};

main().catch(console.error);