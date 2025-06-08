#!/bin/bash

# Ubuntu 安装 Nginx 脚本
# 作者: YXC
# 日期: $(date +%Y-%m-%d)

set -e # 遇到错误立即退出

echo "开始安装 Nginx..."

# 基本配置
NGINX_USER="nginx"
NGINX_GROUP="nginx"

# 固定安装目录到 /usr/local
NGINX_HOME="/usr/local/nginx/conf"
NGINX_PREFIX="/usr/local/nginx"

echo "Nginx 安装目录: $NGINX_PREFIX"
echo "Nginx 配置目录: $NGINX_HOME"

# 获取脚本所在目录的父目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 自动检测 Nginx 版本（从文件名读取）
NGINX_PACKAGE=$(find "$PROJECT_DIR/packages" -name "nginx-*.tar.gz" | head -1)
if [ -z "$NGINX_PACKAGE" ]; then
    echo "错误: 在 $PROJECT_DIR/packages 目录下未找到 nginx-*.tar.gz 文件"
    exit 1
fi

# 从文件名提取版本号
NGINX_VERSION=$(basename "$NGINX_PACKAGE" | sed 's/nginx-\(.*\)\.tar\.gz/\1/')
echo "检测到 Nginx 版本: $NGINX_VERSION"

# 检查 Nginx 是否已安装
if command -v nginx &>/dev/null; then
    INSTALLED_VERSION=$(nginx -v 2>&1 | sed 's/nginx version: nginx\///')
    echo "⚠️  Nginx 已安装，版本: $INSTALLED_VERSION"

    # 检查服务状态
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo "Nginx 服务正在运行"
        echo "如需重新安装，请先停止服务: sudo systemctl stop nginx"
        exit 0
    else
        echo "Nginx 已安装但服务未运行，将重新配置..."
    fi
else
    echo "未检测到 Nginx，开始安装..."
fi

# 安装依赖包
echo "正在安装编译依赖..."
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    zlib1g-dev \
    libpcre3-dev \
    libssl-dev \
    libgd-dev \
    libxml2-dev \
    libxslt1-dev \
    libgeoip-dev \
    libgoogle-perftools-dev \
    libperl-dev \
    libluajit-5.1-dev

# 确保 nginx 用户存在
echo "正在检查 nginx 用户..."
if ! getent group $NGINX_GROUP >/dev/null 2>&1; then
    sudo groupadd $NGINX_GROUP
fi

if ! getent passwd $NGINX_USER >/dev/null 2>&1; then
    sudo useradd -r -g $NGINX_GROUP -s /bin/false -d $NGINX_PREFIX $NGINX_USER
fi

# 创建必要的目录
echo "正在创建目录结构..."
sudo mkdir -p $NGINX_PREFIX/cache

# 解压 Nginx 源码
echo "正在解压 Nginx 源码..."
TEMP_DIR="/tmp/nginx-install"
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR
cd $TEMP_DIR

tar -xzf "$NGINX_PACKAGE"
cd nginx-$NGINX_VERSION

# 配置编译选项
echo "正在配置编译选项..."
./configure \
    --prefix=$NGINX_PREFIX \
    --user=$NGINX_USER \
    --group=$NGINX_GROUP \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_perl_module=dynamic \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_geoip_module=dynamic \
    --with-file-aio

# 编译安装
echo "正在编译 Nginx..."
make -j$(nproc)

echo "正在安装 Nginx..."
sudo make install

# 创建软链接到系统PATH
echo "正在创建系统链接..."
sudo ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/nginx

# 配置 Nginx (使用默认配置)
echo "正在配置 Nginx..."
echo "使用默认配置文件，如需自定义请编辑 $NGINX_HOME/nginx.conf"

# 创建 systemd 服务文件
echo "正在创建 systemd 服务..."
sudo tee /etc/systemd/system/nginx.service >/dev/null <<EOF
[Unit]
Description=The nginx HTTP and reverse proxy server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=$NGINX_PREFIX/logs/nginx.pid
ExecStartPre=$NGINX_PREFIX/sbin/nginx -t
ExecStart=$NGINX_PREFIX/sbin/nginx
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
TimeoutStopSec=5
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# 设置文件权限
echo "正在设置文件权限..."
sudo mkdir -p $NGINX_PREFIX/logs
sudo mkdir -p $NGINX_PREFIX/cache
sudo chown -R $NGINX_USER:$NGINX_GROUP $NGINX_PREFIX
sudo chmod -R 755 $NGINX_PREFIX

# 配置 NGINX_HOME 环境变量
echo "正在配置 NGINX_HOME 环境变量..."
if ! grep -q "NGINX_HOME" ~/.bashrc; then
    echo "" >>~/.bashrc
    echo "# Nginx 环境配置" >>~/.bashrc
    echo "export NGINX_HOME=$NGINX_HOME" >>~/.bashrc
    echo "export NGINX_PREFIX=$NGINX_PREFIX" >>~/.bashrc
    echo 'export PATH=$NGINX_PREFIX/sbin:$PATH' >>~/.bashrc
    echo ".bashrc 中已添加 NGINX_HOME 配置"
else
    echo ".bashrc 中已存在 NGINX_HOME 配置，跳过配置"
fi

# 测试配置文件
echo "正在测试 Nginx 配置..."
sudo $NGINX_PREFIX/sbin/nginx -t

# 启动服务
echo "正在启动 Nginx 服务..."
sudo systemctl daemon-reload
sudo systemctl enable nginx
sudo systemctl start nginx

# 清理临时文件
cd /
rm -rf $TEMP_DIR

# 等待服务启动
echo "等待 Nginx 服务启动..."
sleep 3

# 验证安装
echo "正在验证安装..."
if sudo systemctl is-active --quiet nginx; then
    echo "Nginx 安装验证成功！"

    # 检查端口是否监听
    if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
        echo "Nginx HTTP 端口 80 已正常监听"
    else
        echo "警告: Nginx HTTP 端口 80 未检测到监听，请检查配置"
    fi
else
    echo "警告: Nginx 安装验证失败，请检查配置"
    echo "查看日志: sudo journalctl -u nginx -f"
fi

echo ""
echo "✅ Nginx 安装配置完成！"
echo ""
echo "服务信息:"
echo "  • 版本: $NGINX_VERSION"
echo "  • 安装目录: $NGINX_PREFIX"
echo "  • 配置目录: $NGINX_HOME"
echo "  • 日志目录: $NGINX_PREFIX/logs"
echo "  • 网站根目录: $NGINX_PREFIX/html (默认)"
echo "  • HTTP 端口: 80 (默认)"
echo "  • 运行用户: $NGINX_USER"
echo ""
echo "常用命令："
echo "  查看服务状态: sudo systemctl status nginx"
echo "  启动服务: sudo systemctl start nginx"
echo "  停止服务: sudo systemctl stop nginx"
echo "  重启服务: sudo systemctl restart nginx"
echo "  重载配置: sudo systemctl reload nginx"
echo "  测试配置: sudo nginx -t"
echo "  查看日志: sudo journalctl -u nginx -f"
echo "  查看错误日志: sudo tail -f $NGINX_PREFIX/logs/error.log"
echo "  查看访问日志: sudo tail -f $NGINX_PREFIX/logs/access.log"
echo "  编辑主配置: sudo nano $NGINX_HOME/nginx.conf"
echo "  查看默认页面目录: ls -la $NGINX_PREFIX/html"
echo ""
echo "Web 服务："
echo "  访问地址: http://localhost"
echo "  使用默认nginx配置和页面"
echo ""
echo "配置文件结构："
echo "  主配置文件: $NGINX_HOME/nginx.conf"
echo "  MIME 类型文件: $NGINX_HOME/mime.types"
echo "  使用nginx源码包默认配置结构"
echo ""
echo "⚠️  注意事项："
echo "  • 已启用 HTTP/2、SSL/TLS、状态统计、流媒体代理等核心模块"
echo "  • 已启用扩展模块: 图像处理、XML/XSLT、地理位置、Perl"
echo "  • 使用nginx默认路径配置，简化安装过程"
echo "  • NGINX_HOME 环境变量已配置，重新登录或执行 'source ~/.bashrc' 生效"
echo "  • 如需配置 HTTPS，请添加 SSL 证书配置"
echo "  • 如需配置反向代理，请修改主配置文件"
echo "  • 使用nginx默认配置结构，请参考nginx官方文档"
echo ""
echo "📁 目录权限:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "网站目录: $NGINX_PREFIX/html (属主: $NGINX_USER:$NGINX_GROUP)"
echo "日志目录: $NGINX_PREFIX/logs (属主: $NGINX_USER:$NGINX_GROUP)"
echo "缓存目录: $NGINX_PREFIX/cache (属主: $NGINX_USER:$NGINX_GROUP)"
echo "配置目录: $NGINX_HOME (属主: root:root)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
