"""
AI 服务测试 - 提高覆盖率
"""
import pytest
from pathlib import Path
from app.services.ai.prompts.manager import PromptManager, load_prompt


class TestPromptManager:
    """Prompt 管理器测试"""

    def test_init_with_default_path(self):
        """测试: 使用默认路径初始化"""
        manager = PromptManager()
        assert manager.base_path is not None
        assert manager._system_prompt == ""
        assert manager._task_prompt == ""
        assert manager._examples == []
        assert manager._variables == {}

    def test_init_with_custom_path(self, tmp_path):
        """测试: 使用自定义路径初始化"""
        manager = PromptManager(base_path=str(tmp_path))
        assert manager.base_path == tmp_path

    def test_system_prompt_with_valid_file(self, tmp_path):
        """测试: 加载有效的系统 Prompt 文件"""
        # 创建系统 prompt 目录和文件
        system_dir = tmp_path / "system"
        system_dir.mkdir()
        prompt_file = system_dir / "resume_expert_v1.md"
        prompt_file.write_text("Test System Prompt", encoding="utf-8")

        manager = PromptManager(base_path=str(tmp_path))
        manager.system("resume_expert", version="v1")

        assert manager._system_prompt == "Test System Prompt"

    def test_system_prompt_with_missing_file(self):
        """测试: 缺少系统 Prompt 文件时使用默认值"""
        manager = PromptManager(base_path="/nonexistent/path")
        manager.system("resume_expert", version="v1")

        assert "资深 HR" in manager._system_prompt
        assert "职业顾问" in manager._system_prompt

    def test_system_prompt_unknown_role(self):
        """测试: 未知角色使用通用默认 Prompt"""
        manager = PromptManager(base_path="/nonexistent/path")
        manager.system("unknown_role", version="v1")

        assert manager._system_prompt == "你是一位专业的 AI 助手。"

    def test_task_prompt_with_valid_file(self, tmp_path):
        """测试: 加载有效的任务 Prompt 文件"""
        tasks_dir = tmp_path / "tasks"
        tasks_dir.mkdir(parents=True)
        task_file = tasks_dir / "generate.md"
        task_file.write_text("Test Task Prompt", encoding="utf-8")

        manager = PromptManager(base_path=str(tmp_path))
        manager.task("generate")

        assert manager._task_prompt == "Test Task Prompt"

    def test_task_prompt_with_missing_file(self, tmp_path):
        """测试: 缺少任务 Prompt 文件时返回空字符串"""
        manager = PromptManager(base_path=str(tmp_path))
        manager.task("nonexistent_task")

        assert manager._task_prompt == ""

    def test_examples_with_valid_file(self, tmp_path):
        """测试: 加载有效的示例文件"""
        import json

        examples_dir = tmp_path / "examples"
        examples_dir.mkdir(parents=True)
        examples_file = examples_dir / "test_examples.json"
        test_data = [
            {"input": "Input 1", "output": "Output 1"},
            {"input": "Input 2", "output": "Output 2"},
            {"input": "Input 3", "output": "Output 3"},
            {"input": "Input 4", "output": "Output 4"},  # 这个不应该被加载
        ]
        examples_file.write_text(json.dumps(test_data, ensure_ascii=False), encoding="utf-8")

        manager = PromptManager(base_path=str(tmp_path))
        manager.examples("test_examples", count=3)

        assert len(manager._examples) == 3
        assert manager._examples[0]["input"] == "Input 1"
        assert manager._examples[2]["input"] == "Input 3"

    def test_examples_with_missing_file(self, tmp_path):
        """测试: 缺少示例文件时不报错"""
        manager = PromptManager(base_path=str(tmp_path))
        manager.examples("nonexistent_examples")

        assert manager._examples == []

    def test_vars_method(self):
        """测试: 设置变量"""
        manager = PromptManager()
        result = manager.vars(name="张三", position="工程师")

        assert result is manager  # 链式调用
        assert manager._variables["name"] == "张三"
        assert manager._variables["position"] == "工程师"

    def test_vars_with_dict_value(self):
        """测试: 设置字典类型变量"""
        manager = PromptManager()
        manager.vars(data={"key": "value", "nested": {"item": 123}})

        # vars 方法直接存储变量，序列化发生在渲染时
        assert manager._variables["data"]["key"] == "value"

    def test_vars_with_list_value(self):
        """测试: 设置列表类型变量"""
        manager = PromptManager()
        manager.vars(items=["a", "b", "c"])

        # vars 方法直接存储变量，序列化发生在渲染时
        assert manager._variables["items"] == ["a", "b", "c"]

    def test_build_with_empty_prompts(self):
        """测试: 构建 Prompt（空内容）"""
        manager = PromptManager()
        result = manager.build()

        assert result["system"] == ""
        assert result["user"] == ""
        assert result["full"] == ""

    def test_build_with_system_prompt(self):
        """测试: 构建带系统 Prompt 的结果"""
        manager = PromptManager()
        manager._system_prompt = "System Instructions"
        result = manager.build()

        assert result["system"] == "System Instructions"
        assert result["full"] == "System Instructions"

    def test_build_with_task_prompt(self):
        """测试: 构建带任务 Prompt 的结果"""
        manager = PromptManager()
        manager._task_prompt = "Task Instructions"
        result = manager.build()

        assert result["user"] == "Task Instructions"
        assert "Task Instructions" in result["full"]

    def test_build_with_examples(self):
        """测试: 构建带示例的结果"""
        manager = PromptManager()
        manager._examples = [
            {"input": "输入1", "output": "输出1"},
            {"input": "输入2", "output": "输出2"},
        ]
        result = manager.build()

        assert "示例" in result["user"]
        assert "输入1" in result["user"]
        assert "输出2" in result["user"]

    def test_build_with_variables(self):
        """测试: 构建带变量替换的结果"""
        manager = PromptManager()
        manager._system_prompt = "Hello {name}"
        manager._task_prompt = "Position: {position}"
        manager.vars(name="张三", position="工程师")
        result = manager.build()

        assert result["system"] == "Hello 张三"
        # task prompt 应该包含替换后的变量
        assert "工程师" in result["user"]

    def test_build_full_prompt(self):
        """测试: 构建完整 Prompt"""
        manager = PromptManager()
        manager._system_prompt = "System: {role}"
        manager._task_prompt = "Task: Generate content"
        manager._examples = [{"input": "In", "output": "Out"}]
        manager.vars(role="Expert")
        result = manager.build()

        assert "System: Expert" in result["full"]
        assert "Task: Generate content" in result["full"]
        assert "示例" in result["full"]


class TestLoadPromptFunction:
    """load_prompt 便捷函数测试"""

    def test_load_prompt_without_task(self):
        """测试: 不指定任务路径加载 Prompt"""
        result = load_prompt("resume_expert")

        assert "system" in result
        assert "user" in result
        assert "full" in result
        assert "资深 HR" in result["system"]

    def test_load_prompt_with_task(self):
        """测试: 带任务路径加载 Prompt"""
        result = load_prompt("resume_expert", task="generate")

        assert "system" in result
        assert "user" in result
        assert "full" in result

    def test_load_prompt_with_variables(self):
        """测试: 带变量加载 Prompt"""
        # 使用不与函数参数冲突的变量名
        result = load_prompt("resume_expert", user_name="张三", title="工程师")

        # 变量不会影响系统 prompt（因为没有占位符）
        assert "system" in result


class TestAIBaseService:
    """AI 基础服务测试"""

    def test_base_service_structure(self):
        """测试: AI 基础服务类结构"""
        from app.services.ai.base import AIProviderBase

        # 检查类是否存在且有预期的方法
        assert hasattr(AIProviderBase, '__init__')
        assert callable(AIProviderBase)

    def test_base_provider_is_abstract(self):
        """测试: 基础提供商是抽象类"""
        from app.services.ai.base import AIProviderBase
        from abc import ABC

        assert issubclass(AIProviderBase, ABC)
