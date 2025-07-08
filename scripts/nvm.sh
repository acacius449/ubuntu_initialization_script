#!/bin/bash

# Ubuntu 离线安装 nvm 脚本
# 作者: YXC
# 日期: $(date +%Y-%m-%d)

set -e # 遇到错误立即退出

echo "开始安装 nvm..."

# 检查 nvm 是否已安装
if [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ]; then
    # 尝试加载 nvm 并检查版本
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if command -v nvm &>/dev/null; then
        echo "⚠️  nvm 已安装，版本: $(nvm --version)"
        echo "跳过 nvm 安装步骤"
        exit 0
    fi
fi

echo "未检测到 nvm，开始安装..."

# 安装和配置 nvm

# 使用 packages 目录下的 nvm 压缩包，离线安装 nvm
echo "正在离线安装 nvm..."

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 检查 packages/nvm-0.40.3.tar.gz 是否存在
if [ ! -f "$PROJECT_ROOT/packages/nvm-0.40.3.tar.gz" ]; then
    echo "错误: $PROJECT_ROOT/packages/nvm-0.40.3.tar.gz 文件不存在"
    exit 1
fi

# 解压 nvm 到 ~/.nvm 目录
mkdir -p ~/.nvm
cd ~/.nvm
tar -xzf "$PROJECT_ROOT/packages/nvm-0.40.3.tar.gz" --strip-components=1
cd - >/dev/null

echo "nvm 解压完成"

# 加载 nvm 环境
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 检查 nvm 是否可用
if ! command -v nvm &> /dev/null; then
    echo "错误: nvm 未正确安装或未加载，请先运行 nvm.sh"
    exit 1
fi

# 设置 node 安装镜像
echo "正在设置 Node.js 安装镜像..."
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
echo "Node.js 镜像设置为: $NVM_NODEJS_ORG_MIRROR"

# 修改 .bashrc
echo "正在配置 .bashrc..."

# 检查是否已经添加了 nvm 配置
if ! grep -q "NVM_DIR" ~/.bashrc; then
    echo "" >>~/.bashrc
    echo "# NVM 配置" >>~/.bashrc
    echo 'export NVM_DIR="$HOME/.nvm"' >>~/.bashrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >>~/.bashrc
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >>~/.bashrc
    echo "" >>~/.bashrc
    echo "# NVM Node.js 镜像配置" >>~/.bashrc
    echo 'export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/' >>~/.bashrc
    echo ".bashrc 配置完成"
else
    echo ".bashrc 中已存在 nvm 配置，检查是否需要添加镜像配置..."
    # 检查是否已经配置了镜像
    if ! grep -q "NVM_NODEJS_ORG_MIRROR" ~/.bashrc; then
        echo "" >>~/.bashrc
        echo "# NVM Node.js 镜像配置" >>~/.bashrc
        echo 'export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/' >>~/.bashrc
        echo "镜像配置已添加到 .bashrc"
    else
        echo "镜像配置已存在，跳过配置"
    fi
fi

echo ""
echo "✅ nvm 安装配置完成！"
echo "nvm 版本: $(nvm --version)"
echo "NVM_NODEJS_ORG_MIRROR: $NVM_NODEJS_ORG_MIRROR"
echo ""
