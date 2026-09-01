#!/usr/bin/env python3
"""
========================================
自主迭代测试系统 - Python版本
========================================
每5分钟自动执行，智能分析测试结果，
自动发现问题、生成修复建议、持续优化
"""

import asyncio
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List
import re

# 项目路径
PROJECT_ROOT = Path("/run/media/hongfu/软件/ai_resume")
WEB_DIR = PROJECT_ROOT / "ai-resume-web"
BACKEND_DIR = PROJECT_ROOT / "backend"
LOG_DIR = PROJECT_ROOT / "test-logs"
REPORT_DIR = PROJECT_ROOT / "test-reports"
MEMORY_DIR = PROJECT_ROOT / ".claude" / "projects" / "-run-media-hongfu----ai-resume" / "memory"

# 确保目录存在
for d in [LOG_DIR, REPORT_DIR, MEMORY_DIR]:
    d.mkdir(parents=True, exist_ok=True)


class Colors:
    """终端颜色"""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'


def log(msg: str, color: str = Colors.END) -> None:
    """带颜色的日志输出"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"{color}[{timestamp}] {msg}{Colors.END}")


def log_section(title: str) -> None:
    """输出分隔标题"""
    print()
    log("=" * 50, Colors.BOLD)
    log(f"  {title}", Colors.BOLD)
    log("=" * 50, Colors.BOLD)


class TestHistory:
    """测试历史记录"""

    def __init__(self):
        self.history_file = MEMORY_DIR / "test-history.json"
        self.history = self._load_history()

    def _load_history(self) -> Dict[str, Any]:
        """加载历史记录"""
        if self.history_file.exists():
            try:
                return json.loads(self.history_file.read_text())
            except:
                return {"runs": []}
        return {"runs": []}

    def _save_history(self) -> None:
        """保存历史记录"""
        self.history_file.write_text(json.dumps(self.history, indent=2, ensure_ascii=False))

    def add_run(self, result: Dict[str, Any]) -> None:
        """添加一次测试运行"""
        self.history["runs"].append({
            "timestamp": datetime.now().isoformat(),
            "result": result
        })
        # 只保留最近100次
        if len(self.history["runs"]) > 100:
            self.history["runs"] = self.history["runs"][-100:]
        self._save_history()

    def get_trends(self) -> Dict[str, Any]:
        """获取趋势分析"""
        if len(self.history["runs"]) < 2:
            return {"status": "insufficient_data"}

        recent = self.history["runs"][-10:]
        total = len(recent)
        passed = sum(1 for r in recent if r["result"].get("success", False))
        failed = total - passed

        return {
            "status": "analyzed",
            "total_runs": total,
            "passed": passed,
            "failed": failed,
            "pass_rate": f"{(passed/total*100):.1f}%" if total > 0 else "0%",
            "last_run": self.history["runs"][-1]["timestamp"] if self.history["runs"] else None
        }


class ServiceManager:
    """服务管理器"""

    async def check_backend(self) -> bool:
        """检查后端服务"""
        try:
            result = subprocess.run(
                ["curl", "-s", "http://localhost:8000/health"],
                capture_output=True,
                timeout=5
            )
            if result.returncode == 0:
                log("✓ 后端服务运行正常", Colors.GREEN)
                return True
        except:
            pass

        log("⚠ 后端服务未运行", Colors.YELLOW)
        return False

    async def check_frontend(self) -> bool:
        """检查前端服务"""
        try:
            result = subprocess.run(
                ["curl", "-s", "http://localhost:3000"],
                capture_output=True,
                timeout=5
            )
            if result.returncode == 0:
                log("✓ 前端服务运行正常", Colors.GREEN)
                return True
        except:
            pass

        log("⚠ 前端服务未运行", Colors.YELLOW)
        return False


class TestRunner:
    """测试运行器"""

    def __init__(self, history: TestHistory):
        self.history = history

    async def run_e2e_tests(self) -> Dict[str, Any]:
        """运行E2E测试"""
        log_section("执行 E2E 测试")

        os.chdir(WEB_DIR)

        try:
            result = subprocess.run(
                ["npm", "test"],
                capture_output=True,
                text=True,
                timeout=300  # 5分钟超时
            )

            output = result.stdout + result.stderr

            # 解析结果
            passed = result.returncode == 0
            failed_count = len(re.findall(r'failed', output.lower()))

            log(f"{'✓ 测试通过' if passed else '✗ 测试失败'}", Colors.GREEN if passed else Colors.RED)

            return {
                "success": passed,
                "failed_count": failed_count,
                "output": output[-2000:] if len(output) > 2000 else output  # 只保留最后2000字符
            }

        except subprocess.TimeoutExpired:
            log("✗ 测试超时", Colors.RED)
            return {"success": False, "error": "timeout"}
        except Exception as e:
            log(f"✗ 测试执行出错: {e}", Colors.RED)
            return {"success": False, "error": str(e)}

    async def run_lint_check(self) -> Dict[str, Any]:
        """运行代码规范检查"""
        log_section("执行代码规范检查")

        os.chdir(WEB_DIR)

        try:
            result = subprocess.run(
                ["npm", "run", "lint"],
                capture_output=True,
                text=True,
                timeout=60
            )

            passed = result.returncode == 0
            log(f"{'✓ 规范检查通过' if passed else '⚠ 发现规范问题'}", Colors.GREEN if passed else Colors.YELLOW)

            return {
                "success": passed,
                "output": result.stderr if result.stderr else result.stdout
            }

        except Exception as e:
            log(f"⚠ 规范检查出错: {e}", Colors.YELLOW)
            return {"success": False, "error": str(e)}


class IssueDetector:
    """问题检测器"""

    async def detect_all(self) -> List[Dict[str, Any]]:
        """检测所有问题"""
        log_section("检测潜在问题")

        issues = []

        # 1. 检测 console.log
        issues.extend(await self._detect_console_logs())

        # 2. 检测 TODO 注释
        issues.extend(await self._detect_todos())

        # 3. 检测大文件
        issues.extend(await self._detect_large_files())

        # 4. 检测安全漏洞
        issues.extend(await self._detect_security_issues())

        log(f"发现 {len(issues)} 个问题", Colors.YELLOW if issues else Colors.GREEN)
        return issues

    async def _detect_console_logs(self) -> List[Dict[str, Any]]:
        """检测未清理的 console.log"""
        issues = []
        for file in (WEB_DIR / "src").rglob("*.tsx"):
            content = file.read_text()
            if "console.log" in content:
                issues.append({
                    "type": "code_quality",
                    "severity": "info",
                    "file": str(file.relative_to(WEB_DIR)),
                    "message": "包含 console.log",
                    "suggestion": "清理调试代码"
                })
        return issues

    async def _detect_todos(self) -> List[Dict[str, Any]]:
        """检测 TODO 注释"""
        issues = []
        pattern = re.compile(r'(TODO|FIXME):?\s*(.+)', re.IGNORECASE)

        for file in (WEB_DIR / "src").rglob("*.tsx"):
            content = file.read_text()
            for match in pattern.finditer(content):
                issues.append({
                    "type": "todo",
                    "severity": "info",
                    "file": str(file.relative_to(WEB_DIR)),
                    "message": match.group(2).strip(),
                    "suggestion": "完成待办事项"
                })
        return issues

    async def _detect_large_files(self) -> List[Dict[str, Any]]:
        """检测大文件"""
        issues = []
        for file in (WEB_DIR / "src").rglob("*.tsx"):
            lines = len(file.read_text().split('\n'))
            if lines > 300:
                issues.append({
                    "type": "code_quality",
                    "severity": "warning",
                    "file": str(file.relative_to(WEB_DIR)),
                    "message": f"文件过大 ({lines} 行)",
                    "suggestion": "考虑拆分为多个模块"
                })
        return issues

    async def _detect_security_issues(self) -> List[Dict[str, Any]]:
        """检测安全漏洞"""
        issues = []
        try:
            result = subprocess.run(
                ["npm", "audit", "--production", "--json"],
                capture_output=True,
                text=True,
                timeout=30,
                cwd=WEB_DIR
            )
            if result.returncode != 0:
                data = json.loads(result.stdout)
                vulns = data.get("metadata", {}).get("vulnerabilities", {})
                total = sum(vulns.values())
                if total > 0:
                    issues.append({
                        "type": "security",
                        "severity": "error",
                        "message": f"发现 {total} 个安全漏洞",
                        "suggestion": "运行 npm audit fix"
                    })
        except:
            pass
        return issues


class ReportGenerator:
    """报告生成器"""

    def __init__(self, history: TestHistory):
        self.history = history

    def generate(self, test_result: Dict[str, Any], issues: List[Dict[str, Any]]) -> str:
        """生成测试报告"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_file = REPORT_DIR / f"test-report-{timestamp}.md"

        trends = self.history.get_trends()

        content = f"""# AI Resume 自动化测试报告

**生成时间**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
**测试轮次**: {len(self.history.history.get('runs', []))}

## 测试摘要

| 指标 | 结果 |
|------|------|
| E2E 测试 | {'✓ 通过' if test_result.get('e2e', {}).get('success') else '✗ 失败'} |
| 规范检查 | {'✓ 通过' if test_result.get('lint', {}).get('success') else '⚠ 有问题'} |
| 发现问题 | {len(issues)} 个 |

## 趋势分析

- 近10次通过率: {trends.get('pass_rate', 'N/A')}
- 最近运行: {trends.get('last_run', 'N/A')}

## 发现的问题

"""

        if issues:
            for issue in issues[:20]:  # 最多显示20个
                severity_icon = {
                    "error": "🔴",
                    "warning": "🟡",
                    "info": "🔵"
                }.get(issue.get("severity", "info"), "⚪")

                content += f"\n{severity_icon} **{issue.get('file', 'N/A')}**\n"
                content += f"  - {issue.get('message', 'N/A')}\n"
                content += f"  - 建议: {issue.get('suggestion', 'N/A')}\n"
        else:
            content += "\n✓ 未发现明显问题\n"

        content += f"""

## 优化建议

### 自动优化任务
- [ ] 清理调试代码 (console.log)
- [ ] 完成待办事项 (TODO/FIXME)
- [ ] 拆分大文件 (>300行)
- [ ] 修复安全漏洞

### 下一步行动
"""

        if not test_result.get('e2e', {}).get('success'):
            content += "1. **优先**: 修复 E2E 测试失败\n"

        if not test_result.get('lint', {}).get('success'):
            content += "2. **优先**: 修复代码规范问题\n"

        content += "3. 考虑增加单元测试覆盖率\n"
        content += "4. 检查性能优化空间\n"

        report_file.write_text(content)
        log(f"✓ 报告已生成: {report_file}", Colors.GREEN)

        return str(report_file)


class AutoOptimizer:
    """自动优化器"""

    def __init__(self):
        self.suggestions_file = MEMORY_DIR / "auto-optimization-tasks.md"

    def generate_tasks(self, issues: List[Dict[str, Any]]) -> None:
        """生成优化任务列表"""
        content = f"""# 自动优化任务

生成时间: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

## 当前问题清单

### 代码质量 ({sum(1 for i in issues if i.get('type') == 'code_quality')} 个)

"""

        for issue in [i for i in issues if i.get('type') == 'code_quality']:
            content += f"- [ ] `{issue.get('file')}`: {issue.get('message')}\n"

        content += f"\n### 待办事项 ({sum(1 for i in issues if i.get('type') == 'todo')} 个)\n\n"

        for issue in [i for i in issues if i.get('type') == 'todo']:
            content += f"- [ ] `{issue.get('file')}`: {issue.get('message')}\n"

        content += f"\n### 安全问题 ({sum(1 for i in issues if i.get('type') == 'security')} 个)\n\n"

        for issue in [i for i in issues if i.get('type') == 'security']:
            msg = issue.get('message', 'N/A')
            content += f"- [ ] {msg}\n"

        content += """
## 自动化脚本

运行以下命令执行自动修复:

```bash
cd /run/media/hongfu/软件/ai_resume
bash auto-optimizer.sh
```

## 与 Claude Code 集成

在 Claude Code 中运行以下命令开始优化:

```
请根据 test-reports/ 中的最新报告进行代码优化
```

"""

        self.suggestions_file.write_text(content)
        log(f"✓ 优化任务已生成: {self.suggestions_file}", Colors.GREEN)


class AutoTestSystem:
    """自主迭代测试系统主类"""

    def __init__(self):
        self.history = TestHistory()
        self.service_manager = ServiceManager()
        self.test_runner = TestRunner(self.history)
        self.issue_detector = IssueDetector()
        self.report_generator = ReportGenerator(self.history)
        self.optimizer = AutoOptimizer()

    async def run(self) -> Dict[str, Any]:
        """运行完整测试流程"""
        log("==========================================", Colors.BOLD)
        log("  自主迭代测试系统 - 启动", Colors.BOLD)
        log("==========================================", Colors.BOLD)

        result = {}

        # 1. 检查服务
        log_section("检查服务状态")
        backend_ok = await self.service_manager.check_backend()
        frontend_ok = await self.service_manager.check_frontend()

        if not backend_ok or not frontend_ok:
            log("⚠ 部分服务未运行，跳过测试", Colors.YELLOW)
            result["services_ready"] = False
            return result

        result["services_ready"] = True

        # 2. 运行测试
        e2e_result = await self.test_runner.run_e2e_tests()
        lint_result = await self.test_runner.run_lint_check()

        result["e2e"] = e2e_result
        result["lint"] = lint_result

        # 3. 检测问题
        issues = await self.issue_detector.detect_all()
        result["issues"] = len(issues)
        result["issue_details"] = issues[:10]  # 只保存前10个

        # 4. 生成报告
        report_file = self.report_generator.generate(result, issues)
        result["report"] = report_file

        # 5. 生成优化任务
        self.optimizer.generate_tasks(issues)

        # 6. 保存历史
        self.history.add_run(result)

        # 7. 总结
        self._print_summary(result)

        return result

    def _print_summary(self, result: Dict[str, Any]) -> None:
        """打印测试总结"""
        log_section("测试周期完成")

        success_count = sum([
            result.get("e2e", {}).get("success", False),
            result.get("lint", {}).get("success", True)
        ])

        if success_count == 2 and result.get("issues", 0) == 0:
            log("✓ 全部测试通过，未发现问题", Colors.GREEN)
        elif success_count == 1:
            log("⚠ 部分测试通过，发现问题", Colors.YELLOW)
        else:
            log("✗ 测试失败，需要修复", Colors.RED)

        trends = self.history.get_trends()
        log(f"近期通过率: {trends.get('pass_rate', 'N/A')}", Colors.CYAN)


async def main():
    """主函数"""
    system = AutoTestSystem()

    try:
        result = await system.run()
        sys.exit(0 if result.get("e2e", {}).get("success", True) else 1)
    except KeyboardInterrupt:
        log("\n收到中断信号，退出...", Colors.YELLOW)
        sys.exit(1)
    except Exception as e:
        log(f"错误: {e}", Colors.RED)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
