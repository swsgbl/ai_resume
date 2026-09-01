"""
AI简历智能生成平台 - FastAPI 主入口
"""

from contextlib import asynccontextmanager
from datetime import datetime
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from loguru import logger
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.core.database import init_db, close_db
from app.core.rate_limit import limiter, rate_limit_exceeded_handler
from app.api.v1 import router as api_v1_router
from app.middleware.security import SecurityHeadersMiddleware, CSPMiddleware
from app.utils.logging import setup_logging, AccessLogger, PerformanceLogger

# 初始化日志系统
setup_logging(debug=settings.DEBUG)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时
    logger.info(f"正在启动 {settings.APP_NAME} v{settings.APP_VERSION}")
    await init_db()
    logger.info("数据库初始化完成")

    yield

    # 关闭时
    await close_db()
    logger.info("应用已关闭")


# 创建应用实例
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="""
# AI简历智能生成平台 API

## 功能特性

- **用户认证**: 注册、登录、JWT令牌管理
- **简历管理**: 创建、编辑、删除、版本控制
- **AI生成**: 智能生成简历内容、STAR法则优化
- **模板系统**: 丰富的简历模板库
- **多格式导出**: PDF、Word、HTML导出

## 技术栈

- FastAPI + SQLAlchemy + MySQL
- OpenAI GPT-4 API
- JWT 认证
    """,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# 添加限流器到app state
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)

# 配置 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 添加安全中间件
app.add_middleware(CSPMiddleware)
app.add_middleware(SecurityHeadersMiddleware)


# 安全中间件 - 请求日志(速率限制由slowapi处理)
@app.middleware("http")
async def security_middleware(request: Request, call_next):
    """安全中间件：请求日志、慢查询监控"""
    start_time = datetime.now()
    client_ip = request.client.host if request.client else "unknown"
    user_agent = request.headers.get("user-agent", "unknown")

    # 执行请求(slowapi会自动处理速率限制)
    response = await call_next(request)

    # 计算响应时间
    response_time = (datetime.now() - start_time).total_seconds()

    # 记录访问日志
    AccessLogger.log_request(
        method=request.method,
        path=request.url.path,
        client_ip=client_ip,
        status_code=response.status_code,
        response_time=response_time,
        user_agent=user_agent,
    )

    # 记录慢请求
    if response_time > 1.0:
        PerformanceLogger.log_slow_request(
            path=request.url.path, method=request.method, response_time=response_time
        )

    return response


# 全局异常处理
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    import traceback

    logger.error(f"全局异常: {exc}\n{traceback.format_exc()}")
    # 开发环境显示完整堆栈跟踪，生产环境仅显示通用错误消息
    return JSONResponse(
        status_code=500,
        content={
            "code": 500,
            "message": "服务器内部错误",
            "detail": traceback.format_exc() if settings.DEBUG else "内部错误，请稍后重试",
        },
    )


# 注册路由
app.include_router(api_v1_router, prefix=settings.API_V1_PREFIX)


# 健康检查
@app.get("/health", tags=["系统"])
async def health_check():
    """健康检查接口"""
    return {"status": "healthy", "app": settings.APP_NAME, "version": settings.APP_VERSION}


# 根路径
@app.get("/", tags=["系统"])
async def root():
    """根路径"""
    return {
        "message": f"欢迎使用 {settings.APP_NAME}",
        "version": settings.APP_VERSION,
        "docs": "/docs",
        "redoc": "/redoc",
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=settings.DEBUG)
