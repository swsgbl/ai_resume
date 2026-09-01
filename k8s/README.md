# Kubernetes 部署指南 - AI Resume

本指南描述如何将 AI Resume 应用部署到 Kubernetes 集群。

## 前置要求

- Kubernetes 1.25+ 集群
- kubectl 已配置并连接到集群
- Helm 3+ (可选，用于安装 ingress-nginx)
- 域名和 DNS 配置

## 快速开始

### 1. 创建命名空间

```bash
kubectl apply -f k8s/namespace.yaml
```

### 2. 配置密钥

**重要**: 在部署前，必须更新 `k8s/secret.yaml` 中的敏感信息：

```bash
# 编辑密钥文件
vim k8s/secret.yaml

# 或使用 kubectl create secret 命令
kubectl create secret generic app-secrets \
  --from-literal=SECRET_KEY=$(openssl rand -hex 32) \
  --from-literal=JWT_SECRET_KEY=$(openssl rand -hex 32) \
  --from-literal=MYSQL_PASSWORD=your-secure-password \
  --from-literal=OPENAI_API_KEY=sk-your-key \
  --from-literal=DEEPSEEK_API_KEY=sk-your-key \
  --from-literal=XIAOMI_API_KEY=your-key \
  --namespace=ai-resume
```

### 3. 应用配置

```bash
# 应用配置和密钥
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# 部署应用
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# 部署自动扩缩容
kubectl apply -f k8s/hpa.yaml

# 部署 Ingress (需要先安装 ingress-nginx)
kubectl apply -f k8s/ingress.yaml
```

### 4. 验证部署

```bash
# 检查 Pod 状态
kubectl get pods -n ai-resume

# 检查服务
kubectl get svc -n ai-resume

# 检查 Ingress
kubectl get ingress -n ai-resume

# 查看日志
kubectl logs -f deployment/backend -n ai-resume
kubectl logs -f deployment/frontend -n ai-resume
```

## 安装 Ingress Controller

如果集群还没有安装 ingress-nginx：

```bash
# 使用 Helm 安装
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# 或使用 kubectl
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
```

## 安装 Cert-Manager (自动 HTTPS)

```bash
# 安装 cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml

# 创建 ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## 配置自定义域名

1. 更新 `k8s/ingress.yaml` 中的域名
2. 更新 `k8s/configmap.yaml` 中的 CORS_ORIGINS
3. 配置 DNS 记录指向 Ingress IP

## 扩缩容

### 手动扩缩容

```bash
# 扩展 backend 到 5 个副本
kubectl scale deployment backend --replicas=5 -n ai-resume

# 扩展 frontend 到 3 个副本
kubectl scale deployment frontend --replicas=3 -n ai-resume
```

### 自动扩缩容

HPA 已配置，会根据 CPU/内存使用率自动调整副本数 (2-10)。

```bash
# 查看 HPA 状态
kubectl get hpa -n ai-resume
```

## 持久化存储

MySQL 数据使用 PVC 持久化：

```bash
# 查看 PVC
kubectl get pvc -n ai-resume

# 备份数据
kubectl exec -it mysql-0 -n ai-resume -- mysqldump -u root -p ai_resume > backup.sql
```

## 监控和日志

```bash
# 实时日志
kubectl logs -f deployment/backend -n ai-resume
kubectl logs -f deployment/frontend -n ai-resume

# 所有 Pod 日志
kubectl logs -f -n ai-resume --all-containers=true

# 查看 Pod 详情
kubectl describe pod -n ai-resume <pod-name>

# 进入 Pod
kubectl exec -it -n ai-resume <pod-name> -- /bin/bash
```

## 故障排查

### Pod 无法启动

```bash
# 查看 Pod 状态
kubectl get pods -n ai-resume

# 查看 Pod 事件
kubectl describe pod -n ai-resume <pod-name>

# 查看日志
kubectl logs -n ai-resume <pod-name>
```

### 服务无法访问

```bash
# 测试服务连通性
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -n ai-resume -- wget -O- http://backend:8000/health
```

### Ingress 不工作

```bash
# 检查 Ingress Controller
kubectl get pods -n ingress-nginx

# 查看 Ingress 详情
kubectl describe ingress ai-resume-ingress -n ai-resume
```

## 更新部署

```bash
# 重建部署
kubectl rollout restart deployment/backend -n ai-resume
kubectl rollout restart deployment/frontend -n ai-resume

# 查看部署状态
kubectl rollout status deployment/backend -n ai-resume

# 回滚
kubectl rollout undo deployment/backend -n ai-resume
```

## 清理

```bash
# 删除所有资源
kubectl delete namespace ai-resume

# 或单独删除
kubectl delete -f k8s/
```

## 生产环境检查清单

- [ ] 更新所有默认密码和密钥
- [ ] 配置正确的域名和 DNS
- [ ] 启用 HTTPS (cert-manager)
- [ ] 配置资源限制和请求
- [ ] 设置监控和告警
- [ ] 配置日志收集
- [ ] 配置备份策略
- [ ] 测试灾难恢复流程
