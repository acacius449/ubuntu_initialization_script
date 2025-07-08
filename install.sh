#!/bin/bash

# Ubuntu 开发环境配置脚本
# 作者: YXC
# 日期: $(date +%Y-%m-%d)

set -e # 遇到错误立即退出

echo "======================================================"
echo "🚀 开始配置开发环境"
echo "======================================================"
echo ""

# 检查 Ubuntu 版本兼容性
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
echo "检测到的 Ubuntu 版本: $UBUNTU_VERSION"

if [[ "$UBUNTU_VERSION" == "24.04" ]]; then
    echo "✅ 支持Ubuntu 24.04 LTS"
elif [[ "$UBUNTU_VERSION" == "22.04" ]]; then
    echo "✅ 支持Ubuntu 22.04 LTS"
else
    echo "⚠️  未在 Ubuntu $UBUNTU_VERSION 上测试过，可能存在兼容性问题"
    read -p "是否继续安装？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查必要文件是否存在
if [ ! -f "$SCRIPT_DIR/scripts/nvm.sh" ]; then
    echo "错误: scripts/nvm.sh 文件不存在"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/scripts/nodejs.sh" ]; then
    echo "错误: scripts/nodejs.sh 文件不存在"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/scripts/java.sh" ]; then
    echo "错误: scripts/java.sh 文件不存在"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/scripts/mysql.sh" ]; then
    echo "错误: scripts/mysql.sh 文件不存在"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/scripts/docker.sh" ]; then
    echo "错误: scripts/docker.sh 文件不存在"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/scripts/nacos.sh" ]; then
    echo "错误: scripts/nacos.sh 文件不存在"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/scripts/nginx.sh" ]; then
    echo "错误: scripts/nginx.sh 文件不存在"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/scripts/minio.sh" ]; then
    echo "错误: scripts/minio.sh 文件不存在"
    exit 1
fi

# 为脚本添加执行权限
chmod +x "$SCRIPT_DIR/scripts/nvm.sh"
chmod +x "$SCRIPT_DIR/scripts/nodejs.sh"
chmod +x "$SCRIPT_DIR/scripts/java.sh"
chmod +x "$SCRIPT_DIR/scripts/mysql.sh"
chmod +x "$SCRIPT_DIR/scripts/docker.sh"
chmod +x "$SCRIPT_DIR/scripts/nginx.sh"
chmod +x "$SCRIPT_DIR/scripts/nacos.sh"
chmod +x "$SCRIPT_DIR/scripts/minio.sh"

echo "第一步: 安装和配置 nvm"
echo "------------------------------------------------------"
bash "$SCRIPT_DIR/scripts/nvm.sh"

echo ""
echo "第二步: 安装 Node.js 18 LTS"
echo "------------------------------------------------------"
bash "$SCRIPT_DIR/scripts/nodejs.sh"

echo ""
echo "第三步: 安装 OpenJDK 8 和 OpenJDK 11"
echo "------------------------------------------------------"
bash "$SCRIPT_DIR/scripts/java.sh"

echo ""
echo "第四步: 安装 MySQL 8"
echo "------------------------------------------------------"
bash "$SCRIPT_DIR/scripts/mysql.sh"

echo ""
echo "第五步: 安装 Docker"
echo "------------------------------------------------------"
bash "$SCRIPT_DIR/scripts/docker.sh"

echo ""
echo "第六步: 安装 Nacos"
echo "------------------------------------------------------"
bash "$SCRIPT_DIR/scripts/nacos.sh"

echo ""
echo "第七步: 安装 Nginx"
echo "------------------------------------------------------"
bash "$SCRIPT_DIR/scripts/nginx.sh"

echo ""
echo "第八步: 安装 MinIO"
echo "------------------------------------------------------"
bash "$SCRIPT_DIR/scripts/minio.sh"

echo ""
echo "======================================================"
echo "🎉 安装完成！开发环境已成功配置"
echo "======================================================"
echo ""
echo "环境已自动加载完成！"
echo "如果要在当前终端窗口中使用这些工具，请执行以下命令："
echo "source ~/.bashrc"
echo ""
echo "已安装的环境："
echo "  • nvm + Node.js 18 LTS"
echo "  • OpenJDK 8 (默认) + OpenJDK 11"
echo "  • MySQL 8.0 数据库"
echo "  • Docker CE + Docker Compose"
echo "  • Nacos 2.5.1 单机模式 (端口: 8848)"
echo "  • Nginx 1.27.5 (端口: 80/443)"
echo "  • MinIO 对象存储 (端口: 9000/9001)"
echo ""
echo "======================================================"
