# 步骤2: 在Dokploy中添加SSH公钥

## 操作步骤

1. **登录Dokploy面板**
   - 访问: http://113.45.64.145:3000
   - 邮箱: 641600780@qq.com
   - 密码: 353980swsgbo

2. **导航到SSH Keys设置**
   - 点击左侧菜单的 **Settings** (齿轮图标)
   - 选择 **SSH Keys** 选项卡

3. **添加新SSH密钥**
   - 点击 **Add SSH Key** 或 **+** 按钮
   - 填写以下信息:

     ```
     Name: devops-local-machine
     ```

   - **Public Key**: 粘贴以下完整内容（包含ssh-ed25519开头）

     ```
     ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhpLCnOdDAksakqgydJAqd3vL0rHvJ7I2N/SE6wHgu5 AI_Agent_Key
     ```

4. **保存配置**
   - 点击 **Save** 或 **Create** 按钮
   - 等待确认消息显示成功

## 验证SSH密钥

添加成功后，在本地测试SSH连接:

```bash
ssh -i ~/.ssh/id_ed25519 root@113.45.64.145 "echo 'SSH连接成功'"
```

预期输出: `SSH连接成功`

## 故障排查

**问题1: 密钥添加失败**
- 确保公钥内容完整（从ssh-ed25519开始到最后）
- 检查没有多余的空格或换行
- 尝试重新生成密钥对

**问题2: SSH连接失败**
- 验证服务器IP地址正确: 113.45.64.145
- 检查密钥权限: `chmod 600 ~/.ssh/id_ed25519`
- 确认服务器SSH服务运行: `telnet 113.45.64.145 22`

## 完成标志

✅ Dokploy面板显示新添加的SSH密钥
✅ 本地可以无密码SSH连接到服务器
✅ 可以继续下一步配置后端服务

---

**当前SSH公钥指纹**:
- 密钥类型: ed25519
- 注释: AI_Agent_Key
- 本地路径: /home/hongfu/.ssh/id_ed25519.pub
