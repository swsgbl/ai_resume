# 仓颉开发环境快速安装指南 (Ubuntu Linux)

## 环境状态 ✓

已完成配置：
- ✓ Mise 环境管理 (Python 3.14.3, Node.js 24.14.0)
- ✓ 编译依赖 (binutils, cmake, ninja-build, libc++-dev)
- ✓ OpenSSL 3.5.3
- ✓ VSCode + HarmonyOS/ArkTS 插件
- ✓ 全局环境变量配置

## 三种安装方式

### 方式一：官网下载（推荐）⭐

**步骤：**
1. 访问 https://cangjie-lang.cn/download
2. 登录华为账号
3. 下载 **Linux x64** 版本的 SDK (`cangjie-sdk-linux-x64-x.y.z.tar.gz`)
4. 运行安装脚本：
   ```bash
   ./scripts/install-cangjie-sdk.sh ~/Downloads/cangjie-sdk-linux-x64-*.tar.gz
   ```

### 方式二：从源码编译

```bash
# 运行自动编译脚本（约 30-60 分钟）
./scripts/install-cangjie-sdk.sh
# 选择选项 2
```

### 方式三：华为云开发者空间（无需本地安装）

- 访问：https://developer.huaweicloud.com/developer/space
- 免费云主机，预装仓颉工具链
- 5x8 小时/周免费使用

## VSCode 插件配置

### 已安装的插件 ✓

```bash
# HarmonyOS/ArkTS 相关插件（已安装）
- cheliangzhao.arkts-language-support
- cloris.better-arkts  
- corn12138.harmony-dev-tools
- huawei-developer.arkts-language-client
```

### 安装官方仓颉插件

**方式一：VSCode 扩展市场**
1. 打开 VSCode
2. 按 `Ctrl+Shift+X` 打开扩展市场
3. 搜索 "Cangjie"
4. 点击 Install

**方式二：手动安装 vsix**
1. 从 https://cangjie-lang.cn/download 下载插件包
2. VSCode 中按 `Ctrl+Shift+P`
3. 输入 "Extensions: Install from VSIX"
4. 选择下载的 `.vsix` 文件

### 配置 SDK 路径

安装仓颉 SDK 后，在 VSCode 中配置：

1. `Ctrl+,` 打开设置
2. 搜索 "Cangjie"
3. 设置 `Cangjie Sdk Path` 为 SDK 路径：
   ```
   /home/你的用户名/Huawei/Cangjie
   ```
4. 重启 VSCode

## 验证安装

```bash
# 方式一：命令行验证
source ~/.bashrc
cjc -v

# 方式二：运行环境检查
./scripts/check-harmonyos-env.sh

# 方式三：VSCode 验证
# Ctrl+Shift+P → 输入 "cangjie: Create Cangjie Project"
```

## 快速测试

创建第一个仓颉程序：

```bash
# 创建项目目录
mkdir -p ~/cangjie-projects/hello
cd ~/cangjie-projects/hello

# 创建源文件
cat > hello.cj << 'EOF'
main(): Int64 {
    println("Hello, Cangjie!")
    return 0
}
EOF

# 编译运行
cjc hello.cj -o hello
./hello
```

## 项目级配置

对于 `ai-resume-harmonyos` 项目，已创建：

- `.mise.toml` - 项目级工具版本
- `scripts/install-cangjie-sdk.sh` - SDK 安装脚本
- `scripts/check-harmonyos-env.sh` - 环境检查脚本

## 常见问题

### Q: 仓颉插件找不到？

A: 官方插件可能需要从官网下载 vsix 手动安装。ArkTS 插件可用于 HarmonyOS 开发。

### Q: 编译报错找不到标准库？

A: 确保已正确配置 SDK 路径：
```bash
export CJ_HOME="$HOME/Huawei/Cangjie"
source "$CJ_HOME/envsetup.sh"
```

### Q: DevEco Studio 没有 Linux 版？

A: 使用仓颉 SDK + VSCode 组合，或使用华为云开发者空间。

## 下一步

1. **下载并安装仓颉 SDK** (从官网或运行脚本)
2. **配置 VSCode 插件**
3. **运行环境检查**: `./scripts/check-harmonyos-env.sh`
4. **开始开发**: 用 VSCode 打开 `ai-resume-harmonyos/`

---

**参考文档：**
- 仓颉官方文档: https://docs.cangjie-lang.cn
- 下载中心: https://cangjie-lang.cn/download
- VSCode 插件指南: https://docs.cangjie-lang.cn/tools/IDE/user_manual_community.html
