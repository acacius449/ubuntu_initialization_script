#!/bin/bash

# Ubuntu 安装 OpenJDK 脚本
# 作者: YXC
# 日期: $(date +%Y-%m-%d)

set -e # 遇到错误立即退出

echo "开始安装 OpenJDK 8 和 OpenJDK 11..."

# 检查 Java 是否已安装
JAVA8_INSTALLED=false
JAVA11_INSTALLED=false

if command -v java &>/dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -1)
    echo "⚠️  检测到已安装的 Java: $JAVA_VERSION"
fi

# 检查 OpenJDK 8 是否已安装
if dpkg -l | grep -q "openjdk-8-jdk"; then
    echo "⚠️  OpenJDK 8 已安装"
    JAVA8_INSTALLED=true
fi

# 检查 OpenJDK 11 是否已安装
if dpkg -l | grep -q "openjdk-11-jdk"; then
    echo "⚠️  OpenJDK 11 已安装"
    JAVA11_INSTALLED=true
fi

# 如果都已安装，跳过安装步骤
if [ "$JAVA8_INSTALLED" = true ] && [ "$JAVA11_INSTALLED" = true ]; then
    echo "OpenJDK 8 和 OpenJDK 11 都已安装，跳过安装步骤"
    echo "当前 Java 版本: $(java -version 2>&1 | head -1)"
    exit 0
fi

if [ "$JAVA8_INSTALLED" = false ]; then
    echo "未检测到 OpenJDK 8，将进行安装..."
fi

if [ "$JAVA11_INSTALLED" = false ]; then
    echo "未检测到 OpenJDK 11，将进行安装..."
fi

# 安装和配置 Java 环境

# 更新软件包列表
echo ""
echo "正在更新软件包列表..."
echo ""
sudo apt update -q

# 安装 OpenJDK 8 和 OpenJDK 11
if [ "$JAVA8_INSTALLED" = false ]; then
    echo ""
    echo "正在安装 OpenJDK 8..."
    echo ""
    sudo apt install -q -y openjdk-8-jdk
else
    echo "跳过 OpenJDK 8 安装（已安装）"
fi

if [ "$JAVA11_INSTALLED" = false ]; then
    echo ""
    echo "正在安装 OpenJDK 11..."
    echo ""
    sudo apt install -q -y openjdk-11-jdk
else
    echo ""
    echo "跳过 OpenJDK 11 安装（已安装）"
    echo ""
fi

# 自动设置 Java 8 为默认版本
echo ""
echo "正在设置 Java 8 为默认版本..."
echo ""
JAVA8_PATH=$(update-alternatives --list java 2>/dev/null | grep java-8 | head -1)
JAVAC8_PATH=$(update-alternatives --list javac 2>/dev/null | grep java-8 | head -1)

if [ -n "$JAVA8_PATH" ] && [ -n "$JAVAC8_PATH" ]; then
    sudo update-alternatives --set java "$JAVA8_PATH"
    sudo update-alternatives --set javac "$JAVAC8_PATH"
    echo "✅ Java 8 已自动设置为默认版本"
else
    echo "⚠️  未找到 Java 8 路径，请手动配置"
fi

echo ""
echo "✅ Java 环境安装配置完成！"
echo "Java 版本: $(java -version 2>&1 | head -1)"
echo "Javac 版本: $(javac -version 2>&1)"
echo ""
echo "📋 Java 版本切换操作指南："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Java 8 已自动设置为默认版本"
echo ""
echo "如需切换到其他版本，请执行以下步骤："
echo ""
echo "1. 输入以下命令："
echo "   sudo update-alternatives --config java"
echo ""
echo "2. 返回目前所有可用 Java 版本列表："
echo "  Selection    Path                                            Priority   Status"
echo "------------------------------------------------------------------------------------------"
echo "  * 0          /usr/lib/jvm/java-11-openjdk-amd64/bin/java     1111       auto mode"
echo "    1          /usr/lib/jvm/java-11-openjdk-amd64/bin/java     1111       manual mode"
echo "    2          /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java  1081       manual mode"
echo ""
echo "3. 输入要切换的版本序号，例如要切换到 java-8，则输入：2"
echo ""
echo "4. 验证切换结果："
echo ""
echo "   java -version && javac -version"
echo ""
echo "💡 提示：切换后需要重新打开终端或执行 'source ~/.bashrc' 使环境变量生效"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
