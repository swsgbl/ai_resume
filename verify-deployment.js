const { chromium } = require('playwright');

async function verifyDeployment() {
    const browser = await chromium.launch({
        headless: false,
        slowMo: 200
    });

    const page = await browser.newPage();

    try {
        console.log('🔍 开始验证部署状态...');

        // 1. 检查Frontend服务
        console.log('🌐 检查Frontend服务...');
        try {
            const frontendResponse = await page.goto('http://113.45.64.145:3000', {
                waitUntil: 'domcontentloaded',
                timeout: 15000
            });

            if (frontendResponse && frontendResponse.ok()) {
                console.log('✅ Frontend服务可访问');
            } else {
                console.log('⚠️ Frontend服务响应异常:', frontendResponse?.status());
            }
        } catch (error) {
            console.log('❌ Frontend服务访问失败:', error.message);
        }

        // 2. 检查Backend服务
        console.log('🔧 检查Backend服务...');
        try {
            const backendResponse = await page.goto('http://113.45.64.145:8000/health', {
                waitUntil: 'domcontentloaded',
                timeout: 15000
            });

            if (backendResponse && backendResponse.ok()) {
                const healthData = await backendResponse.json();
                console.log('✅ Backend服务健康检查通过:', healthData);
            } else {
                console.log('⚠️ Backend服务响应异常:', backendResponse?.status());

                // 尝试获取响应文本
                try {
                    const errorText = await backendResponse.text();
                    console.log('📄 错误响应内容:', errorText.substring(0, 200));
                } catch (e) {
                    // 忽略文本读取错误
                }
            }
        } catch (error) {
            console.log('❌ Backend服务访问失败:', error.message);

            // 尝试访问根路径
            try {
                console.log('🔄 尝试访问Backend根路径...');
                const rootResponse = await page.goto('http://113.45.64.145:8000/', {
                    waitUntil: 'domcontentloaded',
                    timeout: 10000
                });
                console.log('📄 Backend根路径响应:', rootResponse?.status());
            } catch (rootError) {
                console.log('❌ Backend根路径也无法访问');
            }
        }

        // 3. 检查API端点
        console.log('🔌 检查API端点...');
        const apiEndpoints = [
            '/api/v1/health',
            '/api/health',
            '/health',
            '/docs',
            '/api/docs'
        ];

        for (const endpoint of apiEndpoints) {
            try {
                const url = `http://113.45.64.145:8000${endpoint}`;
                console.log(`🔍 检查 ${url}...`);

                const response = await page.goto(url, {
                    waitUntil: 'domcontentloaded',
                    timeout: 10000
                });

                if (response && response.ok()) {
                    console.log(`✅ 端点 ${endpoint} 可访问 - 状态: ${response.status()}`);
                    break; // 找到一个可访问的端点就停止
                }
            } catch (error) {
                console.log(`⚠️ 端点 ${endpoint} 不可访问`);
            }
        }

        // 4. 检查Dokploy面板状态
        console.log('🎛️ 检查Dokploy面板状态...');
        try {
            await page.goto('http://113.45.64.145:3000', {
                waitUntil: 'domcontentloaded',
                timeout: 15000
            });

            // 登录（如果需要）
            const loginNeeded = await page.locator('input[type="email"]').count() > 0;
            if (loginNeeded) {
                console.log('📝 需要登录Dokploy面板...');

                await page.locator('input[type="email"]').first().fill('641600780@qq.com');
                await page.waitForTimeout(500);
                await page.locator('input[type="password"]').first().fill('353980swsgbo');
                await page.waitForTimeout(500);

                // 查找并点击登录按钮
                const loginButton = await page.locator('button').filter(async button => {
                    const text = await button.textContent();
                    return text && (text.includes('登录') || text.toLowerCase().includes('login') || text.includes('Sign'));
                }).first();

                await loginButton.click();
                await page.waitForTimeout(5000);
            }

            // 查找AI智能体简历项目
            console.log('🔍 在Dokploy中查找项目状态...');

            const projectStatus = await page.evaluate(async () => {
                // 等待页面加载完成
                await new Promise(resolve => setTimeout(resolve, 2000));

                // 查找包含"AI智能体简历"的项目卡片
                const allElements = document.querySelectorAll('*');
                let projectInfo = null;

                for (const element of allElements) {
                    const text = element.textContent || '';

                    if (text.includes('AI智能体简历') && text.length < 500) {
                        // 查找父元素中的状态信息
                        let parent = element.parentElement;
                        while (parent && parent !== document.body) {
                            const parentText = parent.textContent || '';

                            // 查找包含状态信息的关键词
                            if (parentText.includes('running') || parentText.includes('stopped') ||
                                parentText.includes('deploying') || parentText.includes('failed') ||
                                parentText.includes('运行') || parentText.includes('停止') ||
                                parentText.includes('部署中') || parentText.includes('失败')) {

                                projectInfo = {
                                    found: true,
                                    text: parentText.substring(0, 300),
                                    className: parent.className
                                };
                                break;
                            }
                            parent = parent.parentElement;
                        }

                        if (projectInfo) break;
                    }
                }

                return projectInfo;
            });

            if (projectStatus && projectStatus.found) {
                console.log('📊 项目状态信息:', projectStatus.text);
            } else {
                console.log('⚠️ 无法从Dokploy面板获取项目状态');
            }

            // 截图Dokploy面板
            await page.screenshot({ path: 'dokploy-status-verify.png' });
            console.log('📸 已保存Dokploy状态截图');

        } catch (error) {
            console.log('❌ 检查Dokploy面板失败:', error.message);
        }

        console.log('✅ 部署验证完成');

        // 保持浏览器打开10秒以便查看
        await page.waitForTimeout(10000);

    } catch (error) {
        console.error('❌ 验证过程发生错误:', error.message);
    } finally {
        await browser.close();
        console.log('👋 浏览器已关闭');
    }
}

// 运行验证脚本
verifyDeployment().catch(console.error);