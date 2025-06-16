#!/bin/bash

# Ubuntu 安装 MySQL 8 脚本
# 作者: YXC
# 日期: $(date +%Y-%m-%d)

set -e # 遇到错误立即退出

# 加载环境变量
if [ -f ".env" ]; then
    echo "加载环境变量配置..."
    source .env
fi

# 检查必需的环境变量
if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_ADMIN_PASSWORD" ] || [ -z "$MYSQL_ADMIN_USER" ]; then
    echo "❌ 错误：缺少必需的环境变量"
    echo ""
    echo "请在项目根目录创建 .env 文件，包含以下内容："
    echo ""
    echo "MYSQL_ROOT_PASSWORD=你的 root 密码"
    echo "MYSQL_ADMIN_USER=你的管理员用户名"
    echo "MYSQL_ADMIN_PASSWORD=你的管理员密码"
    echo ""
    echo "注意：请使用强密码，包含大小写字母、数字和特殊字符"
    exit 1
fi

echo "✅ 环境变量检查通过"

echo "开始安装 MySQL 8..."

# 检查 MySQL 是否已安装
if command -v mysql &>/dev/null; then
    MYSQL_VERSION=$(mysql --version 2>/dev/null | head -1)
    echo "⚠️  MySQL 已安装: $MYSQL_VERSION"

    # 检查服务状态
    if systemctl is-active --quiet mysql; then
        echo "MySQL 服务正在运行"
        echo "跳过 MySQL 安装步骤"
        exit 0
    else
        echo "MySQL 已安装但服务未运行，将重新配置..."
    fi
elif dpkg -l | grep -q "mysql-server"; then
    echo "⚠️  检测到 MySQL Server 包已安装"
    echo "跳过 MySQL 安装步骤"
    exit 0
else
    echo "未检测到 MySQL，开始安装..."
fi

# 安装和配置 MySQL 8

# 更新软件包列表
echo "正在更新软件包列表..."
sudo apt update

# 安装 MySQL 8
echo "正在安装 MySQL Server 8.0..."

# 安装 MySQL 服务器
sudo apt install -y mysql-server

# 启动 MySQL 服务
echo "正在启动 MySQL 服务..."
sudo systemctl start mysql
sudo systemctl enable mysql

# 检查 MySQL 服务状态
echo "检查 MySQL 服务状态..."
sudo systemctl status mysql --no-pager || true

# 配置 MySQL 允许远程连接（可选）
echo "正在配置 MySQL 远程连接..."

# 备份原始配置文件
sudo cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.backup

# 修改绑定地址以允许远程连接
sudo sed -i 's/bind-address.*=.*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# 重启 MySQL 服务以应用配置更改
echo "正在重启 MySQL 服务..."
sudo systemctl restart mysql

# 显示安装结果
echo ""
echo "✅ MySQL 8 基础安装完成！"
echo ""
echo "MySQL 服务状态:"
sudo systemctl is-active mysql || echo "MySQL 服务未运行"

echo ""
echo "MySQL 版本信息:"
mysqld --version 2>/dev/null | head -1 || echo "MySQL Server 8.0 已安装"

echo ""
echo "📋 下一步操作："
echo "  1. 请按照下面的安全配置提示手动配置用户和权限"
echo "  2. 配置完成后，测试登录：mysql -u root -p"
echo "  3. 远程连接已启用，端口：3306"
echo ""
echo "常用命令："
echo "  查看服务状态: sudo systemctl status mysql"
echo "  启动服务: sudo systemctl start mysql"
echo "  停止服务: sudo systemctl stop mysql"
echo "  重启服务: sudo systemctl restart mysql"
echo ""
echo "⚠️  重要提醒："
echo "  • 必须先完成安全配置才能正常使用数据库！"
echo "  • 生产环境请修改默认密码！"
echo "  • 建议定期更新密码！"

# 安全配置提示
echo ""
echo "=========================================="
echo "🔧 手动安全配置指南"
echo "=========================================="
echo ""
echo "1. 首先使用以下命令开始 MySQL 安全配置："
echo ""
echo "   sudo mysql_secure_installation"
echo ""
echo "2. 然后根据系统提示依次进行以下设置："
echo ""
echo "   是否启用密码强度检查插件 -> Y"
echo "   设置密码强度级别 -> 2"
echo "   是否移除匿名用户 -> Y"
echo "   是否禁止 root 用户远程登录 -> Y"
echo "   是否删除测试数据库 -> Y"
echo "   是否刷新权限表 -> Y"
echo ""
echo "3. 修改密码，创建远程登录用户："
echo ""
echo "-- 使用 root 用户登录"
echo "   sudo mysql -u root -p"
echo "   Enter password: -> 此时密码为空，直接回车"
echo ""
echo "-- 设置 root 用户高强度密码"
echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';"
echo ""
echo "-- 创建一个用于远程访问的管理员用户（使用高强度密码）"
echo "CREATE USER '$MYSQL_ADMIN_USER'@'%' IDENTIFIED BY '$MYSQL_ADMIN_PASSWORD';"
echo "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_ADMIN_USER'@'%' WITH GRANT OPTION;"
echo ""
echo "-- 刷新权限"
echo "FLUSH PRIVILEGES;"
echo ""
echo "-- 退出 MySQL"
echo "EXIT;"
echo ""
echo "=========================================="
echo ""
echo "🔐 安全配置说明："
echo "  • Root 用户密码: $MYSQL_ROOT_PASSWORD (仅本地访问)"
echo "  • 管理员用户: $MYSQL_ADMIN_USER (密码：$MYSQL_ADMIN_PASSWORD，可远程访问)"
echo "  • 密码强度要求: 最少 12 位，至少 2 个大写 + 2 个小写 + 2 个数字 + 2 个特殊字符"
echo ""
