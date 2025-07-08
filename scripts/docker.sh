#!/bin/bash

# Ubuntu 离线安装 Docker 脚本
# 作者: YXC
# 日期: $(date +%Y-%m-%d)
# 说明: 使用预下载的 deb 包离线安装 Docker
# 依赖: 需要 packages 目录中包含所有必需的 Docker deb 包

set -e # 遇到错误立即退出

echo "开始离线安装 Docker..."

# 检查 Docker 是否已安装
if command -v docker &>/dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null)
    echo "⚠️  Docker 已安装: $DOCKER_VERSION"

    # 检查服务状态
    if systemctl is-active --quiet docker; then
        echo "Docker 服务正在运行"

        # 检查 Docker Compose 是否可用
        if docker compose version &>/dev/null; then
            echo "Docker Compose 插件已安装"
            echo "跳过 Docker 安装步骤"
            exit 0
        else
            echo "Docker Compose 插件未安装，继续安装..."
        fi
    else
        echo "Docker 已安装但服务未运行，将重新配置..."
    fi
elif dpkg -l | grep -q "docker-ce"; then
    echo "⚠️  检测到 Docker CE 包已安装"
    echo "跳过 Docker 安装步骤"
    exit 0
else
    echo "未检测到 Docker，开始安装..."
fi

# 删除可能存在的旧版本 Docker 包
echo "正在删除可能存在的旧版本 Docker 包..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    if dpkg -l | grep -q "^ii.*$pkg "; then
        echo "正在删除旧包: $pkg"
        sudo apt-get remove -y $pkg
    else
        echo "未发现包: $pkg"
    fi
done
echo "✅ 旧版本清理完成"

# 安装和配置 Docker

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/../packages"

# 检查 packages 目录是否存在
if [ ! -d "$PACKAGES_DIR" ]; then
    echo "❌ 错误: packages 目录不存在: $PACKAGES_DIR"
    echo "请确保 packages 目录存在并包含所需的 Docker deb 包"
    exit 1
fi

# 检查必需的 deb 包是否存在
echo "正在检查 Docker 安装包..."
REQUIRED_PACKAGES=(
    "containerd.io"
    "docker-ce_"
    "docker-ce-cli"
    "docker-buildx-plugin"
    "docker-compose-plugin"
)

missing_packages=()
for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! ls "$PACKAGES_DIR"/${package}*.deb >/dev/null 2>&1; then
        missing_packages+=("$package")
    fi
done

if [ ${#missing_packages[@]} -ne 0 ]; then
    echo "❌ 错误: 以下必需的 deb 包未找到:"
    for pkg in "${missing_packages[@]}"; do
        echo "  - ${pkg}*.deb"
    done
    echo ""
    echo "请确保 packages 目录包含以下文件:"
    echo "  - containerd.io_<version>_<arch>.deb"
    echo "  - docker-ce_<version>_<arch>.deb"
    echo "  - docker-ce-cli_<version>_<arch>.deb"
    echo "  - docker-buildx-plugin_<version>_<arch>.deb"
    echo "  - docker-compose-plugin_<version>_<arch>.deb"
    exit 1
fi

echo "✅ 所有必需的 Docker 安装包已找到"

# 使用 dpkg 安装 Docker deb 包
echo "正在从 deb 包安装 Docker..."
cd "$PACKAGES_DIR"

# 按顺序安装包，确保依赖关系正确
sudo dpkg -i containerd.io*.deb
sudo dpkg -i docker-ce-cli*.deb
sudo dpkg -i docker-ce_*.deb
sudo dpkg -i docker-buildx-plugin*.deb
sudo dpkg -i docker-compose-plugin*.deb

# 修复可能的依赖问题
echo "正在修复依赖关系..."
sudo apt-get install -f -y

echo "✅ Docker 安装包安装完成"

# 启动 Docker 服务
echo "正在启动 Docker 服务..."
sudo systemctl start docker
sudo systemctl enable docker

# 检查 Docker 服务状态
echo "检查 Docker 服务状态..."
sudo systemctl status docker --no-pager || true

# 将当前用户添加到 docker 组（允许非 root 用户使用 Docker）
echo "正在配置用户权限..."
sudo usermod -aG docker $USER

# 配置 Docker 镜像加速
echo "正在配置 Docker 镜像加速..."
sudo mkdir -p /etc/docker

# 创建 CDI 目录以避免警告
echo "正在创建 CDI 目录..."
sudo mkdir -p /etc/cdi
sudo mkdir -p /var/run/cdi

cat >/tmp/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF

sudo mv /tmp/daemon.json /etc/docker/daemon.json

# 重启 Docker 服务以应用配置
echo "正在重启 Docker 服务..."
sudo systemctl restart docker

# 验证安装
echo "正在验证 Docker 安装..."
if sudo docker run --rm hello-world >/dev/null 2>&1; then
    echo "Docker 安装验证成功！"
else
    echo "警告: Docker 安装验证失败，请检查安装"
fi

echo ""
echo "✅ Docker 安装配置完成！"
echo ""
echo "Docker 服务状态:"
sudo systemctl is-active docker || echo "Docker 服务未运行"

echo ""
echo "Docker 版本信息:"
docker --version 2>/dev/null || echo "Docker 版本信息获取失败"
docker-compose --version 2>/dev/null || echo "Docker Compose 版本信息获取失败"

echo ""
echo "默认配置信息："
echo "  • 安装方式: 使用 deb 包离线安装"
echo "  • Docker 服务: 已启动并设置开机自启"
echo "  • 用户权限: 当前用户已添加到 docker 组"
echo "  • 镜像加速器: 已配置腾讯云、中科大、网易镜像源"
echo ""
echo "常用命令："
echo "  查看服务状态: sudo systemctl status docker"
echo "  启动服务: sudo systemctl start docker"
echo "  停止服务: sudo systemctl stop docker"
echo "  重启服务: sudo systemctl restart docker"
echo "  运行容器: docker run hello-world"
echo "  查看镜像: docker images"
echo "  查看容器: docker ps -a"
echo ""
echo "⚠️  重要提醒："
echo "  • 需要重新登录或重启终端才能使用 docker 命令（无需 sudo）"
echo "  • 或者运行: newgrp docker"
echo ""
echo "📦 packages 目录要求："
echo "  • containerd.io_<version>_<arch>.deb"
echo "  • docker-ce_<version>_<arch>.deb"
echo "  • docker-ce-cli_<version>_<arch>.deb"
echo "  • docker-buildx-plugin_<version>_<arch>.deb"
echo "  • docker-compose-plugin_<version>_<arch>.deb"
echo "  • 可从 https://download.docker.com/linux/ubuntu/dists/ 下载"
echo ""
