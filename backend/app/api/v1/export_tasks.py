"""
异步导出任务 API 端点
支持后台导出任务队列，支持进度查询和文件下载
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from typing import Optional
from datetime import datetime, timezone

from app.core.database import get_db
from app.core.security import get_current_user
from app.core.rate_limit import limiter, RateLimit
from app.models.user import User
from app.models.resume import Resume
from app.models.export_task import ExportTask, ExportStatus, ExportFormat
from app.schemas.export import (
    ExportTaskCreate,
    ExportTaskResponse,
    ExportTaskListResponse,
)
from app.schemas.common import Response

router = APIRouter(prefix="/export-tasks", tags=["异步导出"])


async def process_export_task(task_id: int, db: AsyncSession):
    """后台处理导出任务"""
    from app.services.export.export_service import ExportService
    import os

    export_service = ExportService()

    # 获取任务
    result = await db.execute(select(ExportTask).where(ExportTask.id == task_id))
    task = result.scalar_one_or_none()

    if not task or task.status != ExportStatus.PENDING:
        return

    # 更新状态为处理中
    task.status = ExportStatus.PROCESSING
    task.started_at = datetime.now(timezone.utc)
    task.progress = 10.0
    await db.commit()

    try:
        # 获取简历数据
        resume_results = await db.execute(
            select(Resume).where(
                and_(Resume.id.in_(task.resume_ids), Resume.user_id == task.user_id)
            )
        )
        resumes = resume_results.scalars().all()

        if not resumes:
            raise ValueError("未找到有效的简历")

        task.progress = 30.0
        await db.commit()

        # 合并简历内容
        merged_content = {}
        style_config = task.options.get("style_config", {})
        template_html = None

        for resume in resumes:
            if resume.content:
                merged_content.update(resume.content)
            if resume.style_config:
                style_config.update(resume.style_config)

        task.progress = 50.0
        await db.commit()

        # 根据格式生成文件
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        export_dir = f"data/exports/{task.user_id}"
        os.makedirs(export_dir, exist_ok=True)

        file_name = f"resume_export_{task_id}_{timestamp}"
        file_path = None
        file_size = 0

        if task.export_format == ExportFormat.PDF:
            file_path = f"{export_dir}/{file_name}.pdf"
            pdf_bytes = await export_service.to_pdf(
                resume_content=merged_content,
                style_config=style_config,
                template_html=template_html,
            )
            with open(file_path, "wb") as f:
                f.write(pdf_bytes)
            file_size = len(pdf_bytes)

        elif task.export_format == ExportFormat.DOCX:
            file_path = f"{export_dir}/{file_name}.docx"
            docx_bytes = await export_service.to_word(
                resume_content=merged_content, style_config=style_config
            )
            with open(file_path, "wb") as f:
                f.write(docx_bytes)
            file_size = len(docx_bytes)

        elif task.export_format == ExportFormat.HTML:
            file_path = f"{export_dir}/{file_name}.html"
            html_content = await export_service.to_html(
                resume_content=merged_content,
                style_config=style_config,
                template_html=template_html,
            )
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(html_content)
            file_size = len(html_content.encode("utf-8"))

        task.progress = 90.0
        await db.commit()

        # 更新任务状态
        task.status = ExportStatus.COMPLETED
        task.file_path = file_path
        task.file_size = file_size
        task.progress = 100.0
        task.completed_at = datetime.now(timezone.utc)

        await db.commit()

    except Exception as e:
        task.status = ExportStatus.FAILED
        task.error_message = str(e)
        task.progress = 0.0
        task.completed_at = datetime.now(timezone.utc)
        await db.commit()


@router.post("", response_model=Response[ExportTaskResponse])
@limiter.limit(RateLimit.RESUME_EXPORT)
async def create_export_task(
    request: Request,
    task_data: ExportTaskCreate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """创建异步导出任务"""
    # 验证简历所有权
    result = await db.execute(
        select(Resume).where(
            and_(Resume.id.in_(task_data.resume_ids), Resume.user_id == current_user.id)
        )
    )
    resumes = result.scalars().all()

    if len(resumes) != len(task_data.resume_ids):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="部分简历不存在或无权访问"
        )

    # 创建导出任务
    export_task = ExportTask(
        user_id=current_user.id,
        resume_ids=task_data.resume_ids,
        export_format=task_data.export_format,
        options=task_data.options or {},
        status=ExportStatus.PENDING,
        progress=0.0,
    )

    db.add(export_task)
    await db.commit()
    await db.refresh(export_task)

    # 添加后台任务
    background_tasks.add_task(process_export_task, export_task.id, db)

    return Response(data=ExportTaskResponse.model_validate(export_task))


@router.get("", response_model=Response[ExportTaskListResponse])
async def list_export_tasks(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    status_filter: Optional[ExportStatus] = Query(None, description="状态筛选"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """获取用户的导出任务列表"""
    query = select(ExportTask).where(ExportTask.user_id == current_user.id)

    if status_filter:
        query = query.where(ExportTask.status == status_filter)

    # 计算总数
    from sqlalchemy import func

    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # 分页查询
    query = query.order_by(ExportTask.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)

    result = await db.execute(query)
    tasks = result.scalars().all()

    items = [ExportTaskResponse.model_validate(task) for task in tasks]

    return Response(data=ExportTaskListResponse(total=total, items=items))


@router.get("/{task_id}", response_model=Response[ExportTaskResponse])
async def get_export_task(
    task_id: int, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """获取导出任务详情"""
    result = await db.execute(
        select(ExportTask).where(
            and_(ExportTask.id == task_id, ExportTask.user_id == current_user.id)
        )
    )
    task = result.scalar_one_or_none()

    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="导出任务不存在")

    return Response(data=ExportTaskResponse.model_validate(task))


@router.get("/{task_id}/download")
async def download_export_file(
    task_id: int, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """下载导出文件"""
    result = await db.execute(
        select(ExportTask).where(
            and_(ExportTask.id == task_id, ExportTask.user_id == current_user.id)
        )
    )
    task = result.scalar_one_or_none()

    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="导出任务不存在")

    if task.status != ExportStatus.COMPLETED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"导出任务尚未完成，当前状态: {task.status.value}",
        )

    if not task.file_path:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="导出文件不存在")

    from fastapi.responses import FileResponse
    import os

    if not os.path.exists(task.file_path):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="导出文件已被删除")

    # 确定文件名和 MIME 类型
    filename = os.path.basename(task.file_path)
    media_type = "application/octet-stream"

    if task.export_format == ExportFormat.PDF:
        media_type = "application/pdf"
    elif task.export_format == ExportFormat.DOCX:
        media_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    elif task.export_format == ExportFormat.HTML:
        media_type = "text/html; charset=utf-8"

    return FileResponse(task.file_path, media_type=media_type, filename=filename)


@router.delete("/{task_id}", response_model=Response[dict])
async def delete_export_task(
    task_id: int, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """删除导出任务"""
    result = await db.execute(
        select(ExportTask).where(
            and_(ExportTask.id == task_id, ExportTask.user_id == current_user.id)
        )
    )
    task = result.scalar_one_or_none()

    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="导出任务不存在")

    # 删除文件
    import os

    if task.file_path and os.path.exists(task.file_path):
        try:
            os.remove(task.file_path)
        except Exception:
            pass  # 忽略删除文件失败

    # 删除数据库记录
    await db.delete(task)
    await db.commit()

    return Response(data={"message": "导出任务已删除"})
