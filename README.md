# Ubuntu 开发环境初始化脚本

🚀 一键式配置 Ubuntu 开发环境的自动化脚本，快速搭建完整的开发环境。

## 📋 项目简介

该项目提供了一套完整的 Ubuntu 开发环境自动化配置脚本，可以快速安装和配置常用的开发工具和服务。特别适合在新的 Ubuntu 服务器或开发机器上快速搭建开发环境。

## 🔧 支持的环境

- **Ubuntu 24.04 LTS** (完全支持)
- **Ubuntu 22.04 LTS** (完全支持)
- 其他 Ubuntu 版本 (部分支持，可能需要手动调整)

## 📦 安装的组件

### 开发工具
- **NVM** (Node Version Manager) - Node.js 版本管理工具
- **Node.js 18 LTS** - JavaScript 运行环境
- **OpenJDK 8** (默认) - Java 开发环境
- **OpenJDK 11** - Java 开发环境

### 数据库
- **MySQL 8.0** - 关系型数据库

### 容器化
- **Docker CE** - 容器化平台
- **Docker Compose** - 容器编排工具

### 服务组件
- **Nacos 2.5.1** - 服务注册发现和配置管理 (端口: 8848)
- **Nginx 1.27.5** - Web 服务器和反向代理 (端口: 80/443)
- **MinIO** - 对象存储服务 (API端口: 9000, 控制台端口: 9001)

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone <repository-url>
cd ubuntu-initialization-script
```

### 2. 运行安装脚本
```bash
chmod +x install.sh
./install.sh
```

### 3. 加载环境变量
```bash
source ~/.bashrc
```

## 📁 项目结构

```
ubuntu-initialization-script/
├── install.sh              # 主安装脚本
├── scripts/                # 各组件安装脚本
│   ├── nvm.sh             # NVM 安装脚本
│   ├── nodejs.sh          # Node.js 安装脚本
│   ├── java.sh            # Java 环境安装脚本
│   ├── mysql.sh           # MySQL 安装脚本
│   ├── docker.sh          # Docker 安装脚本
│   ├── nacos.sh           # Nacos 安装脚本
│   ├── nginx.sh           # Nginx 安装脚本
│   └── minio.sh           # MinIO 安装脚本
└── packages/              # 安装包存储目录
    ├── nacos-server-2.5.1.tar.gz
    ├── nginx-1.27.5.tar.gz
    ├── nvm-0.40.3.tar.gz
    ├── minio_*.deb
    ├── docker-ce_*.deb
    ├── docker-ce-cli_*.deb
    ├── docker-compose-plugin_*.deb
    ├── docker-buildx-plugin_*.deb
    └── containerd.io_*.deb
```

## 📝 安装流程

安装脚本将按照以下顺序执行：

1. **系统兼容性检查** - 验证 Ubuntu 版本
2. **NVM 安装** - 安装 Node 版本管理工具
3. **Node.js 安装** - 安装 Node.js 18 LTS 版本
4. **Java 环境安装** - 安装 OpenJDK 8 和 11
5. **MySQL 安装** - 安装和配置 MySQL 8.0
6. **Docker 安装** - 安装 Docker CE 和相关工具
7. **Nacos 安装** - 部署 Nacos 服务注册中心
8. **Nginx 安装** - 编译安装 Nginx Web 服务器
9. **MinIO 安装** - 部署 MinIO 对象存储服务

## ⚙️ 配置说明

### MySQL 配置
- 默认 root 密码会在安装过程中设置
- 服务端口: 3306

### Nacos 配置
- 运行模式: 单机模式
- 访问端口: 8848
- 默认用户名/密码: nacos/nacos

### Nginx 配置
- HTTP 端口: 80
- HTTPS 端口: 443
- 配置文件位置: `/usr/local/nginx/conf/nginx.conf`

### Docker 配置
- 自动启动 Docker 服务
- 包含 Docker Compose 插件
- 包含 Docker Buildx 插件

### MinIO 配置
- API 端口: 9000
- Web 控制台端口: 9001
- 默认用户名/密码: admin/yUzEBme.ta-7
- 数据目录: /var/lib/minio/data

## 🔍 验证安装

安装完成后，可以通过以下命令验证各组件是否正常工作：

```bash
# 验证 Node.js
node --version
npm --version

# 验证 Java
java -version

# 验证 MySQL
sudo systemctl status mysql

# 验证 Docker
docker --version
docker-compose --version

# 验证 Nginx
sudo /usr/local/nginx/sbin/nginx -t

# 访问 Nacos (在浏览器中打开)
# http://your-server-ip:8848/nacos

# 访问 MinIO 控制台 (在浏览器中打开)
# http://your-server-ip:9001
```

## 🛠️ 故障排除

### 权限问题
如果遇到权限错误，请确保以sudo权限运行脚本：
```bash
sudo ./install.sh
```

### 网络问题
如果下载失败，请检查网络连接或更换软件源。

### 服务启动问题
可以使用 systemd 命令检查和管理服务状态：
```bash
sudo systemctl status mysql
sudo systemctl status docker
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

## 📄 许可证

该项目采用 MIT 许可证，详情请查看 LICENSE 文件。

## 👨‍💻 作者

**YXC** - *项目创建者和维护者*

---

⭐ 如果这个项目对你有帮助，请给它一个星标！ 