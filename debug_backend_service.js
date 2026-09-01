/**
 * 使用Playwright自动化浏览器检查Dokploy中Backend服务的详细状态
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// 配置信息
const DOKPLOY_URL = "http://113.45.64.145:3000";
const EMAIL = "641600780@qq.com";
const PASSWORD = "353980swsgbo";
const PROJECT_NAME = "AI智能体简历";  // 可能的项目名称
const SERVICE_NAME = "backend";  // 要检查的服务名称

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

// 等待并点击元素
const waitAndClick = async (page, selector, timeout = 5000) => {
    try {
        await page.waitForSelector(selector, { timeout });
        await page.click(selector);
        return true;
    } catch (error) {
        console.log(`❌ 点击失败 ${selector}: ${error.message}`);
        return false;
    }
};

// 提取元素文本内容
const extractTextContent = async (page, selector) => {
    try {
        const element = await page.$(selector);
        if (element) {
            return await element.textContent();
        }
        return null;
    } catch (error) {
        console.log(`❌ 提取文本失败 ${selector}: ${error.message}`);
        return null;
    }
};

// 登录到Dokploy
const loginToDokploy = async (page) => {
    console.log("🔐 开始登录Dokploy...");

    // 访问登录页面
    console.log(`🌐 正在访问 ${DOKPLOY_URL}...`);
    await page.goto(DOKPLOY_URL, { waitUntil: 'networkidle' });
    await page.waitForTimeout(3000);

    // 检查是否需要登录
    const currentUrl = page.url();
    console.log(`🔍 当前URL: ${currentUrl}`);

    if (!currentUrl.toLowerCase().includes("login") && !currentUrl.includes("/auth")) {
        console.log("✅ 已经登录，跳过登录步骤");
        return true;
    }

    // 截图登录页面
    await takeScreenshot(page, "login_page");

    // 列出页面上的所有输入框
    const allInputs = await page.$$('input');
    console.log(`🔍 页面共有 ${allInputs.length} 个输入框`);

    for (let i = 0; i < allInputs.length; i++) {
        try {
            const inputType = await allInputs[i].getAttribute('type');
            const inputName = await allInputs[i].getAttribute('name');
            const inputPlaceholder = await allInputs[i].getAttribute('placeholder');
            const inputId = await allInputs[i].getAttribute('id');
            console.log(`  输入框 ${i + 1}: type="${inputType}", name="${inputName}", placeholder="${inputPlaceholder}", id="${inputId}"`);
        } catch (error) {
            console.log(`  输入框 ${i + 1}: 无法获取属性`);
        }
    }

    // 尝试多种选择器输入邮箱
    const emailSelectors = [
        'input[type="email"]',
        'input[name="email"]',
        'input[placeholder*="email" i]',
        'input[placeholder*="邮箱" i]',
        'input[placeholder*="Email" i]',
        'input#email',
        'input:first-of-type'
    ];

    let emailFilled = false;
    for (const selector of emailSelectors) {
        try {
            console.log(`🔍 尝试选择器: ${selector}`);
            await page.fill(selector, EMAIL, { timeout: 2000 });
            console.log("✅ 已输入邮箱");
            emailFilled = true;
            break;
        } catch (error) {
            console.log(`⚠️ 选择器 ${selector} 失败: ${error.message}`);
        }
    }

    if (!emailFilled) {
        console.log("❌ 无法找到邮箱输入框，尝试直接查找第一个输入框");
        try {
            const firstInput = allInputs[0];
            if (firstInput) {
                await firstInput.fill(EMAIL);
                console.log("✅ 已在第一个输入框输入邮箱");
                emailFilled = true;
            }
        } catch (error) {
            console.log("❌ 填写邮箱失败");
        }
    }

    await page.waitForTimeout(1000);

    // 尝试多种选择器输入密码
    const passwordSelectors = [
        'input[type="password"]',
        'input[name="password"]',
        'input[placeholder*="password" i]',
        'input[placeholder*="密码" i]'
    ];

    let passwordFilled = false;
    for (const selector of passwordSelectors) {
        try {
            await page.fill(selector, PASSWORD, { timeout: 2000 });
            console.log("✅ 已输入密码");
            passwordFilled = true;
            break;
        } catch (error) {
            // 继续尝试下一个选择器
        }
    }

    if (!passwordFilled) {
        console.log("❌ 无法找到密码输入框");
    }

    await page.waitForTimeout(1000);
    await takeScreenshot(page, "login_filled");

    // 尝试点击登录按钮
    const loginSelectors = [
        'button[type="submit"]',
        'button:has-text("登录")',
        'button:has-text("Login")',
        'button:has-text("Sign In")',
    ];

    let loginClicked = false;
    for (const selector of loginSelectors) {
        if (await waitAndClick(page, selector, 2000)) {
            console.log("✅ 已点击登录按钮");
            loginClicked = true;
            break;
        }
    }

    if (!loginClicked) {
        console.log("❌ 无法找到登录按钮");
    }

    // 等待登录完成
    await page.waitForTimeout(5000);
    await takeScreenshot(page, "after_login");

    // 检查是否登录成功
    const finalUrl = page.url();
    if (!finalUrl.toLowerCase().includes("login")) {
        console.log("✅ 登录成功");
        return true;
    } else {
        console.log("❌ 登录可能失败");
        return false;
    }
};

// 查找并导航到项目
const findAndNavigateToProject = async (page) => {
    console.log("🔍 查找项目...");
    await page.waitForTimeout(2000);

    // 截图主页面
    await takeScreenshot(page, "main_dashboard");

    // 尝试多种方式查找项目
    const searchStrategies = [
        `text="${PROJECT_NAME}"`,
        `text="ai-resume"`,
        `a:has-text("${PROJECT_NAME}")`,
        `a:has-text("ai-resume")`,
        `button:has-text("${PROJECT_NAME}")`,
        `button:has-text("ai-resume")`,
    ];

    for (const strategy of searchStrategies) {
        try {
            console.log(`🔍 尝试策略: ${strategy}`);
            const element = await page.$(strategy);
            if (element) {
                console.log(`✅ 找到项目元素: ${strategy}`);
                await element.click();
                await page.waitForTimeout(3000);
                await takeScreenshot(page, "project_page");
                return true;
            }
        } catch (error) {
            console.log(`⚠️ 策略 ${strategy} 未找到: ${error.message}`);
        }
    }

    // 如果没有找到，尝试列出所有链接
    console.log("❌ 未找到项目，尝试列出所有链接...");
    const links = await page.$$('a, button');
    console.log(`🔍 页面上有 ${links.length} 个链接/按钮`);

    // 提取页面文本内容
    const pageText = await page.textContent('body');
    console.log("📄 页面文本内容（前1000字符）:");
    console.log(pageText ? pageText.substring(0, 1000) : "无内容");

    return false;
};

// 查找并检查Backend服务
const findAndCheckBackendService = async (page) => {
    console.log("🔍 查找Backend服务...");

    // 截图项目页面
    await takeScreenshot(page, "project_services");

    // 查找Backend相关的服务
    const backendSelectors = [
        `text="${SERVICE_NAME}"`,
        `text="${SERVICE_NAME.toUpperCase()}"`,
        `text="${SERVICE_NAME.charAt(0).toUpperCase() + SERVICE_NAME.slice(1)}"`,
        `text="Backend"`,
        `text="backend"`,
    ];

    for (const selector of backendSelectors) {
        try {
            const element = await page.$(selector);
            if (element) {
                console.log(`✅ 找到Backend服务: ${selector}`);
                await element.click();
                await page.waitForTimeout(3000);
                await takeScreenshot(page, "backend_service_page");

                // 检查服务详情
                await analyzeBackendServiceDetails(page);
                return true;
            }
        } catch (error) {
            console.log(`⚠️ 选择器 ${selector} 未找到: ${error.message}`);
        }
    }

    // 列出所有可能的服务元素
    console.log("🔍 列出所有可用服务...");
    const serviceElements = await page.$$('[class*="service"], [class*="container"], [role="listitem"]');
    console.log(`📋 找到 ${serviceElements.length} 个可能的服务元素`);

    for (let i = 0; i < Math.min(serviceElements.length, 10); i++) {
        try {
            const text = await serviceElements[i].textContent();
            console.log(`  ${i + 1}. ${text ? text.substring(0, 100) : ''}`);
        } catch (error) {
            // 忽略错误
        }
    }

    return false;
};

// 分析Backend服务的详细信息
const analyzeBackendServiceDetails = async (page) => {
    console.log("📊 分析Backend服务详情...");

    // 截图服务页面
    await takeScreenshot(page, "backend_details");

    // 查找并点击日志按钮
    const logButtonSelectors = [
        'button:has-text("日志")',
        'button:has-text("Logs")',
        'button:has-text("Log")',
        'a:has-text("日志")',
        'a:has-text("Logs")',
        '[aria-label*="log" i]',
        '[title*="log" i]',
    ];

    for (const selector of logButtonSelectors) {
        try {
            if (await waitAndClick(page, selector, 3000)) {
                console.log("✅ 已打开日志页面");
                await page.waitForTimeout(3000);
                await extractAndAnalyzeLogs(page);
                break;
            }
        } catch (error) {
            console.log(`⚠️ 点击日志按钮失败 ${selector}: ${error.message}`);
        }
    }

    // 查找并点击终端/Console按钮
    const consoleSelectors = [
        'button:has-text("终端")',
        'button:has-text("Console")',
        'button:has-text("Terminal")',
        'a:has-text("终端")',
        'a:has-text("Console")',
    ];

    for (const selector of consoleSelectors) {
        try {
            if (await waitAndClick(page, selector, 3000)) {
                console.log("✅ 已打开终端页面");
                await page.waitForTimeout(3000);
                await takeScreenshot(page, "backend_terminal");
                break;
            }
        } catch (error) {
            console.log(`⚠️ 点击终端按钮失败 ${selector}: ${error.message}`);
        }
    }

    // 检查健康状态
    await checkServiceHealth(page);

    // 检查资源使用情况
    await checkResourceUsage(page);
};

// 提取并分析日志
const extractAndAnalyzeLogs = async (page) => {
    console.log("📋 提取日志内容...");

    await takeScreenshot(page, "backend_logs");

    // 尝试多种方式提取日志
    const logSelectors = [
        '[class*="log"]',
        '[class*="terminal"]',
        '[class*="console"]',
        'pre',
        'code',
        '[role="log"]',
        '[id*="log"]',
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
                        console.log(`📄 日志块 ${i + 1} 内容（前500字符）:`);
                        console.log(text.substring(0, 500));
                        logsContent += `\n\n--- 日志块 ${i + 1} ---\n${text}`;
                        foundLogs = true;
                    }
                }

                if (foundLogs) break;
            }
        } catch (error) {
            console.log(`⚠️ 提取日志失败 ${selector}: ${error.message}`);
        }
    }

    // 如果没有找到特定元素，尝试获取整个页面的文本
    if (!foundLogs) {
        console.log("📄 获取整个页面的文本内容...");
        try {
            const pageText = await page.textContent('body');
            logsContent = pageText || "";
        } catch (error) {
            console.log("❌ 获取页面文本失败");
        }
    }

    // 保存日志到文件
    if (logsContent) {
        const logFilename = `backend_logs_${getTimestamp()}.txt`;
        fs.writeFileSync(logFilename, logsContent, 'utf8');
        console.log(`💾 日志已保存到: ${logFilename}`);

        // 分析日志中的错误
        analyzeLogsForErrors(logsContent);
    } else {
        console.log("❌ 未能提取到日志内容");
    }
};

// 分析日志中的错误信息
const analyzeLogsForErrors = (logsContent) => {
    console.log("\n🔍 分析日志中的错误信息...");

    const errorPatterns = [
        'Error', 'Exception', 'Failed', 'failed', 'ERROR', 'error',
        'Traceback', 'Warning', 'WARNING', 'warning', 'Fatal', 'fatal',
        'Connection refused', 'Connection reset', 'Timeout', 'timeout',
        'Cannot', 'Unable', 'Invalid', 'Missing', 'Not found', 'not found',
        'Permission denied', 'Access denied', 'Authentication failed',
        'Database error', 'SQL error', 'Port already in use',
        'Address already in use', 'No such file', 'Module not found',
        'Import error', 'Dependency', 'Package', 'Installation failed',
        'python', 'django', 'flask', 'gunicorn', 'uvicorn', 'fastapi'
    ];

    const foundErrors = [];
    const lines = logsContent.split('\n');

    lines.forEach((line, index) => {
        for (const pattern of errorPatterns) {
            if (line.toLowerCase().includes(pattern.toLowerCase())) {
                // 获取上下文（前后几行）
                const contextStart = Math.max(0, index - 2);
                const contextEnd = Math.min(lines.length, index + 3);
                const context = lines.slice(contextStart, contextEnd);

                foundErrors.push({
                    pattern: pattern,
                    line: line.trim(),
                    lineNumber: index + 1,
                    context: context
                });
                break;
            }
        }
    });

    if (foundErrors.length > 0) {
        console.log(`❌ 发现 ${foundErrors.length} 个可能的错误:`);

        // 按严重程度分类
        const criticalErrors = foundErrors.filter(e =>
            ['error', 'exception', 'failed', 'fatal', 'traceback'].some(p =>
                e.line.toLowerCase().includes(p))
        );
        const warnings = foundErrors.filter(e =>
            ['warning', 'timeout'].some(p => e.line.toLowerCase().includes(p))
        );

        console.log(`\n🔴 严重错误 (${criticalErrors.length}):`);
        criticalErrors.slice(0, 10).forEach(error => {
            console.log(`  行 ${error.lineNumber}: ${error.line.substring(0, 100)}`);
        });

        console.log(`\n🟡 警告 (${warnings.length}):`);
        warnings.slice(0, 5).forEach(warning => {
            console.log(`  行 ${warning.lineNumber}: ${warning.line.substring(0, 100)}`);
        });

        // 保存错误报告
        const errorReport = {
            timestamp: new Date().toISOString(),
            totalErrors: foundErrors.length,
            criticalErrors: criticalErrors.length,
            warnings: warnings.length,
            errors: foundErrors.slice(0, 50) // 只保存前50个错误
        };

        const errorReportFile = `backend_error_report_${getTimestamp()}.json`;
        fs.writeFileSync(errorReportFile, JSON.stringify(errorReport, null, 2), 'utf8');
        console.log(`\n💾 错误报告已保存: ${errorReportFile}`);
    } else {
        console.log("✅ 未发现明显的错误信息");
    }
};

// 检查服务健康状态
const checkServiceHealth = async (page) => {
    console.log("🏥 检查服务健康状态...");

    const healthSelectors = [
        '[class*="health"]',
        '[class*="status"]',
        '[aria-label*="health" i]',
        '[aria-label*="status" i]',
    ];

    for (const selector of healthSelectors) {
        try {
            const elements = await page.$$(selector);
            if (elements.length > 0) {
                console.log(`✅ 找到 ${elements.length} 个健康状态元素`);
                for (let i = 0; i < Math.min(elements.length, 5); i++) {
                    const text = await elements[i].textContent();
                    console.log(`  健康状态 ${i + 1}: ${text}`);
                }
            }
        } catch (error) {
            console.log(`⚠️ 检查健康状态失败 ${selector}: ${error.message}`);
        }
    }
};

// 检查资源使用情况
const checkResourceUsage = async (page) => {
    console.log("📊 检查资源使用情况...");

    const resourceSelectors = [
        '[class*="cpu"]',
        '[class*="memory"]',
        '[class*="resource"]',
        '[class*="usage"]',
        'text=CPU',
        'text=Memory',
        'text=内存',
    ];

    for (const selector of resourceSelectors) {
        try {
            const elements = await page.$$(selector);
            if (elements.length > 0) {
                console.log(`✅ 找到 ${elements.length} 个资源信息元素`);
                for (let i = 0; i < Math.min(elements.length, 5); i++) {
                    const text = await elements[i].textContent();
                    console.log(`  资源信息 ${i + 1}: ${text}`);
                }
            }
        } catch (error) {
            console.log(`⚠️ 检查资源使用失败 ${selector}: ${error.message}`);
        }
    }
};

// 主函数
const main = async () => {
    console.log("🚀 开始检查Dokploy Backend服务状态...");
    console.log(`📅 时间: ${new Date().toLocaleString('zh-CN')}`);
    console.log(`🌐 目标: ${DOKPLOY_URL}`);
    console.log(`📧 邮箱: ${EMAIL}`);

    const browser = await chromium.launch({
        headless: false, // 显示浏览器窗口
        slowMo: 1000,    // 慢速操作以便观察
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
            console.log("❌ 登录失败，终止检查");
            return;
        }

        // 2. 查找项目
        const projectFound = await findAndNavigateToProject(page);
        if (!projectFound) {
            console.log("❌ 未找到项目，可能需要手动导航...");
        }

        // 3. 查找Backend服务
        const backendFound = await findAndCheckBackendService(page);
        if (!backendFound) {
            console.log("❌ 未找到Backend服务");
        }

        console.log("✅ 检查完成");

    } catch (error) {
        console.log(`❌ 发生错误: ${error.message}`);
        console.error(error);
    } finally {
        // 等待用户查看
        console.log("⏸️ 等待10秒后关闭浏览器...");
        await page.waitForTimeout(10000);
        await browser.close();
    }

    console.log(`🏁 检查结束于: ${new Date().toLocaleString('zh-CN')}`);
};

// 运行主函数
main().catch(console.error);