"""
合规性配置模块 - 用户协议、隐私政策、数据处理规范
遵循《个人信息保护法》、《网络安全法》及GDPR标准
"""

from typing import Dict, Any
from datetime import datetime


class ComplianceConfig:
    """合规性配置"""

    # 版本信息
    TERMS_VERSION = "1.0.0"
    PRIVACY_VERSION = "1.0.0"
    LAST_UPDATED = "2026-01-27"

    # 数据收集类型
    DATA_COLLECTION_TYPES = {
        "necessary": {
            "description": "必要数据 - 提供服务所必需",
            "items": ["邮箱地址", "密码（加密存储）", "简历内容"],
        },
        "optional": {
            "description": "可选数据 - 增强用户体验",
            "items": ["手机号码", "头像", "个人偏好设置"],
        },
        "analytics": {
            "description": "分析数据 - 改进服务质量",
            "items": ["使用日志", "设备信息", "访问统计"],
        },
    }

    # 数据保留政策
    DATA_RETENTION_POLICY = {
        "user_data": "账户删除后30天内完全删除",
        "resume_data": "用户主动删除后立即移除",
        "logs": "保留7天后自动清理",
        "backups": "保留30天后销毁",
    }

    # 第三方服务
    THIRD_PARTY_SERVICES = [
        {
            "name": "OpenAI",
            "purpose": "AI内容生成",
            "data_shared": "简历文本内容（脱敏处理后）",
            "privacy_policy": "https://openai.com/privacy",
        }
    ]


class PrivacyPolicy:
    """隐私政策生成器"""

    @staticmethod
    def get_privacy_policy() -> Dict[str, Any]:
        """获取完整隐私政策"""
        return {
            "version": ComplianceConfig.PRIVACY_VERSION,
            "last_updated": ComplianceConfig.LAST_UPDATED,
            "title": "AI简历智能生成平台隐私政策",
            "sections": [
                {
                    "title": "1. 引言",
                    "content": """
感谢您使用AI简历智能生成平台（以下简称"本平台"）。我们高度重视您的隐私保护，
本隐私政策将向您说明我们如何收集、使用、存储和保护您的个人信息。
请在使用本平台服务前仔细阅读本政策。
""",
                },
                {
                    "title": "2. 信息收集",
                    "content": """
我们收集以下类型的信息：

2.1 您主动提供的信息：
- 注册信息：邮箱地址、密码
- 简历内容：个人信息、教育经历、工作经历等
- 联系方式：手机号码（可选）

2.2 自动收集的信息：
- 设备信息：设备类型、操作系统版本
- 日志信息：访问时间、IP地址、操作记录
- Cookie信息：用于保持登录状态和偏好设置

2.3 第三方来源：
- 第三方登录：微信、QQ等授权的基本信息
""",
                },
                {
                    "title": "3. 信息使用",
                    "content": """
我们使用您的信息用于：
- 提供核心服务：简历生成、编辑、导出
- AI功能：智能优化简历内容（数据脱敏后处理）
- 服务改进：分析使用模式，优化用户体验
- 安全保障：防止欺诈、滥用和安全威胁
- 法律合规：履行法律义务
""",
                },
                {
                    "title": "4. 信息保护",
                    "content": """
我们采取以下措施保护您的信息：
- 传输加密：使用HTTPS/TLS加密所有数据传输
- 存储加密：敏感信息采用AES-256加密存储
- 访问控制：严格的权限管理和身份验证
- 定期审计：安全漏洞扫描和渗透测试
- 员工培训：数据安全和隐私保护培训
""",
                },
                {
                    "title": "5. 信息共享",
                    "content": """
我们不会出售您的个人信息。仅在以下情况下共享：
- 您明确授权同意
- 与AI服务提供商共享脱敏数据以提供智能功能
- 法律要求或政府机关依法要求
- 保护我们的合法权益（如防欺诈）
""",
                },
                {
                    "title": "6. 您的权利",
                    "content": """
您享有以下权利：
- 访问权：查看我们持有的您的个人信息
- 更正权：更正不准确的个人信息
- 删除权：要求删除您的个人信息
- 数据可携带权：获取您的数据副本
- 撤回同意权：随时撤回对数据处理的同意
- 投诉权：向监管机构投诉

行使权利请联系：privacy@ai-resume.com
""",
                },
                {
                    "title": "7. 数据保留",
                    "content": """
- 账户数据：在账户活跃期间保留，删除账户后30天内清除
- 简历数据：您删除后立即从系统中移除
- 日志数据：保留7天用于安全分析
- 备份数据：保留30天后销毁
""",
                },
                {
                    "title": "8. Cookie政策",
                    "content": """
我们使用以下类型的Cookie：
- 必要Cookie：维持登录状态和基本功能
- 功能Cookie：记住您的偏好设置
- 分析Cookie：了解服务使用情况（可选）

您可以通过浏览器设置管理Cookie。
""",
                },
                {
                    "title": "9. 儿童隐私",
                    "content": """
本服务不面向16岁以下的儿童。我们不会故意收集儿童的个人信息。
如发现误收集了儿童信息，我们将立即删除。
""",
                },
                {
                    "title": "10. 政策更新",
                    "content": """
我们可能会不时更新本隐私政策。重大变更将通过邮件或平台通知告知您。
继续使用服务即表示您接受更新后的政策。
""",
                },
                {
                    "title": "11. 联系我们",
                    "content": """
如有任何隐私相关问题，请联系：
- 邮箱：privacy@ai-resume.com
- 地址：[公司地址]
- 数据保护官：dpo@ai-resume.com
""",
                },
            ],
        }


class UserAgreement:
    """用户服务协议生成器"""

    @staticmethod
    def get_user_agreement() -> Dict[str, Any]:
        """获取用户服务协议"""
        return {
            "version": ComplianceConfig.TERMS_VERSION,
            "last_updated": ComplianceConfig.LAST_UPDATED,
            "title": "AI简历智能生成平台用户服务协议",
            "sections": [
                {
                    "title": "1. 协议接受",
                    "content": """
欢迎使用AI简历智能生成平台。在使用本服务前，请仔细阅读本协议。
注册或使用本服务即表示您已阅读、理解并同意受本协议约束。
如您不同意本协议的任何条款，请勿使用本服务。
""",
                },
                {
                    "title": "2. 服务描述",
                    "content": """
本平台提供以下服务：
- AI辅助简历生成和优化
- 简历模板库
- 多格式导出（PDF、Word、HTML）
- JD匹配分析
- 面试问题预测
- 隐私脱敏功能
""",
                },
                {
                    "title": "3. 用户账户",
                    "content": """
3.1 注册：您需要提供真实、准确的信息进行注册
3.2 安全：您负责保管账户凭证，对账户下的所有活动负责
3.3 通知：如发现未授权使用，请立即通知我们
""",
                },
                {
                    "title": "4. 用户行为规范",
                    "content": """
您同意不会：
- 提供虚假的个人信息
- 侵犯他人的知识产权或隐私
- 使用本服务进行非法活动
- 尝试破坏、攻击或绕过系统安全措施
- 进行任何可能损害平台或其他用户的行为
- 批量爬取或滥用API接口
""",
                },
                {
                    "title": "5. 知识产权",
                    "content": """
5.1 平台内容：本平台的软件、设计、商标等归我们所有
5.2 用户内容：您保留对您创建的简历内容的所有权
5.3 AI生成内容：AI辅助生成的内容，著作权归用户所有
5.4 许可授权：您授予我们处理您内容的必要许可以提供服务
""",
                },
                {
                    "title": "6. 付费服务",
                    "content": """
6.1 基础功能免费，高级功能需要订阅
6.2 订阅费用在购买前明确告知
6.3 自动续费可随时取消
6.4 已付费用一般不予退还（法律规定的情况除外）
""",
                },
                {
                    "title": "7. 免责声明",
                    "content": """
7.1 服务按"现状"提供，不作任何明示或暗示的保证
7.2 AI生成内容仅供参考，最终简历内容由用户负责
7.3 我们不保证简历一定能帮助用户获得工作机会
7.4 因不可抗力导致的服务中断，我们不承担责任
""",
                },
                {
                    "title": "8. 责任限制",
                    "content": """
在法律允许的最大范围内：
- 我们不对间接损失、利润损失等承担责任
- 我们的总责任不超过您支付的服务费用
""",
                },
                {
                    "title": "9. 账户终止",
                    "content": """
9.1 您可随时删除账户
9.2 如您违反本协议，我们可暂停或终止您的账户
9.3 终止后，您的数据将按隐私政策处理
""",
                },
                {
                    "title": "10. 协议修改",
                    "content": """
我们可能会修改本协议。重大变更将提前通知。
继续使用服务即表示接受修改后的协议。
""",
                },
                {
                    "title": "11. 法律适用",
                    "content": """
本协议受中华人民共和国法律管辖。
争议应首先协商解决，协商不成可向有管辖权的法院起诉。
""",
                },
                {
                    "title": "12. 联系方式",
                    "content": """
如有问题，请联系：
- 邮箱：support@ai-resume.com
- 客服热线：[客服电话]
""",
                },
            ],
        }


class DataProtection:
    """数据保护工具"""

    # 敏感数据脱敏规则
    MASK_RULES = {
        "phone": lambda x: x[:3] + "****" + x[-4:] if len(x) == 11 else x,
        "email": lambda x: x[0] + "***" + x[x.index("@") :] if "@" in x else x,
        "id_card": lambda x: x[:6] + "********" + x[-4:] if len(x) == 18 else x,
        "bank_card": lambda x: x[:4] + " **** **** " + x[-4:] if len(x) >= 16 else x,
        "address": lambda x: x[:6] + "****" if len(x) > 6 else x,
    }

    @classmethod
    def mask_sensitive_data(
        cls, data: Dict[str, Any], fields_to_mask: list = None
    ) -> Dict[str, Any]:
        """对敏感数据进行脱敏处理"""
        if fields_to_mask is None:
            fields_to_mask = list(cls.MASK_RULES.keys())

        masked_data = data.copy()

        for key, value in masked_data.items():
            if isinstance(value, str):
                for field_type in fields_to_mask:
                    if field_type in key.lower() and field_type in cls.MASK_RULES:
                        masked_data[key] = cls.MASK_RULES[field_type](value)
                        break
            elif isinstance(value, dict):
                masked_data[key] = cls.mask_sensitive_data(value, fields_to_mask)

        return masked_data

    @staticmethod
    def generate_data_export(user_data: Dict[str, Any]) -> Dict[str, Any]:
        """生成用户数据导出包（数据可携带权）"""
        return {
            "export_time": datetime.now().isoformat(),
            "format_version": "1.0",
            "user_data": user_data,
            "metadata": {
                "description": "您在AI简历智能生成平台的个人数据导出",
                "contact": "privacy@ai-resume.com",
            },
        }

    @staticmethod
    def log_data_access(user_id: int, data_type: str, action: str, accessor: str = "system"):
        """记录数据访问日志（审计追踪）"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "user_id": user_id,
            "data_type": data_type,
            "action": action,
            "accessor": accessor,
        }
        # 这里应该写入审计日志数据库或文件
        return log_entry
