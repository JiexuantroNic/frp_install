#!/bin/bash

# FRP 自动安装脚本 (适配 TOML 配置文件版本)
# 功能：自动下载最新版 frp，安装并配置为 systemd 服务
# 特点：显示下载进度条，增强错误处理

set -e

# 配置部分
FRP_VERSION=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
INSTALL_DIR="/usr/local/frp"
BIN_DIR="/usr/local/frp"
SERVICE_DIR="/etc/systemd/system"
CONFIG_DIR="${INSTALL_DIR}/conf"

# 检查 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 用户运行此脚本！"
    exit 1
fi

# 检查并安装必要工具
if ! command -v wget &> /dev/null; then
    echo "正在安装 wget..."
    apt-get update && apt-get install -y wget || yum install -y wget
fi

# 创建必要的目录
mkdir -p ${INSTALL_DIR} ${CONFIG_DIR} /usr/local/bin
cd ${INSTALL_DIR}

# 获取系统架构
ARCH=$(uname -m)
case ${ARCH} in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    armv7l)
        ARCH="arm"
        ;;
    *)
        echo "不支持的架构: ${ARCH}"
        exit 1
        ;;
esac

# 下载并解压 frp
echo "正在下载 frp ${FRP_VERSION} (${ARCH})..."
DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/${FRP_VERSION}/frp_${FRP_VERSION/v/}_linux_${ARCH}.tar.gz"
echo "下载地址: ${DOWNLOAD_URL}"
wget --no-verbose --show-progress --progress=bar:force:noscroll -O frp.tar.gz "${DOWNLOAD_URL}"

echo "正在解压 frp..."
tar -xzf frp.tar.gz

# 动态获取解压后的目录名
EXTRACTED_DIR=$(tar -tf frp.tar.gz | head -1 | cut -f1 -d"/")
if [ -z "${EXTRACTED_DIR}" ]; then
    echo "错误：无法确定解压后的目录名"
    exit 1
fi

cd "${EXTRACTED_DIR}"

# 复制文件到安装目录
echo "正在安装 frp..."
cp -v frpc ${BIN_DIR}/
cp -v frps ${BIN_DIR}/
cp -v *.toml ${CONFIG_DIR}/

# 创建 systemd 服务文件
echo "正在配置 systemd 服务..."

# frps 服务文件
cat > ${SERVICE_DIR}/frps.service <<EOF
[Unit]
Description=Frp Server Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=${BIN_DIR}/frps -c ${CONFIG_DIR}/frps.toml
ExecReload=${BIN_DIR}/frps reload -c ${CONFIG_DIR}/frps.toml
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

# frpc 服务文件
cat > ${SERVICE_DIR}/frpc.service <<EOF
[Unit]
Description=Frp Client Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=${BIN_DIR}/frpc -c ${CONFIG_DIR}/frpc.toml
ExecReload=${BIN_DIR}/frpc reload -c ${CONFIG_DIR}/frpc.toml
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

# 设置权限
chmod +x ${BIN_DIR}/frpc ${BIN_DIR}/frps
chmod 644 ${CONFIG_DIR}/*.toml
chmod 644 ${SERVICE_DIR}/frpc.service ${SERVICE_DIR}/frps.service

# 创建符号链接到 /usr/local/bin 以便全局访问
echo "正在创建符号链接..."
ln -sf ${BIN_DIR}/frpc /usr/local/bin/frpc || echo "警告：创建 frpc 符号链接失败"
ln -sf ${BIN_DIR}/frps /usr/local/bin/frps || echo "警告：创建 frps 符号链接失败"

# 重载 systemd
echo "正在重载 systemd..."
systemctl daemon-reload

# 清理安装包
echo "正在清理安装文件..."
rm -rf "${EXTRACTED_DIR}" frp.tar.gz

# 完成提示
echo -e "\n\033[32mfrp ${FRP_VERSION} 安装完成！\033[0m"
echo ""
echo "已安装到: ${INSTALL_DIR}"
echo "二进制文件: ${BIN_DIR}/"
echo "配置文件: ${CONFIG_DIR}/"
echo ""
echo "使用说明:"
echo "1. 编辑配置文件: ${CONFIG_DIR}/frps.toml 或 frpc.toml"
echo "2. 启动服务:"
echo "   - 服务端: systemctl start frps"
echo "   - 客户端: systemctl start frpc"
echo "3. 设置开机启动:"
echo "   - 服务端: systemctl enable frps"
echo "   - 客户端: systemctl enable frpc"
echo ""
echo "请根据您的需求修改配置文件后启动服务。"
