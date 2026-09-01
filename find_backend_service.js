/**
 * 精确查找Backend服务并获取真实容器日志
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

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const main = async () => {
    console.log("🚀 开始查找Backend服务...");

    const browser = await chromium.launch({
        headless: false,
        slowMo: 500,
    });

    const page = await browser.newPage({
        viewport: { width: 1920, height: 1080 }
    });

    try {
        // 1. 登录
        console.log("🔐 登录Dokploy...");
        await page.goto(DOKPLOY_URL, { waitUntil: 'domcontentloaded' });
        await sleep(2000);

        await page.fill('input[name="email"]', EMAIL);
        await sleep(500);
        await page.fill('input[name="password"]', PASSWORD);
        await sleep(500);
        await page.click('button[type="submit"]');
        console.log("⏳ 等待登录...");
        await sleep(5000);

        // 2. 直接访问项目URL
        const projectUrl = "http://113.45.64.145:3000/dashboard/project/hKHDNMV9pJ9GDVhXMJUSX/environment/knUE3WmJdtKEkJqX8rff0";
        console.log(`🔍 直接访问项目: ${projectUrl}`);
        await page.goto(projectUrl, { waitUntil: 'networkidle' });
        await sleep(3000);

        // 截图项目页面
        await page.screenshot({ path: `project_page_${getTimestamp()}.png`, fullPage: true });
        console.log("📸 已截图项目页面");

        // 3. 分析页面结构，查找服务/应用列表
        console.log("🔍 分析页面结构...");

        // 获取页面的所有文本内容
        const pageText = await page.textContent('body');
        console.log("📄 页面文本内容（前3000字符）:");
        console.log(pageText.substring(0, 3000));

        // 查找所有可能的容器或服务卡片
        const possibleCards = await page.$$('[class*="card"], [class*="container"], [class*="service"], [class*="application"], [class*="item"]');
        console.log(`🔍 找到 ${possibleCards.length} 个可能的卡片/容器`);

        let backendServiceElement = null;
        let serviceInfo = null;

        for (let i = 0; i < possibleCards.length; i++) {
            try {
                const text = await possibleCards[i].textContent();
                const className = await possibleCards[i].getAttribute('class');

                if (text) {
                    console.log(`\n卡片 ${i + 1}:`);
                    console.log(`  Class: ${className}`);
                    console.log(`  Text: ${text.substring(0, 200)}`);

                    // 检查是否包含backend相关内容
                    const lowerText = text.toLowerCase();
                    if ((lowerText.includes('backend') ||
                         lowerText.includes('server') ||
                         lowerText.includes('api')) &&
                        (lowerText.includes('starting') ||
                         lowerText.includes('running') ||
                         lowerText.includes('stopped') ||
                         lowerText.includes('error') ||
                         lowerText.includes('端口') ||
                         lowerText.includes('port'))) {

                        console.log("✅ 找到可能的Backend服务!");
                        backendServiceElement = possibleCards[i];
                        serviceInfo = {
                            index: i,
                            text: text.substring(0, 500),
                            className: className
                        };
                        break;
                    }
                }
            } catch (error) {
                console.log(`⚠️ 分析卡片 ${i + 1} 失败: ${error.message}`);
            }
        }

        if (backendServiceElement) {
            console.log("✅ 找到Backend服务元素");
            console.log("服务信息:", serviceInfo);

            // 点击Backend服务
            await backendServiceElement.click();
            await sleep(3000);

            const serviceName = `backend_service_${getTimestamp()}.png`;
            await page.screenshot({ path: serviceName, fullPage: true });
            console.log(`📸 已截图Backend服务: ${serviceName}`);

            // 4. 查找容器日志
            console.log("📋 查找容器日志...");

            // 查找所有可能的日志链接或按钮
            const allLinks = await page.$$('a, button, [role="tab"]');
            console.log(`🔍 页面有 ${allLinks.length} 个链接/按钮`);

            const logLinks = [];
            for (let i = 0; i < Math.min(allLinks.length, 50); i++) {
                try {
                    const text = await allLinks[i].textContent();
                    const href = await allLinks[i].getAttribute('href');
                    const className = await allLinks[i].getAttribute('class');

                    if (text && text.trim()) {
                        const lowerText = text.toLowerCase().trim();

                        if (lowerText.includes('log') ||
                            lowerText.includes('console') ||
                            lowerText.includes('terminal') ||
                            lowerText.includes('output')) {

                            logLinks.push({
                                index: i,
                                text: text.trim(),
                                href: href || '',
                                className: className || ''
                            });

                            console.log(`🎯 日志链接: "${text.trim()}"`);
                        }
                    }
                } catch (error) {
                    // 忽略
                }
            }

            if (logLinks.length > 0) {
                console.log(`✅ 找到 ${logLinks.length} 个日志相关链接`);

                // 点击第一个日志链接
                const firstLogLink = logLinks[0];
                console.log(`🖱️ 点击日志链接: "${firstLogLink.text}"`);

                const logElement = allLinks[firstLogLink.index];
                await logElement.click();
                await sleep(4000);

                const logsPageName = `backend_logs_page_${getTimestamp()}.png`;
                await page.screenshot({ path: logsPageName, fullPage: true });
                console.log(`📸 已截图日志页面: ${logsPageName}`);

                // 5. 提取容器日志内容
                console.log("📋 提取容器日志...");

                // 尝试多种方式提取日志
                const logSelectors = [
                    'pre',
                    'code',
                    '[class*="log"]',
                    '[class*="terminal"]',
                    '[class*="console"]',
                    '[class*="output"]',
                    '[class*="stdout"]',
                    '[class*="stderr"]',
                    '[class*="content"]',
                ];

                let logsContent = '';
                let logsFound = false;

                for (const selector of logSelectors) {
                    try {
                        const elements = await page.$$(selector);
                        if (elements.length > 0) {
                            console.log(`✅ 找到 ${elements.length} 个 ${selector} 元素`);

                            for (let i = 0; i < elements.length; i++) {
                                const text = await elements[i].textContent();
                                if (text && text.trim().length > 20) {
                                    if (!logsFound) {
                                        console.log("📄 找到日志内容（前2000字符）:");
                                        console.log(text.substring(0, 2000));
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
                    const pageContent = await page.textContent('body');
                    logsContent = pageContent;
                    console.log("📄 整个页面内容（前3000字符）:");
                    console.log(pageContent.substring(0, 3000));
                }

                // 保存日志
                if (logsContent) {
                    const logFile = `backend_real_logs_${getTimestamp()}.txt`;
                    fs.writeFileSync(logFile, logsContent, 'utf8');
                    console.log(`💾 真实容器日志已保存: ${logFile}`);

                    // 分析日志
                    analyzeContainerLogs(logsContent);
                }

            } else {
                console.log("❌ 未找到日志链接");

                // 列出页面上的所有文本
                const visibleText = await page.textContent('body');
                const lines = visibleText.split('\n')
                    .map(line => line.trim())
                    .filter(line => line.length > 5 && line.length < 200);

                console.log("📄 页面可见文本（前50行）:");
                lines.slice(0, 50).forEach((line, i) => {
                    console.log(`  ${i + 1}: ${line}`);
                });
            }

        } else {
            console.log("❌ 未找到Backend服务");

            // 查找所有包含服务状态的部分
            const statusElements = await page.$$('[class*="status"], [class*="badge"], [class*="indicator"]');
            console.log(`🔍 找到 ${statusElements.length} 个状态元素`);

            for (let i = 0; i < Math.min(statusElements.length, 10); i++) {
                try {
                    const text = await statusElements[i].textContent();
                    const className = await statusElements[i].getAttribute('class');
                    console.log(`  状态 ${i + 1}: "${text}" (class: ${className})`);
                } catch (error) {
                    // 忽略
                }
            }

            // 列出所有链接
            const allLinks = await page.$$('a');
            console.log(`🔍 页面有 ${allLinks.length} 个链接`);

            for (let i = 0; i < Math.min(allLinks.length, 20); i++) {
                try {
                    const text = await allLinks[i].textContent();
                    const href = await allLinks[i].getAttribute('href');
                    if (text && text.trim() && href) {
                        console.log(`  链接 ${i + 1}: "${text.trim()}" -> ${href}`);
                    }
                } catch (error) {
                    // 忽略
                }
            }
        }

        console.log("✅ 检查完成");

    } catch (error) {
        console.log(`❌ 发生错误: ${error.message}`);
        console.error(error);
    } finally {
        console.log("⏸️ 等待20秒后关闭...");
        await sleep(20000);
        await browser.close();
    }

    console.log("🏁 脚本执行完成");
};

const analyzeContainerLogs = (content) => {
    console.log("\n🔍 分析容器日志...");

    // 查找关键错误和启动信息
    const patterns = {
        critical: ['exception', 'fatal', 'traceback', 'panic', 'crash', 'segfault'],
        error: ['error', 'failed', 'failure', 'cannot', 'unable', 'invalid'],
        warning: ['warning', 'timeout', 'deprecated'],
        connection: ['connection refused', 'connection reset', 'cannot connect', 'network'],
        database: ['database error', 'sql error', 'mysql', 'postgresql', 'mongodb'],
        python: ['python', 'django', 'flask', 'fastapi', 'uvicorn', 'gunicorn'],
        startup: ['starting', 'started', 'listening', 'running', 'application startup'],
        port: ['port', 'bind', 'address', 'host'],
    };

    const lines = content.split('\n');
    const findings = {};

    // 初始化分类
    Object.keys(patterns).forEach(key => findings[key] = []);

    lines.forEach((line, index) => {
        const trimmedLine = line.trim();
        if (trimmedLine.length > 10) {
            const lowerLine = trimmedLine.toLowerCase();

            Object.entries(patterns).forEach(([category, keywords]) => {
                for (const keyword of keywords) {
                    if (lowerLine.includes(keyword)) {
                        findings[category].push({
                            line: index + 1,
                            text: trimmedLine.substring(0, 200),
                            keyword: keyword
                        });
                        break;
                    }
                }
            });
        }
    });

    // 输出分析结果
    console.log("📊 日志分析结果:");

    Object.entries(findings).forEach(([category, items]) => {
        if (items.length > 0) {
            console.log(`\n${category.toUpperCase()} (${items.length}):`);
            items.slice(0, 10).forEach(item => {
                console.log(`  行 ${item.line}: ${item.text.substring(0, 100)}`);
            });
        }
    });

    // 特别关注严重错误和启动问题
    const allErrors = [...findings.critical, ...findings.error, ...findings.connection, ...findings.database];
    if (allErrors.length > 0) {
        console.log(`\n🔴 发现 ${allErrors.length} 个严重问题:`);
        allErrors.slice(0, 15).forEach(item => {
            console.log(`  行 ${item.line}: ${item.text.substring(0, 120)}`);
        });

        // 保存详细错误报告
        const errorReport = {
            timestamp: new Date().toISOString(),
            totalErrors: allErrors.length,
            errors: allErrors.slice(0, 50)
        };

        const reportFile = `backend_errors_report_${getTimestamp()}.json`;
        fs.writeFileSync(reportFile, JSON.stringify(errorReport, null, 2), 'utf8');
        console.log(`💾 错误报告已保存: ${reportFile}`);
    }

    // 检查启动信息
    if (findings.startup.length > 0) {
        console.log(`\n🔵 启动信息:`);
        findings.startup.slice(0, 10).forEach(item => {
            console.log(`  行 ${item.line}: ${item.text.substring(0, 100)}`);
        });
    }
};

main().catch(console.error);