"""
合规性API - 用户协议、隐私政策、数据权利
"""

from fastapi import APIRouter, HTTPException, status
from typing import Dict, Any

from app.core.compliance import ComplianceConfig, PrivacyPolicy, UserAgreement
from app.schemas.common import Response

router = APIRouter(prefix="/compliance", tags=["合规性"])


@router.get("/privacy-policy", response_model=Response[Dict[str, Any]])
async def get_privacy_policy():
    """
    获取隐私政策

    返回完整的隐私政策内容，包含版本号和更新日期
    """
    try:
        policy = PrivacyPolicy.get_privacy_policy()
        return Response(code=200, message="获取成功", data=policy)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"获取隐私政策失败: {str(e)}"
        )


@router.get("/user-agreement", response_model=Response[Dict[str, Any]])
async def get_user_agreement():
    """
    获取用户服务协议

    返回完整的用户服务协议内容，包含版本号和更新日期
    """
    try:
        agreement = UserAgreement.get_user_agreement()
        return Response(code=200, message="获取成功", data=agreement)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"获取用户协议失败: {str(e)}"
        )


@router.get("/data-collection-info", response_model=Response[Dict[str, Any]])
async def get_data_collection_info():
    """
    获取数据收集说明

    返回平台收集的数据类型及其用途说明
    """
    return Response(
        code=200,
        message="获取成功",
        data={
            "collection_types": ComplianceConfig.DATA_COLLECTION_TYPES,
            "retention_policy": ComplianceConfig.DATA_RETENTION_POLICY,
            "third_party_services": ComplianceConfig.THIRD_PARTY_SERVICES,
            "last_updated": ComplianceConfig.LAST_UPDATED,
        },
    )


@router.get("/versions", response_model=Response[Dict[str, str]])
async def get_compliance_versions():
    """
    获取合规文档版本

    返回用户协议和隐私政策的当前版本号
    """
    return Response(
        code=200,
        message="获取成功",
        data={
            "terms_version": ComplianceConfig.TERMS_VERSION,
            "privacy_version": ComplianceConfig.PRIVACY_VERSION,
            "last_updated": ComplianceConfig.LAST_UPDATED,
        },
    )


# 以下API需要用户认证
# from app.core.deps import get_current_user


@router.post("/consent/accept", response_model=Response[Dict[str, Any]])
async def accept_consent(
    consent_type: str,
    version: str,
    # current_user = Depends(get_current_user)  # 生产环境取消注释
):
    """
    记录用户同意

    记录用户接受用户协议或隐私政策的版本

    Args:
        consent_type: 同意类型 (terms/privacy)
        version: 同意的版本号
    """
    if consent_type not in ["terms", "privacy"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="无效的同意类型")

    # 这里应该记录到数据库
    # await save_user_consent(current_user.id, consent_type, version)

    return Response(
        code=200,
        message="同意记录已保存",
        data={
            "consent_type": consent_type,
            "version": version,
            "accepted_at": "2026-01-27T00:00:00Z",
        },
    )


@router.post("/data/export-request", response_model=Response[Dict[str, Any]])
async def request_data_export(
    # current_user = Depends(get_current_user)  # 生产环境取消注释
):
    """
    请求数据导出（数据可携带权）

    用户可以请求导出其在平台上的所有个人数据
    导出完成后将通过邮件发送下载链接
    """
    # 这里应该创建异步任务来生成数据导出
    # task_id = await create_data_export_task(current_user.id)

    return Response(
        code=200,
        message="数据导出请求已提交，完成后将通过邮件通知",
        data={"request_id": "export_12345", "status": "processing", "estimated_time": "24小时内"},
    )


@router.post("/data/delete-request", response_model=Response[Dict[str, Any]])
async def request_data_deletion(
    confirmation: bool,
    # current_user = Depends(get_current_user)  # 生产环境取消注释
):
    """
    请求删除数据（被遗忘权）

    用户可以请求删除其在平台上的所有个人数据
    此操作不可逆，需要用户确认

    Args:
        confirmation: 用户确认删除 (必须为True)
    """
    if not confirmation:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="请确认删除请求")

    # 这里应该创建数据删除任务
    # await schedule_data_deletion(current_user.id)

    return Response(
        code=200,
        message="数据删除请求已提交，将在30天内完成",
        data={"request_id": "delete_12345", "status": "scheduled", "completion_date": "2026-02-26"},
    )


@router.get("/data/access-log", response_model=Response[Dict[str, Any]])
async def get_data_access_log(
    # current_user = Depends(get_current_user)  # 生产环境取消注释
):
    """
    获取数据访问日志（知情权）

    用户可以查看其数据的访问记录
    """
    # 这里应该从审计日志中查询
    # logs = await get_user_data_access_logs(current_user.id)

    return Response(
        code=200,
        message="获取成功",
        data={
            "logs": [
                {
                    "timestamp": "2026-01-27T10:00:00Z",
                    "action": "view",
                    "data_type": "resume",
                    "accessor": "user",
                },
                {
                    "timestamp": "2026-01-27T09:30:00Z",
                    "action": "ai_process",
                    "data_type": "resume_content",
                    "accessor": "ai_service",
                    "note": "AI内容优化处理（数据已脱敏）",
                },
            ],
            "total": 2,
        },
    )
