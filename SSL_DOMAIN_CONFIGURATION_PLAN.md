# 域名和SSL配置规划

## 📋 项目信息
- **项目名称**: AI智能体简历平台
- **服务器IP**: 113.45.64.145
- **当前状态**: HTTP访问正常，待配置域名和HTTPS

---

## 🎯 配置目标

### 第一阶段: 域名配置
- [ ] 选择和注册域名
- [ ] 配置DNS解析
- [ ] 验证域名解析生效
- [ ] 更新应用配置

### 第二阶段: SSL证书配置
- [ ] 申请SSL证书
- [ ] 配置HTTPS服务
- [ ] 强制HTTPS重定向
- [ ] 配置HSTS头部

### 第三阶段: 优化和完善
- [ ] 配置CDN加速
- [ ] 启用HTTP/2
- [ ] 配置安全头部
- [ ] 设置证书自动续期

---

## 🌐 域名选择建议

### 推荐域名选项
1. **品牌域名**
   - `ai-resume.com`
   - `airesume.com`
   - `smart-resume.ai`

2. **功能域名**
   - `myairesume.com`
   - `resumeai.tech`
   - `intelligent-resume.com`

3. **国别域名**
   - `ai-resume.cn` (中国)
   - `ai-resume.io` (技术类)
   - `ai-resume.app` (应用类)

### 域名购买建议
**推荐注册商:**
- **阿里云**: 万网 (wanwang.aliyun.com)
- **腾讯云**: dnspod.cn
- **Cloudflare**: cloudflare.com
- **Namecheap**: namecheap.com

**注意事项:**
- 选择简短易记的域名
- 避免商标侵权
- 考虑国际化需求
- 比较价格和服务

---

## 🔄 DNS配置方案

### 方案A: 云服务商DNS
**优点**: 免费、简单、与服务器集成
**缺点**: 功能相对基础

**配置步骤:**
1. 在云服务商控制台找到DNS管理
2. 添加A记录:
   ```
   类型: A记录
   主机记录: @ (或 www)
   记录值: 113.45.64.145
   TTL: 600 (10分钟)
   ```

3. 添加CNAME记录 (可选):
   ```
   类型: CNAME
   主机记录: api
   记录值: @ (指向根域名)
   ```

### 方案B: Cloudflare DNS (推荐)
**优点**: 免费、CDN、DDoS防护、SSL
**缺点**: 需要迁移DNS

**配置步骤:**
1. 注册Cloudflare账户
2. 添加站点到Cloudflare
3. 更新域名服务器为Cloudflare NS
4. 添加DNS记录:
   ```
   类型: A
   名称: @
   IPv4地址: 113.45.64.145
   代理状态: 已代理 (橙色云朵)
   ```

---

## 🔒 SSL证书配置

### 方案A: Let's Encrypt (免费推荐)
**优点**: 免费、自动化、广泛支持
**缺点**: 需要定期续期(可自动化)

**配置方法:**
1. **安装Certbot**
   ```bash
   # 在服务器上执行
   sudo apt update
   sudo apt install certbot python3-certbot-nginx
   ```

2. **申请证书**
   ```bash
   # 自动配置Nginx
   sudo certbot --nginx -d your-domain.com -d www.your-domain.com

   # 或仅获取证书
   sudo certbot certonly --nginx -d your-domain.com
   ```

3. **自动续期**
   ```bash
   # 测试续期
   sudo certbot renew --dry-run

   # 自动续期已通过cron/systemd timer配置
   ```

### 方案B: 云服务商SSL
**优点**: 与云平台集成、管理方便
**缺点**: 可能有费用

**支持的云服务商:**
- **阿里云**: SSL证书服务
- **腾讯云**: SSL证书
- **Cloudflare**: Universal SSL

### 方案C: Dokploy集成配置
**优点**: 自动化、与部署流程集成
**配置步骤:**
1. 在Dokploy项目中配置SSL选项
2. 添加域名和证书路径
3. 启用HTTPS重定向

---

## 🚀 实施步骤

### 第一步: 域名准备 (1-2天)
1. **选择域名**
   - 检查域名可用性
   - 比较价格和服务
   - 购买域名

2. **配置DNS**
   - 登录域名管理控制台
   - 添加DNS记录指向服务器IP
   - 等待DNS生效(24-48小时)

### 第二步: SSL证书配置 (1-2小时)
1. **准备环境**
   ```bash
   # 确保域名已解析到服务器
   nslookup your-domain.com
   ```

2. **申请证书**
   ```bash
   # 使用Certbot申请Let's Encrypt证书
   sudo certbot --nginx -d your-domain.com -d www.your-domain.com
   ```

3. **验证证书**
   ```bash
   # 检查证书状态
   sudo certbot certificates

   # 测试HTTPS访问
   curl https://your-domain.com
   ```

### 第三步: 应用配置更新 (30分钟)
1. **更新环境变量**
   ```bash
   # .env.production
   DOMAIN=your-domain.com
   API_URL=https://api.your-domain.com
   FRONTEND_URL=https://your-domain.com
   ```

2. **更新Nginx配置**
   ```nginx
   server {
       listen 443 ssl http2;
       server_name your-domain.com www.your-domain.com;

       ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

       # SSL配置
       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_ciphers HIGH:!aNULL:!MD5;
       ssl_prefer_server_ciphers on;

       # HSTS
       add_header Strict-Transport-Security "max-age=31536000" always;
   }

   # HTTP重定向到HTTPS
   server {
       listen 80;
       server_name your-domain.com www.your-domain.com;
       return 301 https://$server_name$request_uri;
   }
   ```

3. **重启服务**
   ```bash
   sudo systemctl reload nginx
   docker-compose -f docker-compose.prod.yml restart
   ```

---

## 📊 成本估算

### 域名费用
- **.com域名**: $10-15/年
- **.tech域名**: $5-10/年
- **.ai域名**: $50-100/年

### SSL证书费用
- **Let's Encrypt**: 免费
- **商业证书**: $50-500/年
- **云服务商证书**: $0-500/年

### 总计首年预算
- **最低配置**: $10-25 (域名 + 免费SSL)
- **推荐配置**: $50-100 (优质域名 + 商业SSL)
- **高级配置**: $200-500 (premium域名 + 高级SSL)

---

## ✅ 验证清单

### 域名配置验证
- [ ] DNS解析生效: `nslookup your-domain.com`
- [ ] HTTP访问正常: `curl http://your-domain.com`
- [ ] 无DNS错误: 无MX/TXT配置错误

### SSL配置验证
- [ ] HTTPS访问正常: `curl https://your-domain.com`
- [ ] 证书有效: SSL Shopper检查
- [ ] 无安全警告: 浏览器无警告信息
- [ ] HTTP重定向: http自动跳转https

### 性能验证
- [ ] 页面加载速度正常
- [ ] SSL Labs评分A+
- [ ] 无混合内容错误

---

## 🔐 安全加固建议

### SSL配置优化
```nginx
# 启用现代加密协议
ssl_protocols TLSv1.2 TLSv1.3;

# 使用安全的加密套件
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;

# 启用HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

# 安全头部
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

### 安全监控
- 定期检查证书有效期
- 监控SSL握手错误
- 配置证书过期告警
- 定期安全扫描

---

## 📅 时间计划

### 阶段1: 准备 (1-3天)
- Day 1: 域名选择和购买
- Day 2: DNS配置和生效等待
- Day 3: DNS验证完成

### 阶段2: SSL配置 (1天)
- Day 4: 申请SSL证书
- Day 4: 配置HTTPS服务
- Day 4: 测试和验证

### 阶段3: 优化 (持续)
- Week 1: 监控和调优
- Week 2: 性能优化
- Month 1: 全面评估

---

## 🎓 技术要点

### 关键技术
- **DNS解析**: A记录、CNAME记录
- **SSL/TLS**: 证书申请、配置和续期
- **HTTP/HTTPS**: 协议配置和重定向
- **反向代理**: Nginx配置和优化

### 常见问题
1. **DNS生效慢**: 通常需要24-48小时
2. **证书申请失败**: 检查DNS和防火墙配置
3. **混合内容错误**: 确保所有资源使用HTTPS
4. **证书过期**: 配置自动续期

---

**文档版本**: v1.0
**创建日期**: 2026-04-06
**状态**: 规划阶段
**优先级**: 🟡 中等优先级 (防火墙配置完成后执行)