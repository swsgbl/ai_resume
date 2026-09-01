#!/usr/bin/env python3
"""
使用Playwright自动化浏览器检查Dokploy中Backend服务的详细状态
"""
import asyncio
import json
import time
from datetime import datetime
from playwright.async_api import async_playwright

# 配置信息
DOKPLOY_URL = "http://113.45.64.145:3000"
EMAIL = "641600780@qq.com"
PASSWORD = "353980swsgbo"
PROJECT_NAME = "AI智能体简历"  # 可能的项目名称
SERVICE_NAME = "backend"  # 要检查的服务名称

async def take_screenshot(page, name):
    """保存截图"""
    filename = f"backend_debug_{name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
    await page.screenshot(path=filename, full_page=True)
    print(f"📸 截图已保存: {filename}")
    return filename

async def wait_and_click(page, selector, timeout=5000):
    """等待并点击元素"""
    try:
        await page.wait_for_selector(selector, timeout=timeout)
        await page.click(selector)
        return True
    except Exception as e:
        print(f"❌ 点击失败 {selector}: {e}")
        return False

async def extract_text_content(page, selector):
    """提取元素的文本内容"""
    try:
        element = await page.query_selector(selector)
        if element:
            return await element.text_content()
        return None
    except Exception as e:
        print(f"❌ 提取文本失败 {selector}: {e}")
        return None

async def login_to_dokploy(page):
    """登录到Dokploy"""
    print("🔐 开始登录Dokploy...")

    # 访问登录页面
    await page.goto(DOKPLOY_URL)
    await asyncio.sleep(2)

    # 检查是否需要登录
    current_url = page.url
    if "login" not in current_url.lower():
        print("✅ 已经登录，跳过登录步骤")
        return True

    # 截图登录页面
    await take_screenshot(page, "login_page")

    # 输入邮箱
    try:
        await page.fill('input[type="email"], input[name="email"], input[placeholder*="email" i], input[placeholder*="邮箱" i]', EMAIL)
        print("✅ 已输入邮箱")
    except Exception as e:
        print(f"❌ 输入邮箱失败: {e}")
        # 尝试查找所有输入框
        inputs = await page.query_selector_all('input')
        print(f"🔍 找到 {len(inputs)} 个输入框")

    await asyncio.sleep(1)

    # 输入密码
    try:
        await page.fill('input[type="password"], input[name="password"], input[placeholder*="password" i], input[placeholder*="密码" i]', PASSWORD)
        print("✅ 已输入密码")
    except Exception as e:
        print(f"❌ 输入密码失败: {e}")

    await asyncio.sleep(1)
    await take_screenshot(page, "login_filled")

    # 点击登录按钮
    try:
        login_selectors = [
            'button[type="submit"]',
            'button:has-text("登录")',
            'button:has-text("Login")',
            'button:has-text("Sign In")',
            'button:has-text("登录")',
        ]

        for selector in login_selectors:
            if await wait_and_click(page, selector, timeout=2000):
                print("✅ 已点击登录按钮")
                break
    except Exception as e:
        print(f"❌ 点击登录按钮失败: {e}")

    # 等待登录完成
    await asyncio.sleep(5)
    await take_screenshot(page, "after_login")

    # 检查是否登录成功
    current_url = page.url
    if "login" not in current_url.lower():
        print("✅ 登录成功")
        return True
    else:
        print("❌ 登录可能失败")
        return False

async def find_and_navigate_to_project(page):
    """查找并导航到项目"""
    print("🔍 查找项目...")
    await asyncio.sleep(2)

    # 截图主页面
    await take_screenshot(page, "main_dashboard")

    # 查找项目相关的链接或按钮
    project_found = False

    # 尝试多种方式查找项目
    search_strategies = [
        # 通过文本查找
        f'text="{PROJECT_NAME}"',
        f'text="ai-resume"',
        # 通过链接查找
        f'a:has-text("{PROJECT_NAME}")',
        f'a:has-text("ai-resume")',
        # 通过按钮查找
        f'button:has-text("{PROJECT_NAME}")',
        f'button:has-text("ai-resume")',
    ]

    for strategy in search_strategies:
        try:
            print(f"🔍 尝试策略: {strategy}")
            element = await page.query_selector(strategy)
            if element:
                print(f"✅ 找到项目元素: {strategy}")
                await element.click()
                project_found = True
                await asyncio.sleep(3)
                await take_screenshot(page, "project_page")
                break
        except Exception as e:
            print(f"⚠️ 策略 {strategy} 未找到: {e}")
            continue

    if not project_found:
        print("❌ 未找到项目，尝试手动导航...")
        # 列出所有可能的链接
        links = await page.query_selector_all('a, button')
        print(f"🔍 页面上有 {len(links)} 个链接/按钮")

        # 提取所有文本内容
        page_text = await page.text_content('body')
        print("📄 页面文本内容（前1000字符）:")
        print(page_text[:1000] if page_text else "无内容")

    return project_found

async def find_and_check_backend_service(page):
    """查找并检查Backend服务"""
    print("🔍 查找Backend服务...")

    # 截图项目页面
    await take_screenshot(page, "project_services")

    # 查找Backend相关的服务
    backend_selectors = [
        f'text="{SERVICE_NAME}"',
        f'text="{SERVICE_NAME.upper()}"',
        f'text="{SERVICE_NAME.capitalize()}"',
        f'text="Backend"',
        f'text="backend"',
    ]

    for selector in backend_selectors:
        try:
            element = await page.query_selector(selector)
            if element:
                print(f"✅ 找到Backend服务: {selector}")
                await element.click()
                await asyncio.sleep(3)
                await take_screenshot(page, "backend_service_page")

                # 检查服务详情
                await analyze_backend_service_details(page)
                return True
        except Exception as e:
            print(f"⚠️ 选择器 {selector} 未找到: {e}")
            continue

    # 如果没有找到，列出所有服务
    print("🔍 列出所有可用服务...")
    service_elements = await page.query_selector_all('[class*="service"], [class*="container"], [role="listitem"]')
    print(f"📋 找到 {len(service_elements)} 个可能的服务元素")

    for i, element in enumerate(service_elements[:10]):  # 只显示前10个
        try:
            text = await element.text_content()
            print(f"  {i+1}. {text[:100]}")  # 只显示前100字符
        except:
            pass

    return False

async def analyze_backend_service_details(page):
    """分析Backend服务的详细信息"""
    print("📊 分析Backend服务详情...")

    # 截图服务页面
    await take_screenshot(page, "backend_details")

    # 查找并点击日志按钮
    log_button_selectors = [
        'button:has-text("日志")',
        'button:has-text("Logs")',
        'button:has-text("Log")',
        'a:has-text("日志")',
        'a:has-text("Logs")',
        '[aria-label*="log" i]',
        '[title*="log" i]',
    ]

    for selector in log_button_selectors:
        try:
            if await wait_and_click(page, selector, timeout=3000):
                print("✅ 已打开日志页面")
                await asyncio.sleep(3)
                await extract_and_analyze_logs(page)
                break
        except Exception as e:
            print(f"⚠️ 点击日志按钮失败 {selector}: {e}")
            continue

    # 查找并点击终端/Console按钮
    console_selectors = [
        'button:has-text("终端")',
        'button:has-text("Console")',
        'button:has-text("Terminal")',
        'a:has-text("终端")',
        'a:has-text("Console")',
    ]

    for selector in console_selectors:
        try:
            if await wait_and_click(page, selector, timeout=3000):
                print("✅ 已打开终端页面")
                await asyncio.sleep(3)
                await take_screenshot(page, "backend_terminal")
                break
        except Exception as e:
            print(f"⚠️ 点击终端按钮失败 {selector}: {e}")
            continue

    # 检查健康状态
    await check_service_health(page)

    # 检查资源使用情况
    await check_resource_usage(page)

async def extract_and_analyze_logs(page):
    """提取并分析日志"""
    print("📋 提取日志内容...")

    await take_screenshot(page, "backend_logs")

    # 尝试多种方式提取日志
    log_selectors = [
        '[class*="log"]',
        '[class*="terminal"]',
        '[class*="console"]',
        'pre',
        'code',
        '[role="log"]',
        '[id*="log"]',
    ]

    logs_content = ""
    for selector in log_selectors:
        try:
            elements = await page.query_selector_all(selector)
            if elements:
                print(f"✅ 找到 {len(elements)} 个日志元素: {selector}")

                for i, element in enumerate(elements):
                    text = await element.text_content()
                    if text and len(text.strip()) > 0:
                        print(f"📄 日志块 {i+1} 内容（前500字符）:")
                        print(text[:500])
                        logs_content += f"\n\n--- 日志块 {i+1} ---\n{text}"

                if logs_content:
                    break
        except Exception as e:
            print(f"⚠️ 提取日志失败 {selector}: {e}")
            continue

    # 如果没有找到特定元素，尝试获取整个页面的文本
    if not logs_content:
        print("📄 获取整个页面的文本内容...")
        page_text = await page.text_content('body')
        logs_content = page_text if page_text else ""

    # 保存日志到文件
    if logs_content:
        log_filename = f"backend_logs_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        with open(log_filename, 'w', encoding='utf-8') as f:
            f.write(logs_content)
        print(f"💾 日志已保存到: {log_filename}")

        # 分析日志中的错误
        analyze_logs_for_errors(logs_content)
    else:
        print("❌ 未能提取到日志内容")

def analyze_logs_for_errors(logs_content):
    """分析日志中的错误信息"""
    print("\n🔍 分析日志中的错误信息...")

    error_patterns = [
        'Error', 'Exception', 'Failed', 'failed', 'ERROR', 'error',
        'Traceback', 'Warning', 'WARNING', 'warning', 'Fatal', 'fatal',
        'Connection refused', 'Connection reset', 'Timeout', 'timeout',
        'Cannot', 'Unable', 'Invalid', 'Missing', 'Not found', 'not found',
        'Permission denied', 'Access denied', 'Authentication failed',
        'Database error', 'SQL error', 'Port already in use',
        'Address already in use', 'No such file', 'Module not found',
        'Import error', 'Dependency', 'Package', 'Installation failed'
    ]

    found_errors = []
    lines = logs_content.split('\n')

    for i, line in enumerate(lines):
        for pattern in error_patterns:
            if pattern.lower() in line.lower():
                # 获取上下文（前后几行）
                context_start = max(0, i - 2)
                context_end = min(len(lines), i + 3)
                context = lines[context_start:context_end]

                found_errors.append({
                    'pattern': pattern,
                    'line': line.strip(),
                    'line_number': i + 1,
                    'context': context
                })
                break

    if found_errors:
        print(f"❌ 发现 {len(found_errors)} 个可能的错误:")

        # 按严重程度分类
        critical_errors = [e for e in found_errors if any(p in e['line'].lower() for p in ['error', 'exception', 'failed', 'fatal', 'traceback'])]
        warnings = [e for e in found_errors if any(p in e['line'].lower() for p in ['warning', 'timeout'])]

        print(f"\n🔴 严重错误 ({len(critical_errors)}):")
        for error in critical_errors[:10]:  # 只显示前10个
            print(f"  行 {error['line_number']}: {error['line'][:100]}")

        print(f"\n🟡 警告 ({len(warnings)}):")
        for warning in warnings[:5]:  # 只显示前5个
            print(f"  行 {warning['line_number']}: {warning['line'][:100]}")

        # 保存错误报告
        error_report = {
            'timestamp': datetime.now().isoformat(),
            'total_errors': len(found_errors),
            'critical_errors': len(critical_errors),
            'warnings': len(warnings),
            'errors': found_errors
        }

        error_report_file = f"backend_error_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(error_report_file, 'w', encoding='utf-8') as f:
            json.dump(error_report, f, ensure_ascii=False, indent=2)
        print(f"\n💾 错误报告已保存: {error_report_file}")
    else:
        print("✅ 未发现明显的错误信息")

async def check_service_health(page):
    """检查服务健康状态"""
    print("🏥 检查服务健康状态...")

    # 查找健康状态指示器
    health_selectors = [
        '[class*="health"]',
        '[class*="status"]',
        '[aria-label*="health" i]',
        '[aria-label*="status" i]',
    ]

    for selector in health_selectors:
        try:
            elements = await page.query_selector_all(selector)
            if elements:
                print(f"✅ 找到 {len(elements)} 个健康状态元素")
                for i, element in enumerate(elements[:5]):
                    text = await element.text_content()
                    print(f"  健康状态 {i+1}: {text}")
        except Exception as e:
            print(f"⚠️ 检查健康状态失败 {selector}: {e}")

async def check_resource_usage(page):
    """检查资源使用情况"""
    print("📊 检查资源使用情况...")

    # 查找资源使用信息
    resource_selectors = [
        '[class*="cpu"]',
        '[class*="memory"]',
        '[class*="resource"]',
        '[class*="usage"]',
        'text=CPU',
        'text=Memory',
        'text=内存',
    ]

    for selector in resource_selectors:
        try:
            elements = await page.query_selector_all(selector)
            if elements:
                print(f"✅ 找到 {len(elements)} 个资源信息元素")
                for i, element in enumerate(elements[:5]):
                    text = await element.text_content()
                    print(f"  资源信息 {i+1}: {text}")
        except Exception as e:
            print(f"⚠️ 检查资源使用失败 {selector}: {e}")

async def main():
    """主函数"""
    print("🚀 开始检查Dokploy Backend服务状态...")
    print(f"📅 时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🌐 目标: {DOKPLOY_URL}")
    print(f"📧 邮箱: {EMAIL}")

    async with async_playwright() as playwright:
        # 启动浏览器
        browser = await playwright.chromium.launch(
            headless=False,  # 显示浏览器窗口
            slow_mo=1000,    # 慢速操作以便观察
        )

        context = await browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        )

        page = await context.new_page()

        try:
            # 1. 登录
            login_success = await login_to_dokploy(page)
            if not login_success:
                print("❌ 登录失败，终止检查")
                return

            # 2. 查找项目
            project_found = await find_and_navigate_to_project(page)
            if not project_found:
                print("❌ 未找到项目，尝试直接检查服务列表...")
                # 可以添加其他导航逻辑

            # 3. 查找Backend服务
            backend_found = await find_and_check_backend_service(page)
            if not backend_found:
                print("❌ 未找到Backend服务")

            print("✅ 检查完成")

        except Exception as e:
            print(f"❌ 发生错误: {e}")
            import traceback
            traceback.print_exc()
        finally:
            # 等待用户查看
            print("⏸️ 等待10秒后关闭浏览器...")
            await asyncio.sleep(10)
            await browser.close()

    print(f"🏁 检查结束于: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    asyncio.run(main())