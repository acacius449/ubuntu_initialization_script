#!/bin/bash

# Ubuntu 安装 Node.js 18 LTS 脚本
# 作者: YXC
# 日期: $(date +%Y-%m-%d)

set -e  # 遇到错误立即退出

echo "开始安装 Node.js 18 LTS..."

# 检查 Node.js 是否已安装
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "⚠️  Node.js 已安装，版本: $NODE_VERSION"
    
    # 检查是否是 18.x 版本
    if [[ $NODE_VERSION == v18.* ]]; then
        echo "已安装 Node.js 18 LTS，跳过安装步骤"
        exit 0
    else
        echo "当前版本不是 18.x，继续安装 Node.js 18 LTS..."
    fi
else
    echo "未检测到 Node.js，开始安装..."
fi

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

# 安装和配置 Node.js

# 安装 Node.js 18 LTS
echo "正在安装 Node.js 18 LTS..."
nvm install 18
nvm use 18
nvm alias default 18

echo "Node.js $(node --version) 安装完成"

# 设置 npm 安装镜像
echo "正在设置 npm 镜像..."
npm config set registry https://registry.npmmirror.com/

echo "npm 镜像配置完成"
echo "当前 npm 源: $(npm config get registry)"

echo ""
echo "✅ Node.js 环境安装完成！"
echo "Node.js 版本: $(node --version)"
echo "npm 版本: $(npm --version)"
echo ""
