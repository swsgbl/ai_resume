# 仓颉语言开发环境配置指南 (Ubuntu 25.10)

本文档详细介绍如何在 Ubuntu 25.10 上配置鸿蒙/仓颉开发环境，核心使用 Mise 管理依赖版本。

## 目录

1. [环境现状](#环境现状)
2. [Mise 配置](#mise-配置)
3. [DevEco Studio 安装](#deveco-studio-安装)
4. [仓颉 SDK 配置](#仓颉-sdk-配置)
5. [VSCode 配置](#vscode-配置)
6. [验证环境](#验证环境)

---

## 环境现状

当前系统已安装并配置的工具：

- **操作系统**: Ubuntu 25.10 (Questing Quokka)
- **Mise**: v2026.3.10 (已安装在 `~/.local/bin/mise`)
- **Python**: v3.14.3 (由 Mise 管理)
- **Node.js**: v24.14.0 (由 Mise 管理)
- **Go**: v1.26.1 (由 Mise 管理)

## Mise 配置

### 当前配置文件位置

```bash
~/.config/mise/config.toml
```

### 添加仓颉开发相关工具

在 `~/.config/mise/config.toml` 中添加以下配置：

```toml
# mise 配置文件 - 鸿蒙/仓颉开发环境

[tools]
# Node.js - 构建工具需要
node = "lts"           # 当前: 24.14.0

# Python - 后端服务
python = "3.14"        # 当前: 3.14.3

# Go - 部分工具需要
go = "latest"          # 当前: 1.26.1

# Java - DevEco Studio 需要
java = "corretto-17"   # OpenJDK 17 LTS

# Gradle - 构建工具
gradle = "8.5"

# pnpm - 包管理器
pnpm = "latest"

[env]
# HarmonyOS SDK 路径 (安装后配置)
# HOS_SDK_HOME = "$HOME/Huawei/Sdk"

# DevEco Studio 路径 (安装后配置)  
# DEVECO_HOME = "$HOME/Huawei/DevEcoStudio"

# 仓颉编译器路径 (安装后配置)
# CJ_HOME = "$HOME/Huawei/Cangjie"
# PATH_add = "$CJ_HOME/bin"

[settings]
# 自动安装缺失的工具
auto_install = true

# 自动切换版本
experimental = true
```

### 应用新配置

```bash
# 重新加载配置
mise install

# 激活 shell 集成 (如果尚未配置)
# 在 ~/.bashrc 或 ~/.zshrc 中添加:
eval "$(mise activate bash)"  # bash 用户
# 或
eval "$(mise activate zsh)"   # zsh 用户
```

---

## DevEco Studio 安装

### 方法一：官方安装包 (推荐)

1. **下载 DevEco Studio**
   ```bash
   # 创建安装目录
   mkdir -p ~/Huawei
   cd ~/Huawei
   
   # 下载 Linux 版本 (访问官网获取最新链接)
   # https://developer.huawei.com/consumer/cn/deveco-studio/
   wget https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_package_9_10/e426a72b0e754b07b5b7b1f2e6a5a5ee/Deveco-Studio-4.0.2.600-linux.tar.gz
   
   # 解压
   tar -xzf Deveco-Studio-4.0.2.600-linux.tar.gz
   
   # 重命名
   mv Deveco-Studio-4.0.2.600 DevEcoStudio
   ```

2. **安装依赖**
   ```bash
   # Ubuntu/Debian 依赖
   sudo apt update
   sudo apt install -y \
       libnss3 \
       libnspr4 \
       libdbus-1-3 \
       libatk1.0-0 \
       libatk-bridge2.0-0 \
       libcups2 \
       libdrm2 \
       libxkbcommon0 \
       libxcomposite1 \
       libxdamage1 \
       libxfixes3 \
       libxrandr2 \
       libgbm1 \
       libasound2t64 \
       libpango-1.0-0 \
       libcairo2 \
       libatspi2.0-0 \
       libxshmfence1
   ```

3. **启动 DevEco Studio**
   ```bash
   cd ~/Huawei/DevEcoStudio/bin
   ./studio.sh
   ```

### 方法二：使用 Snap (简化安装)

```bash
# 注意：官方暂未提供 Snap 包，建议使用方法一
```

### 初始化 SDK

首次启动 DevEco Studio 后：

1. 接受许可协议
2. 下载 HarmonyOS SDK (API 10+)
3. 配置 SDK 路径 (默认 `~/Huawei/Sdk`)

---

## 仓颉 SDK 配置

### 安装仓颉编译器

1. **通过 DevEco Studio 安装** (推荐)
   - DevEco Studio 4.0+ 已内置仓颉编译器
   - SDK 路径: `~/Huawei/Sdk/cangjie/{version}`

2. **手动安装**
   ```bash
   # 创建目录
   mkdir -p ~/Huawei/Cangjie
   cd ~/Huawei/Cangjie
   
   # 从官方渠道下载仓颉 SDK (需要华为开发者账号)
   # 解压后设置环境变量
   export CJ_HOME="$HOME/Huawei/Cangjie"
   export PATH="$CJ_HOME/bin:$PATH"
   ```

### 环境变量配置

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
# HarmonyOS 开发环境
export HOS_SDK_HOME="$HOME/Huawei/Sdk"
export DEVECO_HOME="$HOME/Huawei/DevEcoStudio"
export CJ_HOME="$HOME/Huawei/Cangjie"

# 添加到 PATH
export PATH="$HOS_SDK_HOME:$PATH"
export PATH="$CJ_HOME/bin:$PATH"
```

然后执行：

```bash
source ~/.bashrc  # 或 source ~/.zshrc
```

---

## VSCode 配置

### 安装推荐扩展

创建项目级扩展推荐配置：

```json
// .vscode/extensions.json
{
  "recommendations": [
    "ms-vscode.vscode-typescript-next",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "bradlc.vscode-tailwindcss",
    "ms-python.python",
    "ms-python.vscode-pylance",
    "golang.go",
    "redhat.vscode-yaml",
    "editorconfig.editorconfig",
    "streetsidesoftware.code-spell-checker",
    "yzhang.markdown-all-in-one"
  ]
}
```

### 工作区设置

更新 `.vscode/settings.json`：

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  },
  
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "python.formatting.provider": "none",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true
  },
  
  // 仓颉语言支持 (如果有扩展)
  "[cangjie]": {
    "editor.formatOnSave": true
  },
  
  // 文件关联
  "files.associations": {
    "*.cj": "cangjie",
    "*.json5": "json5"
  },
  
  // Mise 集成
  "mise.autoInstall": true,
  
  // 终端配置
  "terminal.integrated.env.linux": {
    "HOS_SDK_HOME": "${env:HOME}/Huawei/Sdk",
    "DEVECO_HOME": "${env:HOME}/Huawei/DevEcoStudio"
  }
}
```

### 安装 Mise VSCode 扩展

```bash
code --install-extension jdxcode.mise-vscode
```

---

## 验证环境

### 1. 验证 Mise 工具链

```bash
# 检查所有已安装工具
mise ls

# 验证 Python
python3 --version  # 应显示 3.14.3

# 验证 Node.js
node --version     # 应显示 v24.14.0

# 验证 Go
go version         # 应显示 go1.26.1
```

### 2. 验证 DevEco Studio

```bash
# 检查 DevEco 安装
ls -la ~/Huawei/DevEcoStudio/bin/studio.sh

# 检查 SDK
ls -la ~/Huawei/Sdk
```

### 3. 验证仓颉编译器

```bash
# 如果已安装独立 SDK
which cjc
cjc --version

# 或通过 DevEco SDK 查找
find ~/Huawei/Sdk -name "cjc" 2>/dev/null
```

### 4. 测试项目构建

```bash
cd /home/hongfu/ai-resume/ai-resume-harmonyos

# 如果有 hvigor (构建工具)
npm install  # 或 pnpm install
npm run build
```

---

## 常见问题

### Q: DevEco Studio 启动失败？

**A:** 检查依赖是否完整：

```bash
# 检查缺失的库
ldd ~/Huawei/DevEcoStudio/bin/studio.sh

# 安装缺失依赖
sudo apt --fix-broken install
```

### Q: 仓颉编译器找不到？

**A:** 确保：
1. DevEco Studio 已下载 SDK
2. 环境变量正确设置
3. PATH 包含 `$CJ_HOME/bin`

### Q: Mise 工具版本冲突？

**A:** 项目级配置优先级更高：

```bash
# 在项目根目录创建 .mise.toml
cd /home/hongfu/ai-resume/ai-resume-harmonyos
mise use node@20.11.0  # 指定项目需要的版本
```

### Q: VSCode 找不到仓颉语法高亮？

**A:** 目前仓颉扩展较少，可以：
1. 等待官方扩展发布
2. 使用 DevEco Studio 进行主要开发
3. 配置 TextMate 语法规则

---

## 下一步

1. **完成 DevEco Studio 安装**
2. **下载 HarmonyOS SDK API 10+**
3. **配置真机调试或模拟器**
4. **运行项目测试环境**

---

## 参考资源

- [Mise 官方文档](https://mise.jdx.dev/)
- [DevEco Studio 下载](https://developer.huawei.com/consumer/cn/deveco-studio/)
- [HarmonyOS 开发文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/application-dev-guide-V5)
- [仓颉语言文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/cangjie-overview-V5)

---

**更新日期**: 2026-03-29
**适用系统**: Ubuntu 25.10 (Questing Quokka)
