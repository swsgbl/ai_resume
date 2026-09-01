# AI Prompt 分层管理体系

## 目录结构

```
prompts/
├── system/           # L1: 系统级 Prompt（角色定义）
│   ├── resume_expert_v1.md
│   ├── career_advisor_v1.md
│   └── optimizer_v1.md
├── tasks/            # L2: 任务级 Prompt（具体任务）
│   ├── generate/
│   │   ├── full_resume.md
│   │   └── simplified_resume.md
│   ├── optimize/
│   │   ├── star_method.md
│   │   ├── quantify.md
│   │   └── keywords.md
│   └── analyze/
│       ├── jd_match.md
│       └── interview_questions.md
├── examples/         # L3: Few-shot 示例
│   ├── work_experience/
│   │   ├── good_examples.json
│   │   └── bad_examples.json
│   └── project_experience/
│       └── examples.json
└── versions/         # Prompt 版本历史
    └── 2024-03/
```

## 使用方式

```python
from app.services.ai.prompts import PromptManager

# 加载分层 Prompt
prompt = PromptManager()
    .system("resume_expert_v1")
    .task("generate/full_resume")
    .examples("work_experience/good")
    .build()
```

## 版本控制

- 所有 Prompt 变更需要记录在 versions/ 目录
- 支持 A/B 测试：可同时运行多个 Prompt 版本
- 通过 analytics 追踪各版本效果
