# Makefile for AI Resume Platform

.PHONY: help install-dev install-prod run-backend run-frontend test test-coverage lint lint-fix format security-check build docker-up docker-down clean deploy

help:
	@echo "AI Resume Platform - 常用命令"
	@echo ""
	@echo "开发环境:"
	@echo "  make install-dev      - 安装开发依赖"
	@echo "  make run-backend      - 启动后端开发服务器"
	@echo "  make run-frontend     - 启动前端开发服务器"
	@echo "  make run-all          - 同时启动前后端"
	@echo ""
	@echo "测试:"
	@echo "  make test             - 运行所有测试"
	@echo "  make test-coverage    - 运行测试并生成覆盖率报告"
	@echo "  make test-backend     - 只运行后端测试"
	@echo "  make test-frontend    - 只运行前端测试"
	@echo ""
	@echo "代码质量:"
	@echo "  make lint             - 运行代码检查"
	@echo "  make lint-fix         - 自动修复问题"
	@echo "  make format           - 格式化代码"
	@echo "  make security-check   - 安全扫描"
	@echo ""
	@echo "构建和部署:"
	@echo "  make build            - 构建 Docker 镜像"
	@echo "  make docker-up         - 启动 Docker Compose"
	@echo "  make docker-down       - 停止 Docker Compose"
	@echo "  make docker-logs       - 查看 Docker 日志"
	@echo "  make clean            - 清理构建文件"
	@echo "  make deploy            - 部署到生产环境"

# 开发环境
install-dev:
	@echo "安装开发依赖..."
	cd backend && source venv/bin/activate && pip install -r requirements-dev.txt
	cd ai-resume-web && npm install

run-backend:
	@echo "启动后端开发服务器..."
	cd backend && source venv/bin/activate && python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

run-frontend:
	@echo "启动前端开发服务器..."
	cd ai-resume-web && npm run dev

run-all:
	@echo "同时启动前后端..."
	@make -j2 run-backend run-frontend

# 测试
test:
	@echo "运行所有测试..."
	cd backend && source venv/bin/activate && pytest tests/ test_*.py -v
	cd ai-resume-web && npm test

test-coverage:
	@echo "运行测试并生成覆盖率报告..."
	cd backend && source venv/bin/activate && pytest tests/ test_*.py --cov=app --cov-report=html --cov-report=term
	cd ai-resume-web && npm run test:coverage

test-backend:
	@echo "运行后端测试..."
	cd backend && source venv/bin/activate && pytest tests/ test_*.py -v

test-frontend:
	@echo "运行前端测试..."
	cd ai-resume-web && npm test

# 代码质量
lint:
	@echo "运行代码检查..."
	cd backend && source venv/bin/activate && ruff check app/
	cd ai-resume-web && npm run lint

lint-fix:
	@echo "自动修复代码问题..."
	cd backend && source venv/bin/activate && ruff check --fix app/
	cd ai-resume-web && npm run lint:fix

format:
	@echo "格式化代码..."
	cd backend && source venv/bin/activate && black app/ --line-length 100
	cd backend && source venv/bin/activate && isort app/
	cd ai-resume-web && npx prettier --write "src/**/*.{ts,tsx,js,jsx}"

security-check:
	@echo "运行安全扫描..."
	cd backend && source venv/bin/activate && bandit -r app/
	cd backend && source venv/bin/activate && safety check
	cd ai-resume-web && npm audit

# 构建和部署
build:
	@echo "构建 Docker 镜像..."
	docker-compose build

docker-up:
	@echo "启动 Docker Compose..."
	docker-compose up -d

docker-down:
	@echo "停止 Docker Compose..."
	docker-compose down

docker-logs:
	@echo "查看 Docker 日志..."
	docker-compose logs -f

clean:
	@echo "清理构建文件..."
	cd backend && rm -rf htmlcov/ .pytest_cache/ .coverage
	cd ai-resume-web && rm -rf dist/ node_modules/.vite coverage/
	docker system prune -f

deploy:
	@echo "部署到生产环境..."
	@read -p "确认部署到生产环境? (y/N) " -n 1 -r; \
	echo; \
	if [ $$REPLY = "y" ]; then \
		git pull origin main; \
		docker-compose --profile production up -d; \
		echo "部署完成!"; \
	else \
		echo "已取消部署"; \
	fi

# 数据库
db-backup:
	@echo "备份数据库..."
	@docker-compose exec -T db mysqldump -u airesume -pairesume_password ai_resume > backup_$$(date +%Y%m%d_%H%M%S).sql

db-restore:
	@echo "恢复数据库..."
	@read -p "输入备份文件名: " file; \
	docker-compose exec -T db mysql -u airesume -pairesume_password ai_resume < $$file

# 监控
health:
	@echo "健康检查..."
	@curl -f http://localhost:8000/health || echo "后端不健康"
	@curl -f http://localhost:3000 || echo "前端不健康"

logs:
	@echo "查看应用日志..."
	@docker-compose logs --tail=100 -f

# 快速命令
dev: install-dev run-all
ci: lint security-check test
all: clean install-dev build docker-up test
