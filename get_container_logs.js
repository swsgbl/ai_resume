/**
 * 精确定位Backend服务并获取容器日志
 */

const { chromium } = require('playwright');
const fs = require('fs');

const DOKPLOY_URL = "http://113.45.64.145:3000";
const EMAIL = "641600780@qq.com";
const PASSWORD = "353980swsgbo";

const getTimestamp = () => {
    const now = new Date();
    return now.toISOString().replace(/[:.]/g, '-').slice(0, -5);
};

const takeScreenshot = async (page, name) => {
    const filename = `container_logs_${name}_${getTimestamp()}.png`;
    await page.screenshot({ path: filename, fullPage: true });
    console.log(`📸 截图: ${filename}`);
    return filename;
};

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const main = async () => {
    console.log("🚀 开始获取Backend容器日志...");

    const browser = await chromium.launch({
        headless: false,
        slowMo: 600,
    });

    const page = await browser.newPage({
        viewport: { width: 1920, height: 1080 }
    });

    try {
        // 1. 登录
        console.log("🔐 登录Dokploy...");
        await page.goto(DOKPLOY_URL, { waitUntil: 'domcontentloaded' });
        await sleep(3000);

        await page.fill('input[name="email"]', EMAIL);
        await sleep(500);
        await page.fill('input[name="password"]', PASSWORD);
        await sleep(500);
        await takeScreenshot(page, "login_filled");

        await page.click('button[type="submit"]');
        console.log("⏳ 等待登录...");
        await sleep(6000);
        await takeScreenshot(page, "logged_in");

        // 2. 导航到项目
        console.log("🔍 导航到AI智能体简历项目...");

        // 检查当前URL
        let currentUrl = page.url();
        console.log(`当前URL: ${currentUrl}`);

        // 如果不在项目页面，点击项目
        if (!currentUrl.includes('ai-resume') && !currentUrl.includes('AI智能体简历')) {
            try {
                // 尝试直接点击项目链接
                const projectLink = await page.$('a:has-text("AI智能体简历")');
                if (projectLink) {
                    await projectLink.click();
                    console.log("✅ 已点击项目链接");
                    await sleep(4000);
                }
            } catch (error) {
                console.log("⚠️ 无法点击项目链接");
            }
        }

        await takeScreenshot(page, "project_page");
        currentUrl = page.url();
        console.log(`项目页面URL: ${currentUrl}`);

        // 3. 查找Backend服务/应用
        console.log("🔍 查找Backend服务...");

        // 首先列出页面上所有的服务和链接
        const allServices = await page.$$('[class*="service"], [class*="application"], [role="button"], a, button');
        console.log(`🔍 页面上有 ${allServices.length} 个可能的元素`);

        const backendServices = [];
        for (let i = 0; i < Math.min(allServices.length, 30); i++) {
            try {
                const text = await allServices[i].textContent();
                const href = await allServices[i].getAttribute('href');
                const className = await allServices[i].getAttribute('class');
                const dataTestId = await allServices[i].getAttribute('data-testid');

                if (text && text.trim()) {
                    const info = {
                        index: i,
                        text: text.trim().substring(0, 50),
                        href: href || '',
                        className: className || '',
                        dataTestId: dataTestId || ''
                    };

                    // 检查是否是backend相关
                    if (info.text.toLowerCase().includes('backend') ||
                        info.text.toLowerCase().includes('server') ||
                        info.text.toLowerCase().includes('api')) {
                        backendServices.push(info);
                        console.log(`🎯 Backend服务: ${JSON.stringify(info)}`);
                    } else if (i < 15) {
                        console.log(`  ${JSON.stringify(info)}`);
                    }
                }
            } catch (error) {
                // 忽略
            }
        }

        // 点击第一个backend服务
        if (backendServices.length > 0) {
            console.log(`✅ 找到 ${backendServices.length} 个Backend相关服务，点击第一个...`);
            const backendService = allServices[backendServices[0].index];
            await backendService.click();
            await sleep(3000);
            await takeScreenshot(page, "backend_service_clicked");
        } else {
            console.log("❌ 未找到Backend服务，尝试其他方法...");

            // 尝试查找所有可能包含服务列表的区域
            const serviceLists = await page.$$('[class*="list"], [class*="grid"], [role="list"]');
            console.log(`🔍 找到 ${serviceLists.length} 个可能的列表/网格区域`);

            for (let i = 0; i < serviceLists.length; i++) {
                try {
                    const listItems = await serviceLists[i].$$('div, a, button');
                    console.log(`  列表 ${i + 1}: ${listItems.length} 个项目`);

                    for (let j = 0; j < Math.min(listItems.length, 10); j++) {
                        const text = await listItems[j].textContent();
                        if (text && (text.toLowerCase().includes('backend') ||
                                     text.toLowerCase().includes('server'))) {
                            console.log(`  找到Backend服务: ${text.substring(0, 50)}`);
                            await listItems[j].click();
                            await sleep(3000);
                            await takeScreenshot(page, "backend_found");
                            break;
                        }
                    }
                } catch (error) {
                    // 忽略
                }
            }
        }

        // 4. 查找容器日志选项
        console.log("📋 查找容器日志...");

        // 截图当前页面
        await takeScreenshot(page, "service_page");

        // 查找所有可能的日志相关元素
        const allButtons = await page.$$('button, a, [role="tab"], [data-tab], div');
        console.log(`🔍 页面上有 ${allButtons.length} 个可能的按钮/链接`);

        const logRelatedElements = [];
        for (let i = 0; i < Math.min(allButtons.length, 50); i++) {
            try {
                const text = await allButtons[i].textContent();
                const className = await allButtons[i].getAttribute('class');
                const role = await allButtons[i].getAttribute('role');
                const dataTab = await allButtons[i].getAttribute('data-tab');

                if (text && text.trim()) {
                    const lowerText = text.toLowerCase();

                    // 查找日志相关
                    if (lowerText.includes('log') ||
                        lowerText.includes('console') ||
                        lowerText.includes('terminal') ||
                        lowerText.includes('output') ||
                        lowerText.includes('stdout') ||
                        lowerText.includes('stderr')) {

                        logRelatedElements.push({
                            index: i,
                            text: text.trim(),
                            className: className || '',
                            role: role || '',
                            dataTab: dataTab || ''
                        });

                        console.log(`🎯 日志相关: "${text.trim()}" (class: ${className}, role: ${role}, data-tab: ${dataTab})`);
                    }
                }
            } catch (error) {
                // 忽略
            }
        }

        // 点击日志相关的元素
        if (logRelatedElements.length > 0) {
            console.log(`✅ 找到 ${logRelatedElements.length} 个日志相关元素`);

            // 优先点击"Logs"或"日志"
            const priorityLogs = logRelatedElements.filter(e =>
                e.text.toLowerCase() === 'logs' ||
                e.text.toLowerCase() === '日志' ||
                e.text.includes('Logs') ||
                e.text.includes('日志')
            );

            const elementToClick = priorityLogs.length > 0 ?
                priorityLogs[0] : logRelatedElements[0];

            console.log(`🖱️ 点击: "${elementToClick.text}"`);
            const logElement = allButtons[elementToClick.index];
            await logElement.click();
            await sleep(4000);
            await takeScreenshot(page, "logs_clicked");

            // 5. 提取容器日志内容
            console.log("📋 提取容器日志内容...");

            // 尝试多种方式提取日志
            const logContentSelectors = [
                'pre',
                'code',
                '[class*="log"]',
                '[class*="terminal"]',
                '[class*="console"]',
                '[class*="output"]',
                '[class*="content"]',
                '[id*="log"]',
                '[role="log"]',
                '[data-testid*="log"]',
            ];

            let logsContent = '';
            let logsFound = false;

            for (const selector of logContentSelectors) {
                try {
                    console.log(`🔍 尝试选择器: ${selector}`);
                    const elements = await page.$$(selector);
                    if (elements.length > 0) {
                        console.log(`✅ 找到 ${elements.length} 个元素`);

                        for (let i = 0; i < elements.length; i++) {
                            const text = await elements[i].textContent();
                            if (text && text.trim().length > 10) {
                                if (!logsFound) {
                                    console.log("📄 日志内容预览（前1500字符）:");
                                    console.log(text.substring(0, 1500));
                                    logsFound = true;
                                }
                                logsContent += `\n\n=== ${selector} ${i + 1} ===\n${text}`;
                            }
                        }

                        if (logsFound) break;
                    }
                } catch (error) {
                    console.log(`⚠️ ${selector}: ${error.message}`);
                }
            }

            if (!logsFound) {
                // 获取整个页面内容
                console.log("📄 获取整个页面内容...");
                const pageContent = await page.textContent('body');
                logsContent = pageContent;
                console.log("📄 页面内容预览（前2000字符）:");
                console.log(pageContent.substring(0, 2000));
            }

            // 保存日志
            if (logsContent) {
                const logFile = `container_detailed_logs_${getTimestamp()}.txt`;
                fs.writeFileSync(logFile, logsContent, 'utf8');
                console.log(`💾 详细日志已保存: ${logFile}`);

                // 分析日志
                analyzeDetailedLogs(logsContent);
            }

        } else {
            console.log("❌ 未找到日志相关元素");

            // 列出所有可见的文本内容
            console.log("📄 页面可见文本内容:");
            const pageText = await page.textContent('body');
            const lines = pageText.split('\n').filter(line => line.trim().length > 0);
            lines.slice(0, 30).forEach((line, i) => {
                console.log(`  ${i + 1}: ${line.substring(0, 80)}`);
            });
        }

        // 6. 查找服务状态信息
        console.log("🔍 查找服务状态...");

        const statusIndicators = await page.$$('[class*="status"], [class*="badge"], [class*="indicator"]');
        console.log(`🔍 找到 ${statusIndicators.length} 个状态指示器`);

        for (let i = 0; i < Math.min(statusIndicators.length, 10); i++) {
            try {
                const text = await statusIndicators[i].textContent();
                const className = await statusIndicators[i].getAttribute('class');
                if (text && text.trim()) {
                    console.log(`  状态 ${i + 1}: "${text.trim()}" (class: ${className})`);
                }
            } catch (error) {
                // 忽略
            }
        }

        // 7. 查找可能的操作按钮
        console.log("🔍 查找操作按钮...");
        const actionButtons = await page.$$('button');
        console.log(`🔍 找到 ${actionButtons.length} 个按钮`);

        const actions = [];
        for (let i = 0; i < Math.min(actionButtons.length, 20); i++) {
            try {
                const text = await actionButtons[i].textContent();
                if (text && text.trim() &&
                    (text.toLowerCase().includes('restart') ||
                     text.toLowerCase().includes('stop') ||
                     text.toLowerCase().includes('start') ||
                     text.toLowerCase().includes('delete') ||
                     text.toLowerCase().includes('rebuild') ||
                     text.toLowerCase().includes('redploy'))) {
                    actions.push(text.trim());
                    console.log(`  操作: "${text.trim()}"`);
                }
            } catch (error) {
                // 忽略
            }
        }

        console.log("✅ 检查完成");
        await takeScreenshot(page, "final_state");

    } catch (error) {
        console.log(`❌ 发生错误: ${error.message}`);
        console.error(error);
        await takeScreenshot(page, "error");
    } finally {
        console.log("⏸️ 等待30秒后关闭...");
        await sleep(30000);
        await browser.close();
    }

    console.log("🏁 脚本执行完成");
};

const analyzeDetailedLogs = (content) => {
    console.log("\n🔍 详细分析日志内容...");

    const errorPatterns = [
        { pattern: 'error', type: 'ERROR', priority: 1 },
        { pattern: 'exception', type: 'CRITICAL', priority: 0 },
        { pattern: 'failed', type: 'ERROR', priority: 1 },
        { pattern: 'fatal', type: 'CRITICAL', priority: 0 },
        { pattern: 'traceback', type: 'CRITICAL', priority: 0 },
        { pattern: 'warning', type: 'WARNING', priority: 2 },
        { pattern: 'timeout', type: 'WARNING', priority: 2 },
        { pattern: 'connection refused', type: 'ERROR', priority: 1 },
        { pattern: 'connection reset', type: 'ERROR', priority: 1 },
        { pattern: 'cannot connect', type: 'ERROR', priority: 1 },
        { pattern: 'port already', type: 'ERROR', priority: 1 },
        { pattern: 'address already', type: 'ERROR', priority: 1 },
        { pattern: 'no such file', type: 'ERROR', priority: 1 },
        { pattern: 'module not found', type: 'ERROR', priority: 1 },
        { pattern: 'import error', type: 'ERROR', priority: 1 },
        { pattern: 'permission denied', type: 'ERROR', priority: 1 },
        { pattern: 'authentication failed', type: 'ERROR', priority: 1 },
        { pattern: 'database error', type: 'CRITICAL', priority: 0 },
        { pattern: 'sql error', type: 'CRITICAL', priority: 0 },
        { pattern: 'startup error', type: 'CRITICAL', priority: 0 },
        { pattern: 'boot error', type: 'CRITICAL', priority: 0 },
        { pattern: 'python', type: 'INFO', priority: 3 },
        { pattern: 'django', type: 'INFO', priority: 3 },
        { pattern: 'fastapi', type: 'INFO', priority: 3 },
        { pattern: 'uvicorn', type: 'INFO', priority: 3 },
        { pattern: 'gunicorn', type: 'INFO', priority: 3 },
        { pattern: 'listening on', type: 'INFO', priority: 3 },
        { pattern: 'application startup', type: 'INFO', priority: 3 },
        { pattern: 'starting', type: 'INFO', priority: 3 },
    ];

    const lines = content.split('\n');
    const findings = [];

    lines.forEach((line, index) => {
        const trimmedLine = line.trim();
        if (trimmedLine.length > 5) {
            const lowerLine = trimmedLine.toLowerCase();

            for (const { pattern, type, priority } of errorPatterns) {
                if (lowerLine.includes(pattern)) {
                    findings.push({
                        line: index + 1,
                        text: trimmedLine.substring(0, 200),
                        type: type,
                        priority: priority
                    });
                    break;
                }
            }
        }
    });

    if (findings.length > 0) {
        // 按优先级排序
        findings.sort((a, b) => a.priority - b.priority);

        console.log(`📊 发现 ${findings.length} 个相关条目:`);

        const critical = findings.filter(f => f.type === 'CRITICAL');
        const errors = findings.filter(f => f.type === 'ERROR');
        const warnings = findings.filter(f => f.type === 'WARNING');
        const info = findings.filter(f => f.type === 'INFO');

        console.log(`\n🔴 严重错误 (${critical.length}):`);
        critical.slice(0, 15).forEach(f => {
            console.log(`  行 ${f.line}: ${f.text}`);
        });

        console.log(`\n🟠 错误 (${errors.length}):`);
        errors.slice(0, 15).forEach(f => {
            console.log(`  行 ${f.line}: ${f.text}`);
        });

        console.log(`\n🟡 警告 (${warnings.length}):`);
        warnings.slice(0, 10).forEach(f => {
            console.log(`  行 ${f.line}: ${f.text}`);
        });

        console.log(`\n🔵 信息 (${info.length}):`);
        info.slice(0, 10).forEach(f => {
            console.log(`  行 ${f.line}: ${f.text}`);
        });

        // 保存详细分析
        const analysis = {
            timestamp: new Date().toISOString(),
            summary: {
                total: findings.length,
                critical: critical.length,
                errors: errors.length,
                warnings: warnings.length,
                info: info.length
            },
            findings: findings.slice(0, 200)
        };

        const analysisFile = `container_log_analysis_${getTimestamp()}.json`;
        fs.writeFileSync(analysisFile, JSON.stringify(analysis, null, 2), 'utf8');
        console.log(`\n💾 详细分析已保存: ${analysisFile}`);

    } else {
        console.log("✅ 日志内容中没有发现明显的错误或启动信息");
    }
};

main().catch(console.error);