#!/bin/bash

# Ubuntu 安装 Nacos 脚本
# 作者: YXC
# 日期: $(date +%Y-%m-%d)

set -e # 遇到错误立即退出

echo "开始安装 Nacos..."

# 基本配置
NACOS_USER="nacos"
NACOS_GROUP="nacos"

# 固定安装目录到 /usr/local
NACOS_HOME="/usr/local/nacos"

echo "Nacos 安装目录: $NACOS_HOME"

# 获取脚本所在目录的父目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 自动检测 Nacos 版本（从文件名读取）
NACOS_PACKAGE=$(find "$PROJECT_DIR/packages" -name "nacos-server-*.tar.gz" | head -1)
if [ -z "$NACOS_PACKAGE" ]; then
    echo "错误: 在 $PROJECT_DIR/packages 目录下未找到 nacos-server-*.tar.gz 文件"
    exit 1
fi

# 从文件名提取版本号
NACOS_VERSION=$(basename "$NACOS_PACKAGE" | sed 's/nacos-server-\(.*\)\.tar\.gz/\1/')
echo "检测到 Nacos 版本: $NACOS_VERSION"

# 检查 Java 环境
if ! command -v java &>/dev/null; then
    echo "错误: Java 未安装，请先运行 java.sh 安装 Java 环境"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | sed '/^1\./s///' | cut -d'.' -f1)
if [[ $JAVA_VERSION -lt 8 ]]; then
    echo "错误: Nacos 需要 Java 8 或更高版本，当前版本: $JAVA_VERSION"
    exit 1
fi

echo "Java 环境检查通过: $(java -version 2>&1 | head -1)"

# 检查 Nacos 是否已安装
if [ -d "$NACOS_HOME" ] && [ -f "$NACOS_HOME/bin/startup.sh" ]; then
    echo "⚠️  Nacos 已安装在 $NACOS_HOME"

    # 检查服务状态
    if systemctl is-active --quiet nacos 2>/dev/null; then
        echo "Nacos 服务正在运行"
        echo "跳过 Nacos 安装步骤"
        exit 0
    else
        echo "Nacos 已安装但服务未运行，将重新配置..."
    fi
else
    echo "未检测到 Nacos，开始安装..."
fi

# 创建 nacos 用户和组
echo "正在创建 nacos 用户..."
if ! getent group $NACOS_GROUP >/dev/null 2>&1; then
    sudo groupadd $NACOS_GROUP
fi

if ! getent passwd $NACOS_USER >/dev/null 2>&1; then
    sudo useradd -r -g $NACOS_GROUP -s /bin/bash -d $NACOS_HOME $NACOS_USER
fi

# 创建必要的目录
echo "正在创建目录结构..."
sudo mkdir -p $NACOS_HOME

# 解压 Nacos
echo "正在解压 Nacos..."
TEMP_DIR="/tmp/nacos-install"
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR
cd $TEMP_DIR

tar -xzf "$NACOS_PACKAGE"

# 移动到目标目录
echo "正在安装 Nacos..."
sudo mv nacos/* $NACOS_HOME/

# 配置 Nacos 身份验证
echo "正在配置 Nacos 身份验证..."

# 备份原配置文件
if [ -f "$NACOS_HOME/conf/application.properties" ]; then
    sudo cp $NACOS_HOME/conf/application.properties $NACOS_HOME/conf/application.properties.backup.$(date +%Y%m%d_%H%M%S)
    echo "已备份原配置文件"
fi

# 定义需要配置的参数
AUTH_CONFIGS=(
    "nacos.core.auth.enabled=true"
    "nacos.core.auth.plugin.nacos.token.secret.key=7gaiNU8EuQXPr19PJ9GTdmswJY87/+NPAdbQcFnnwqY="
    "nacos.core.auth.server.identity.key=serverIdentity"
    "nacos.core.auth.server.identity.value=BjuvQanL2DQGiARYBgatOsjpAupAGzgIDowjqlSgRis="
)

# 函数：更新或添加配置项
update_config() {
    local config_line="$1"
    local config_key=$(echo "$config_line" | cut -d'=' -f1)
    local config_file="$NACOS_HOME/conf/application.properties"
    
    if sudo grep -q "^${config_key}=" "$config_file" 2>/dev/null; then
        # 如果配置项存在，则更新
        sudo sed -i "s|^${config_key}=.*|${config_line}|" "$config_file"
        echo "  已更新配置: $config_key"
    elif sudo grep -q "^#${config_key}=" "$config_file" 2>/dev/null; then
        # 如果配置项被注释，则取消注释并更新
        sudo sed -i "s|^#${config_key}=.*|${config_line}|" "$config_file"
        echo "  已启用配置: $config_key"
    else
        # 如果配置项不存在，则添加到文件末尾
        echo "$config_line" | sudo tee -a "$config_file" >/dev/null
        echo "  已添加配置: $config_key"
    fi
}

# 确保配置文件存在
if [ ! -f "$NACOS_HOME/conf/application.properties" ]; then
    sudo touch "$NACOS_HOME/conf/application.properties"
    echo "# Nacos Configuration" | sudo tee "$NACOS_HOME/conf/application.properties" >/dev/null
fi

# 应用所有身份验证配置
echo "正在应用身份验证配置..."
for config in "${AUTH_CONFIGS[@]}"; do
    update_config "$config"
done

# 创建基本目录结构
sudo mkdir -p $NACOS_HOME/data

# 创建 systemd 服务文件
echo "正在创建 systemd 服务..."
sudo tee /etc/systemd/system/nacos.service >/dev/null <<EOF
[Unit]
Description=Nacos Server
Documentation=https://nacos.io/docs/v2.5/quickstart/quick-start/
After=network.target

[Service]
Type=forking
User=$NACOS_USER
Group=$NACOS_GROUP
Environment=JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
WorkingDirectory=$NACOS_HOME
ExecStart=$NACOS_HOME/bin/startup.sh -m standalone
ExecStop=$NACOS_HOME/bin/shutdown.sh
Restart=on-failure
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 设置文件权限
sudo chown -R $NACOS_USER:$NACOS_GROUP $NACOS_HOME
sudo chmod -R 755 $NACOS_HOME

# 配置 NACOS_HOME 环境变量
echo "正在配置 NACOS_HOME 环境变量..."
if ! grep -q "NACOS_HOME" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Nacos 环境配置" >> ~/.bashrc
    echo "export NACOS_HOME=$NACOS_HOME" >> ~/.bashrc
    echo 'export PATH=$NACOS_HOME/bin:$PATH' >> ~/.bashrc
    echo ".bashrc 中已添加 NACOS_HOME 配置"
else
    echo ".bashrc 中已存在 NACOS_HOME 配置，跳过配置"
fi

# 启动服务
echo "正在启动 Nacos 服务..."
sudo systemctl daemon-reload
sudo systemctl enable nacos

# 启动前等待一下，确保 Java 环境准备就绪
sleep 2
sudo systemctl start nacos

# 清理临时文件
cd /
rm -rf $TEMP_DIR

# 等待服务启动
echo "等待 Nacos 服务启动..."
sleep 10

# 验证安装
echo "正在验证安装..."
if sudo systemctl is-active --quiet nacos; then
    echo "Nacos 安装验证成功！"

    # 检查端口是否监听
    if netstat -tlnp 2>/dev/null | grep -q ":8848 "; then
        echo "Nacos Web 端口 8848 已正常监听"
    else
        echo "警告: Nacos Web 端口 8848 未检测到监听，服务可能还在启动中"
        echo "请等待 1-2 分钟后检查: netstat -tlnp | grep 8848"
    fi
else
    echo "警告: Nacos 安装验证失败，请检查配置"
    echo "查看日志: sudo journalctl -u nacos -f"
fi

echo ""
echo "✅ Nacos 安装配置完成！"
echo ""
echo "服务信息:"
echo "  • 安装目录: $NACOS_HOME"
echo "  • 环境变量: NACOS_HOME 已配置到 ~/.bashrc"
echo "  • Web 端口: 8848 (默认)"
echo "  • gRPC 端口: 9848 (默认)"
echo "  • 运行模式: 单机模式 (默认)"
echo "  • 配置文件: $NACOS_HOME/conf/application.properties"
echo "  • 日志目录: $NACOS_HOME/logs (默认)"
echo "  • 数据目录: $NACOS_HOME/data (默认)"
echo ""
echo "常用命令："
echo "  查看服务状态: sudo systemctl status nacos"
echo "  启动服务: sudo systemctl start nacos"
echo "  停止服务: sudo systemctl stop nacos"
echo "  重启服务: sudo systemctl restart nacos"
echo "  查看日志: sudo journalctl -u nacos -f"
echo "  查看应用日志: tail -f $NACOS_HOME/logs/nacos.log"
echo "  编辑配置: sudo nano $NACOS_HOME/conf/application.properties"
echo "  手动启动: $NACOS_HOME/bin/startup.sh -m standalone"
echo "  手动停止: $NACOS_HOME/bin/shutdown.sh"
echo ""
echo "Web 控制台："
echo "  访问地址: http://localhost:8848/nacos"
echo "  登录方式: 已启用身份验证"
echo "  用户名: nacos"
echo "  密码: 首次访问时需要设置管理员密码"
echo "  ⚠️  建议密码: bzGHm@fqN_h7"
echo ""
echo "⚠️  注意事项："
echo "  • 首次启动可能需要 1-2 分钟，请耐心等待"
echo "  • 已启用身份验证，适合生产环境使用"
echo "  • 必须修改默认密码以提高安全性"
echo "  • NACOS_HOME 环境变量已配置，重新登录或执行 'source ~/.bashrc' 生效"
echo "  • 如需自定义配置，请修改 $NACOS_HOME/conf/application.properties"
echo "  • 如需使用外部 MySQL 数据库，请修改配置文件中的数据库配置"
echo "  • 如需集群模式，请修改配置文件中的集群相关设置"
echo ""
echo "🔐 身份验证配置："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "当前配置: 已启用身份验证 (nacos.core.auth.enabled=true)"
echo "用户名: nacos"
echo "密码设置: 首次访问时需要设置管理员密码"
echo ""
echo "🔑 密码设置步骤："
echo "1. 访问控制台: http://localhost:8848/nacos"
echo "2. 首次访问时会提示设置管理员密码"
echo "3. 用户名使用: nacos"
echo "4. 建议设置密码为: bzGHm@fqN_h7"
echo "5. 确认密码并完成初始化"
echo "6. 使用设置的用户名密码登录管理控制台"
echo ""
echo "如需禁用身份验证："
echo "1. 编辑配置文件: sudo nano $NACOS_HOME/conf/application.properties"
echo "2. 修改配置项: nacos.core.auth.enabled=false"
echo "3. 重启服务: sudo systemctl restart nacos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
