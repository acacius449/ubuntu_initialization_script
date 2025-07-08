#!/bin/bash

# Ubuntu 离线安装 MinIO 脚本
# 作者: YXC
# 日期: $(date +%Y-%m-%d)
# 说明: 使用预下载的 deb 包离线安装 MinIO
# 依赖: 需要 packages 目录中包含 MinIO deb 包

set -e # 遇到错误立即退出

echo "开始离线安装 MinIO..."

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 加载环境变量
ENV_FILE="$PROJECT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    echo "加载环境变量配置..."
    source "$ENV_FILE"
else
    echo "❌ 错误: .env 文件不存在: $ENV_FILE"
    echo "请确保项目根目录下存在 .env 文件，并包含 MINIO_ROOT_USER 和 MINIO_ROOT_PASSWORD 配置"
    exit 1
fi

# 检查必需的环境变量
if [ -z "$MINIO_ROOT_USER" ] || [ -z "$MINIO_ROOT_PASSWORD" ]; then
    echo "❌ 错误：缺少必需的环境变量"
    echo ""
    echo "请在项目根目录的 .env 文件中，包含以下内容："
    echo ""
    echo "MINIO_ROOT_USER=你的管理员用户名"
    echo "MINIO_ROOT_PASSWORD=你的管理员密码"
    echo ""
    exit 1
fi

echo "✅ 环境变量检查通过"

# 检查 MinIO 是否已安装
if command -v minio &>/dev/null; then
    MINIO_VERSION=$(minio --version 2>/dev/null | head -n 1)
    echo "⚠️ MinIO 已安装: $MINIO_VERSION"

    # 检查服务状态
    if systemctl is-active --quiet minio; then
        echo "MinIO 服务正在运行"
        echo "跳过 MinIO 安装步骤"
        exit 0
    else
        echo "MinIO 已安装但服务未运行，将重新配置..."
    fi
elif dpkg -l | grep -q "minio"; then
    echo "⚠️ 检测到 MinIO 包已安装"
    echo "跳过 MinIO 安装步骤"
    exit 0
else
    echo "未检测到 MinIO，开始安装..."
fi

PACKAGES_DIR="$PROJECT_DIR/packages"

# 检查 packages 目录是否存在
if [ ! -d "$PACKAGES_DIR" ]; then
    echo "❌ 错误: packages 目录不存在: $PACKAGES_DIR"
    echo "请确保 packages 目录存在并包含所需的 MinIO deb 包"
    exit 1
fi

# 检查必需的 deb 包是否存在
echo "正在检查 MinIO 安装包..."
MINIO_PACKAGE=$(find "$PACKAGES_DIR" -name "minio_*.deb" | head -1)
if [ -z "$MINIO_PACKAGE" ]; then
    echo "❌ 错误: 在 $PACKAGES_DIR 目录下未找到 minio_*.deb 文件"
    echo "请确保 packages 目录包含 MinIO deb 包"
    exit 1
fi

# 从文件名提取版本号
MINIO_VERSION=$(basename "$MINIO_PACKAGE" | sed 's/minio_\(.*\)_amd64\.deb/\1/')
echo "✅ 检测到 MinIO 版本: $MINIO_VERSION"

# 使用 dpkg 安装 MinIO deb 包
echo "正在从 deb 包安装 MinIO..."
sudo dpkg -i "$MINIO_PACKAGE"

# 修复可能的依赖问题
echo "正在修复依赖关系..."
sudo apt-get install -f -y

echo "✅ MinIO 安装包安装完成"

# 创建 MinIO 用户和组
echo "正在创建 minio 用户..."
MINIO_USER="minio"
MINIO_GROUP="minio"

if ! getent group $MINIO_GROUP >/dev/null 2>&1; then
    sudo groupadd $MINIO_GROUP
fi

if ! getent passwd $MINIO_USER >/dev/null 2>&1; then
    sudo useradd -r -g $MINIO_GROUP -s /bin/bash -d /home/$MINIO_USER $MINIO_USER
    sudo mkdir -p /home/$MINIO_USER
    sudo chown $MINIO_USER:$MINIO_GROUP /home/$MINIO_USER
fi

# 创建 MinIO 数据和配置目录
echo "正在创建 MinIO 目录结构..."
MINIO_DATA_DIR="/var/lib/minio/data"
MINIO_CONFIG_DIR="/etc/minio"

sudo mkdir -p $MINIO_DATA_DIR
sudo mkdir -p $MINIO_CONFIG_DIR

# 创建环境配置文件
echo "正在配置 MinIO 环境..."
sudo tee $MINIO_CONFIG_DIR/minio.env >/dev/null <<EOF
# MinIO 服务配置
MINIO_ROOT_USER=$MINIO_ROOT_USER
MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD
MINIO_VOLUMES=$MINIO_DATA_DIR
MINIO_OPTS="--console-address :9001"
EOF

# 查找 MinIO 可执行文件的实际路径
echo "正在查找 MinIO 可执行文件路径..."
MINIO_BIN=$(which minio 2>/dev/null || find /usr -name minio -type f -executable 2>/dev/null | head -1)

# 如果找不到，使用默认路径
if [ -z "$MINIO_BIN" ]; then
    MINIO_BIN="/usr/bin/minio"
    echo "未找到 MinIO 可执行文件，将使用默认路径: $MINIO_BIN"
else
    echo "找到 MinIO 可执行文件路径: $MINIO_BIN"
fi

# 确保可执行文件有执行权限
if [ -f "$MINIO_BIN" ]; then
    sudo chmod +x "$MINIO_BIN"
    echo "已设置 MinIO 可执行文件权限"
fi

# 创建 systemd 服务文件
echo "正在创建 systemd 服务..."
sudo tee /etc/systemd/system/minio.service >/dev/null <<EOF
[Unit]
Description=MinIO
Documentation=https://min.io/docs/minio/linux/index.html
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=$MINIO_USER
Group=$MINIO_GROUP
EnvironmentFile=$MINIO_CONFIG_DIR/minio.env
ExecStart=$MINIO_BIN server \$MINIO_OPTS \$MINIO_VOLUMES
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
TasksMax=infinity
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF

# 设置文件权限
echo "正在设置目录权限..."
sudo mkdir -p $MINIO_DATA_DIR
sudo mkdir -p $MINIO_CONFIG_DIR
sudo chown -R $MINIO_USER:$MINIO_GROUP $MINIO_DATA_DIR
sudo chown -R $MINIO_USER:$MINIO_GROUP $MINIO_CONFIG_DIR
sudo chmod -R 750 $MINIO_DATA_DIR
sudo chmod -R 750 $MINIO_CONFIG_DIR

# 启动 MinIO 服务
echo "正在启动 MinIO 服务..."
sudo systemctl daemon-reload
sudo systemctl enable minio
sudo systemctl start minio

# 等待服务启动
echo "等待 MinIO 服务启动..."
sleep 5

# 验证安装
echo "正在验证 MinIO 安装..."
# 检查服务状态
if ! systemctl is-active --quiet minio; then
    echo "MinIO 服务未能正常启动，尝试查看错误日志..."
    sudo journalctl -u minio --no-pager -n 20
    echo "尝试手动启动服务..."
    sudo systemctl restart minio
    sleep 3
fi

if sudo systemctl is-active --quiet minio; then
    echo "MinIO 安装验证成功！"

    # 检查端口是否监听
    if netstat -tlnp 2>/dev/null | grep -q ":9000 "; then
        echo "MinIO API 端口 9000 已正常监听"
    else
        echo "警告: MinIO API 端口 9000 未检测到监听，服务可能还在启动中"
        echo "请等待片刻后检查: netstat -tlnp | grep 9000"
    fi

    if netstat -tlnp 2>/dev/null | grep -q ":9001 "; then
        echo "MinIO Console 端口 9001 已正常监听"
    else
        echo "警告: MinIO Console 端口 9001 未检测到监听，服务可能还在启动中"
        echo "请等待片刻后检查: netstat -tlnp | grep 9001"
    fi
else
    echo "警告: MinIO 安装验证失败，请检查配置"
    echo "查看日志: sudo journalctl -u minio -f"
fi

echo ""
echo "✅ MinIO 安装配置完成！"
echo ""
echo "MinIO 服务信息:"
echo "  • 安装方式: 使用 deb 包离线安装"
echo "  • MinIO 版本: $MINIO_VERSION"
echo "  • 服务状态: $(systemctl is-active minio 2>/dev/null || echo '未运行')"
echo "  • 数据目录: $MINIO_DATA_DIR"
echo "  • 配置目录: $MINIO_CONFIG_DIR"
echo "  • API 端口: 9000 (默认)"
echo "  • 控制台端口: 9001 (默认)"
echo "  • 用户名: $MINIO_ROOT_USER"
echo "  • 密码: $MINIO_ROOT_PASSWORD"
echo ""
# 尝试获取外网IP
echo "正在获取IP地址信息..."
LOCAL_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || curl -s http://ifconfig.me 2>/dev/null || echo "无法获取")

echo "访问方式:"
echo "  • API 端点(内网): http://$LOCAL_IP:9000"
echo "  • Web 控制台(内网): http://$LOCAL_IP:9001"

if [ "$PUBLIC_IP" != "无法获取" ]; then
    echo "  • API 端点(外网): http://$PUBLIC_IP:9000 (需确保端口已开放)"
    echo "  • Web 控制台(外网): http://$PUBLIC_IP:9001 (需确保端口已开放)"
else
    echo "  • 未能获取外网 IP，请确保服务器能够访问互联网或手动查询外网 IP"
fi
echo ""
echo "常用命令："
echo "  查看服务状态: sudo systemctl status minio"
echo "  启动服务: sudo systemctl start minio"
echo "  停止服务: sudo systemctl stop minio"
echo "  重启服务: sudo systemctl restart minio"
echo "  查看日志: sudo journalctl -u minio -f"
echo ""
echo "⚠️ 安全提醒："
echo "  • 请确保 .env 文件中的凭据安全"
echo "  • 修改方法: 编辑 .env 文件后重新运行此脚本，或直接编辑 $MINIO_CONFIG_DIR/minio.env 文件后重启服务"
echo ""
echo "📦 packages 目录要求："
echo "  • minio_<version>_amd64.deb"
echo "  • 可从 https://min.io/download 下载"
echo "" 