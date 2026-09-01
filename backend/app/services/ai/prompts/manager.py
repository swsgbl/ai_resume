"""
Prompt 管理器 - 分层 Prompt 加载和构建
"""

import json
from typing import List, Dict, Any, Optional
from pathlib import Path


class PromptManager:
    """分层 Prompt 管理器"""

    def __init__(self, base_path: Optional[str] = None):
        """
        初始化 Prompt 管理器

        Args:
            base_path: Prompt 文件基础路径，默认使用内置路径
        """
        if base_path is None:
            # 获取当前文件所在目录
            current_dir = Path(__file__).parent
            self.base_path = current_dir / "prompts"
        else:
            self.base_path = Path(base_path)

        self._system_prompt: str = ""
        self._task_prompt: str = ""
        self._examples: List[Dict[str, Any]] = []
        self._variables: Dict[str, Any] = {}

    def system(self, name: str, version: str = "v1") -> "PromptManager":
        """
        加载系统级 Prompt

        Args:
            name: Prompt 名称，如 "resume_expert"
            version: 版本号，默认 v1
        """
        filepath = self.base_path / "system" / f"{name}_{version}.md"
        if filepath.exists():
            self._system_prompt = filepath.read_text(encoding="utf-8")
        else:
            # 使用默认系统 Prompt
            self._system_prompt = self._default_system_prompt(name)
        return self

    def task(self, path: str) -> "PromptManager":
        """
        加载任务级 Prompt

        Args:
            path: 相对路径，如 "generate/full_resume"
        """
        filepath = self.base_path / "tasks" / f"{path}.md"
        if filepath.exists():
            self._task_prompt = filepath.read_text(encoding="utf-8")
        else:
            self._task_prompt = ""
        return self

    def examples(self, path: str, count: int = 3) -> "PromptManager":
        """
        加载 Few-shot 示例

        Args:
            path: 示例路径，如 "work_experience/good"
            count: 加载示例数量
        """
        filepath = self.base_path / "examples" / f"{path}.json"
        if filepath.exists():
            with open(filepath, "r", encoding="utf-8") as f:
                all_examples = json.load(f)
                self._examples = all_examples[:count]
        return self

    def vars(self, **kwargs) -> "PromptManager":
        """
        设置变量，用于渲染 Prompt

        Args:
            **kwargs: 变量名和值
        """
        self._variables.update(kwargs)
        return self

    def build(self) -> Dict[str, Any]:
        """
        构建最终 Prompt

        Returns:
            包含 system_prompt 和 user_prompt 的字典
        """
        # 渲染变量
        system_content = self._render_template(self._system_prompt)
        task_content = self._render_template(self._task_prompt)

        # 构建用户 Prompt
        user_parts = []

        # 添加任务指令
        if task_content:
            user_parts.append(task_content)

        # 添加示例
        if self._examples:
            user_parts.append("\n## 示例\n")
            for i, ex in enumerate(self._examples, 1):
                user_parts.append(f"示例{i}:")
                user_parts.append(f"输入: {ex.get('input', '')}")
                user_parts.append(f"输出: {ex.get('output', '')}")
                user_parts.append("")

        user_content = "\n".join(user_parts)

        return {
            "system": system_content,
            "user": user_content,
            "full": f"{system_content}\n\n{user_content}".strip(),
        }

    def _render_template(self, template: str) -> str:
        """渲染模板变量"""
        result = template
        for key, value in self._variables.items():
            placeholder = "{" + key + "}"
            if isinstance(value, (dict, list)):
                value = json.dumps(value, ensure_ascii=False)
            result = result.replace(placeholder, str(value))
        return result

    def _default_system_prompt(self, name: str) -> str:
        """获取默认系统 Prompt"""
        defaults = {
            "resume_expert": """你是一位资深 HR 和职业顾问，拥有 10 年+ 大厂招聘经验。
你的任务是帮助用户将经历转化为有竞争力的简历内容。

核心能力：
1. 深度信息挖掘 - 从平淡描述中发现亮点
2. STAR 法则结构化 - 情境-任务-行动-结果
3. 行业关键词优化 - 匹配 ATS 和 HR 筛选习惯
4. 量化表达 - 用数字说话""",
            "career_advisor": """你是一位专业的职业规划顾问。
帮助用户分析职业路径，提供发展建议。""",
            "optimizer": """你是一位简历优化专家。
专注于改进简历的表达方式和内容质量。""",
        }
        return defaults.get(name, "你是一位专业的 AI 助手。")


# 便捷函数
def load_prompt(name: str, task: str = "", **vars) -> Dict[str, Any]:
    """
    快速加载 Prompt

    Args:
        name: 系统 Prompt 名称
        task: 任务 Prompt 路径（可选）
        **vars: 模板变量

    Returns:
        构建好的 Prompt 字典
    """
    builder = PromptManager().system(name).vars(**vars)
    if task:
        builder.task(task)
    return builder.build()
