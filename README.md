# FRP 一键安装脚本

一个全自动安装配置 [FRP](https://github.com/fatedier/frp) 的Bash脚本，支持最新TOML配置格式。

## ✨ 核心功能

**✅ 全自动安装**  
- 自动从GitHub获取最新FRP版本  
- 支持 `amd64`/`arm64`/`armv7` 架构  

**✅ 开箱即用**  
- 自动生成systemd服务文件  
- 配置文件存放于 `/usr/local/frp/conf/`  
- 二进制文件软链接到 `/usr/local/bin/`  

**✅ 安全可靠**  
- 自动检查root权限  
- 以`nobody`用户运行服务  
- 完善的错误处理机制  

## 🚀 快速开始

### 基本安装
```bash
# 下载脚本（需root权限）
wget https://raw.githubusercontent.com/JiexuantroNic/frp_install/main/frp_install.sh
chmod +x frp_install.sh
./frp_install.sh
```

## 📂 文件结构
/usr/local/frp/

├── frpc

├── frps

└── conf/

    ├── frpc.toml
    
    └── frps.toml

## ⚙️ 服务管理
```bash
#启动
systemctl start frps
#停止
systemctl stop frps
#状态
systemctl status frps
```
## 🔧 配置修改
```bash
nano /usr/local/frp/conf/frps.toml
systemctl restart frps
```

## ❓ 常见问题
**如何卸载？**
```bash
systemctl stop frps frpc
rm -rf /usr/local/frp/
rm /etc/systemd/system/frps.service
systemctl daemon-reload
```
**支持Windows吗？**
**不支持** 仅限linux系统

## 📜 ​​协议​​：MIT © [JiexuantroNic](https://github.com/JiexuantroNic)
