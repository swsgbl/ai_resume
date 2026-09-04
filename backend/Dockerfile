# 后端 Dockerfile
FROM python:3.12.14-slim-trixie AS builder

WORKDIR /app

# 编译依赖统一放在 builder 层，最终镜像不携带编译工具链
RUN python -m venv /opt/venv
COPY requirements.txt .

RUN /opt/venv/bin/pip install --no-cache-dir --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple --timeout 120

FROM python:3.12.14-slim-trixie

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 运行时不需要安装器或 ensurepip，移除后可减少 Python 包攻击面
RUN rm -rf \
    /usr/local/bin/pip* \
    /usr/local/lib/python3.12/ensurepip \
    /usr/local/lib/python3.12/site-packages/pip* \
    /usr/local/lib/python3.12/site-packages/setuptools*

COPY . .

RUN mkdir -p /app/data

# 暴露端口
EXPOSE 8000

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# 启动命令
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"
