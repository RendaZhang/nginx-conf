<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Nginx Configuration for rendazhang.com](#nginx-configuration-for-rendazhangcom)
  - [简介](#%E7%AE%80%E4%BB%8B)
  - [🚀 服务器环境信息示例](#-%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%8E%AF%E5%A2%83%E4%BF%A1%E6%81%AF%E7%A4%BA%E4%BE%8B)
    - [**后端服务**](#%E5%90%8E%E7%AB%AF%E6%9C%8D%E5%8A%A1)
    - [**前端项目**:](#%E5%89%8D%E7%AB%AF%E9%A1%B9%E7%9B%AE)
  - [📁 项目配置文件说明](#-%E9%A1%B9%E7%9B%AE%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%E8%AF%B4%E6%98%8E)
  - [🔧 Nginx 编译与安装](#-nginx-%E7%BC%96%E8%AF%91%E4%B8%8E%E5%AE%89%E8%A3%85)
    - [编译步骤](#%E7%BC%96%E8%AF%91%E6%AD%A5%E9%AA%A4)
    - [启用缓存目录](#%E5%90%AF%E7%94%A8%E7%BC%93%E5%AD%98%E7%9B%AE%E5%BD%95)
    - [检查缓存是否生效](#%E6%A3%80%E6%9F%A5%E7%BC%93%E5%AD%98%E6%98%AF%E5%90%A6%E7%94%9F%E6%95%88)
  - [🧭 关键配置功能 (`nginx.conf`)](#-%E5%85%B3%E9%94%AE%E9%85%8D%E7%BD%AE%E5%8A%9F%E8%83%BD-nginxconf)
  - [🚚 迁移指南](#-%E8%BF%81%E7%A7%BB%E6%8C%87%E5%8D%97)
    - [示例服务器](#%E7%A4%BA%E4%BE%8B%E6%9C%8D%E5%8A%A1%E5%99%A8)
    - [迁移步骤](#%E8%BF%81%E7%A7%BB%E6%AD%A5%E9%AA%A4)
    - [验证迁移](#%E9%AA%8C%E8%AF%81%E8%BF%81%E7%A7%BB)
  - [🔒 证书更新指南](#-%E8%AF%81%E4%B9%A6%E6%9B%B4%E6%96%B0%E6%8C%87%E5%8D%97)
  - [针对小内存服务器的优化和增强建议](#%E9%92%88%E5%AF%B9%E5%B0%8F%E5%86%85%E5%AD%98%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%9A%84%E4%BC%98%E5%8C%96%E5%92%8C%E5%A2%9E%E5%BC%BA%E5%BB%BA%E8%AE%AE)
    - [速率限制:](#%E9%80%9F%E7%8E%87%E9%99%90%E5%88%B6)
    - [使用轻量级 WSGI 服务器](#%E4%BD%BF%E7%94%A8%E8%BD%BB%E9%87%8F%E7%BA%A7-wsgi-%E6%9C%8D%E5%8A%A1%E5%99%A8)
    - [后端服务相关的调整建议](#%E5%90%8E%E7%AB%AF%E6%9C%8D%E5%8A%A1%E7%9B%B8%E5%85%B3%E7%9A%84%E8%B0%83%E6%95%B4%E5%BB%BA%E8%AE%AE)
    - [防火墙增强:](#%E9%98%B2%E7%81%AB%E5%A2%99%E5%A2%9E%E5%BC%BA)
    - [日志监控:](#%E6%97%A5%E5%BF%97%E7%9B%91%E6%8E%A7)
      - [简单的轻量级监控工具](#%E7%AE%80%E5%8D%95%E7%9A%84%E8%BD%BB%E9%87%8F%E7%BA%A7%E7%9B%91%E6%8E%A7%E5%B7%A5%E5%85%B7)
      - [功能全面的轻量级监控工具](#%E5%8A%9F%E8%83%BD%E5%85%A8%E9%9D%A2%E7%9A%84%E8%BD%BB%E9%87%8F%E7%BA%A7%E7%9B%91%E6%8E%A7%E5%B7%A5%E5%85%B7)
    - [设置交换空间（如果尚未设置）](#%E8%AE%BE%E7%BD%AE%E4%BA%A4%E6%8D%A2%E7%A9%BA%E9%97%B4%E5%A6%82%E6%9E%9C%E5%B0%9A%E6%9C%AA%E8%AE%BE%E7%BD%AE)
  - [🛠️ 故障排查](#-%E6%95%85%E9%9A%9C%E6%8E%92%E6%9F%A5)
  - [📎 相关资源](#-%E7%9B%B8%E5%85%B3%E8%B5%84%E6%BA%90)
  - [🤝 Contributing Guide](#-contributing-guide)
  - [🔐 License](#-license)
  - [📬 联系方式](#-%E8%81%94%E7%B3%BB%E6%96%B9%E5%BC%8F)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Nginx Configuration for rendazhang.com

* **Last Updated:** July 8, 2025, 21:50 (UTC+8)
* **作者:** 张人大（Renda Zhang）

---

## 简介

本仓库存储了 **轻量级** 网站的 Nginx 服务器配置，主要面向小内存服务器。这些配置文件针对生产环境优化，支持 HTTPS、反向代理和安全防护措施，并具备较强的通用性，可在多种操作系统上使用。文档中的示例以 CentOS 7 为主，你可以按需调整以适配其他系统。

> 重量级解决方案可参考我的云原生项目：[Renda Cloud LAB](https://github.com/RendaZhang/renda-cloud-lab)

---

## 🚀 服务器环境信息示例

- **服务器位置**: 香港
- **操作系统（示例）**: CentOS 7（可根据需要调整至其他系统）
- **服务器配置**:
  - 2 vCPUs
  - 1 GB RAM
  - 40 GB SSD
- **Web 服务器**: Nginx + Gunicorn(Gevent)
- **参考架构**：Web (Frontend (HTML + CSS + Bootstrap + JavaScript)) → Server (CentOS 7 → Nginx → systemd → Gunicorn + Gevent → Backend (Flask APP))

### **后端服务**

- Python Flask 部署在 Gunicorn + Gevent 上
- 具体情况和部署操作请参考后端项目：[Python Cloud Chat](https://github.com/RendaZhang/python-cloud-chat)

### **前端项目**:

- 原生 HTML, CSS, Bootstrap, JavaScript
- 具体操作和网站功能描述请参考前端项目：[Renda Zhang Web](https://github.com/RendaZhang/rendazhang.github.io)

---

## 📁 项目配置文件说明

| 文件 | 作用 |
|------|------|
| `nginx.conf` | 主配置文件 |
| `fastcgi.conf` | FastCGI 相关配置 |
| `fastcgi_params` | FastCGI 参数设置 |
| `scgi_params` | SCGI 协议参数 |
| `uwsgi_params` | uWSGI 协议参数 |
| `mime.types` | MIME 类型映射 |

> ⚠ **注意**: 证书文件(`cert/`, `ssl/`)和日志文件(`logs/`)等敏感/临时文件已通过 `.gitignore` 排除

---

## 🔧 Nginx 编译与安装

下面示例展示了如何编译与部署适用于本仓库配置的 Nginx **1.24.0**。编译参数需与下列输出一致：

```bash
nginx -V
# --prefix=/usr/local/nginx \
# --with-http_stub_status_module \
# --with-http_ssl_module \
# --with-http_gzip_static_module \
# --with-http_v2_module \
# --add-module=../ngx_cache_purge
```

### 编译步骤

```bash
# 安装依赖
sudo yum install -y gcc make pcre-devel zlib-devel openssl-devel git

# 下载源码
wget http://nginx.org/download/nginx-1.24.0.tar.gz
tar zxvf nginx-1.24.0.tar.gz
cd nginx-1.24.0

# 获取 ngx_cache_purge 模块
git clone https://github.com/FRiCKLE/ngx_cache_purge.git ../ngx_cache_purge

# 配置并编译
./configure \
  --prefix=/usr/local/nginx \
  --with-http_stub_status_module \
  --with-http_ssl_module \
  --with-http_gzip_static_module \
  --with-http_v2_module \
  --add-module=../ngx_cache_purge
make
sudo make install
```

### 启用缓存目录

```bash
id nginx || sudo useradd -r -s /sbin/nologin nginx

sudo mkdir -p /var/cache/nginx
sudo chown -R nginx:nginx /usr/local/nginx
sudo chown -R nginx:nginx /var/cache/nginx
sudo chmod -R 700 /var/cache/nginx
```

### 检查缓存是否生效

1. 重启 Nginx 后访问动态页面两次，`/var/cache/nginx` 下应生成缓存文件。
2. 或者查看响应头：
   ```bash
   curl -I https://YOUR_DOMAIN/cloudchat/test
   ```
   出现 `X-Cache-Status: HIT` 或 `MISS` 表示缓存已启用。

---

## 🧭 关键配置功能 (`nginx.conf`)

- **HTTP → HTTPS 重定向**:
  - 所有 HTTP 请求 (端口 80) 自动重定向到 HTTPS (端口 443)
- **SSL 设置**:
  - 证书: `cert/$DomainName.pem`
  - 私钥: `cert/$DomainName.key`
  - 支持 `TLSv1.2` 和 `TLSv1.3`
- **网站根目录**: `/usr/local/nginx/$StaticFrontendPagesFolder`
- **反向代理**:
  - `/cloudchat/` 路径代理到 `http://$BackendIP:$Port/`
  - `proxy_buffering off` 等设置以支持流式传输
  - `proxy_read_timeout` 设置需要跟 Gunicorn 的 `timeout` 设置对齐
  - 仅当 `Referer` 头以 `https://$DomainName` 开头时才生效
- **安全措施**:
  - 阻止访问 `.git`, `.gitignore`, `package.json` 等敏感文件
- **自定义错误页面**:
  - `404.html`, `50x.html`

---

## 🚚 迁移指南

### 示例服务器

1. **操作系统**:

- CentOS 7

2. **Nginx 版本**:

- 1.22+

3. **依赖组件**:

- Python 3.11+
- Flask 框架
- Gunicorn
- Gevent
- 开放的端口: 80 (HTTP), 443 (HTTPS)

4. **资源规格**:

- 最低: 1 vCPU, 1GB RAM, 20GB 存储
- 推荐: 2 vCPU, 2GB RAM, 40GB 存储

### 迁移步骤

```bash
# 1. 克隆配置仓库
git clone git@gitee.com:yourname/nginx-conf.git

# 2. 复制配置文件 (保留文件权限)
sudo cp -p nginx-conf/* /usr/local/nginx/conf/

# 3. 安装证书 (手动操作，不上传至 Git)

# 将证书文件放入 /usr/local/nginx/conf/cert/

# 确保文件名与配置中一致:
#   - rendazhang.com.pem
#   - rendazhang.com.key

# 4. 部署静态网站
git clone git@gitee.com:yourname/rendazhang.git /usr/local/nginx/RendaZhang

# 5. 部署 Flask 后端 (Gunicorn + Gevent)

# 假设 Flask 应用部署在 /opt/cloudchat
sudo /opt/cloudchat/venv/bin/pip install gunicorn gevent

# 使用 systemd 管理服务:
sudo tee /etc/systemd/system/cloudchat.service > /dev/null <<EOF
[Unit]
Description=CloudChat Flask App with Gunicorn
After=network.target

[Service]
User=root
WorkingDirectory=/opt/cloudchat
Environment="PATH=/opt/cloudchat/venv/bin"
ExecStart=/opt/cloudchat/venv/bin/gunicorn --worker-class gevent --workers 2 --worker-connections 50 --max-requests 1000 --max-requests-jitter 50 --timeout 300 --bind 0.0.0.0:5000 app:app
Restart=always
RestartSec=3
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
sudo systemctl daemon-reload
sudo systemctl start cloudchat.service
sudo systemctl enable cloudchat.service

# 6. 测试并重启 Nginx
sudo nginx -t  # 验证配置
sudo systemctl restart nginx

# 7. 快速检查内存使用
free -h
```

### 验证迁移

1. 访问 `http://服务器IP` 应自动跳转至 `https://服务器IP`

2. 检查各功能页面:

- 主页面: `/index.html`
- 聊天功能: `/chat.html`

3. 验证后端服务:

```bash
curl -X POST https://DOMAIN_NAME/cloudchat/chat \
      -H "Content-Type: application/json" \
      -H "Referer: https://DOMAIN_NAME" \
      -d '{"message": "Hello from curl!"}'
```

---

## 🔒 证书更新指南

证书需定期手动更新（建议使用 Certbot 自动化）：

```bash
# 安装 Certbot
sudo yum install epel-release
sudo yum install certbot python2-certbot-nginx

# 申请证书 (首次)
sudo certbot --nginx -d rendazhang.com -d www.rendazhang.com

# 设置自动续期 (每月检查)
sudo crontab -e
# 添加以下内容:
0 0 1 * * /usr/bin/certbot renew --quiet
```

---

## 针对小内存服务器的优化和增强建议

### 速率限制:

```nginx
# 在 nginx.conf 的 http 块添加
limit_req_zone $binary_remote_addr zone=flask_limit:10m rate=5r/s;

# 在 location /cloudchat/ 添加
limit_req zone=flask_limit burst=10 nodelay;
```

### 使用轻量级 WSGI 服务器

- 使用 Gunicorn + Gevent 作为 WSGI 服务器

部署示例：
```bash
pip install gunicorn
gunicorn -w 2 -k gevent your_app:app
```

### 后端服务相关的调整建议

- 限制对话历史长度
- 定期清理旧会话

具体可以参考 Python 后端项目的文档：[轻量级会话存储方案（针对小内存服务器）](https://github.com/RendaZhang/python-cloud-chat/blob/master/docs/lightweight_backend_development.md#%E8%BD%BB%E9%87%8F%E7%BA%A7%E4%BC%9A%E8%AF%9D%E5%AD%98%E5%82%A8%E6%96%B9%E6%A1%88%E9%92%88%E5%AF%B9%E5%B0%8F%E5%86%85%E5%AD%98%E6%9C%8D%E5%8A%A1%E5%99%A8)

### 防火墙增强:

```bash
# 安装 firewalld
sudo yum install firewalld
sudo systemctl start firewalld

# 开放必要端口
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 日志监控:

#### 简单的轻量级监控工具

安装 htop 步骤：

```bash
# Enable the EPEL repository:
sudo yum install epel-release
# Install htop:
sudo yum install htop
# Run htop:
htop
```

使用 htop 简单地定期去手动检查内存使用情况。

#### 功能全面的轻量级监控工具

安装 glances 步骤：

```bash
# Enable the EPEL repository (if not already enabled):
sudo yum install epel-release
# Install glances:
sudo yum install glances
# Run glances:
glances
```

使用 glances 可以实现 Web-based 界面的远程监控，支持提醒功能和插件扩展。

### 设置交换空间（如果尚未设置）

```bash
# Creates a 1GB file named /swapfile using fallocate:
sudo fallocate -l 1G /swapfile

# Set Permissions: only the root user can read and write to the swap file.
sudo chmod 600 /swapfile

# Initializes the file as swap space:
sudo mkswap /swapfile

# Activates the swap file
sudo swapon /swapfile

# Make the Swap File Permanent
# Open /etc/fstab for editing:
sudo vi /etc/fstab
# Add the following line at the end of the file:
/swapfile swap swap defaults 0 0
# Save and exit the editor.

# Verify the Swap Space
# Check if the swap space is active using:
sudo swapon --show
# View the total memory and swap space with:
free -h

# Adjusting Swapiness
# Check the current swappiness value (Default is 60):
cat /proc/sys/vm/swappiness
# Set a lower swappiness value for better performance on small-memory servers:
sudo sysctl vm.swappiness=10
# Make the change permanent by adding the following line to /etc/sysctl.conf:
vm.swappiness=10
```

---

## 🛠️ 故障排查

> **重要提示**: 每次修改配置后，请运行 `nginx -t` 验证配置有效性后再重启服务

```bash
# 检查 Nginx 错误
tail -f /usr/local/nginx/logs/error.log

# 检查 Flask 日志
journalctl -u cloudchat.service -f

# 测试 SSL 配置
openssl s_client -connect www.rendazhang.com:443 -servername www.rendazhang.com
```

---

## 📎 相关资源

- 网站: [www.rendazhang.com](https://www.rendazhang.com)
- 前端仓库：[Renda Zhang Web](https://github.com/RendaZhang/rendazhang.github.io)
- 后端仓库：[Python Cloud Chat](https://github.com/RendaZhang/python-cloud-chat)
- Flask 文档: [flask.palletsprojects.com](https://flask.palletsprojects.com/)
- 重量级解决方案：[renda-cloud-lab](https://github.com/RendaZhang/renda-cloud-lab)

---

## 🤝 Contributing Guide

- Fork & clone this repo.
- Install dependencies and **pre-commit**:
```bash
pip install pre-commit
pre-commit install
```
- Before every commit, hooks will run automatically. You can trigger them manually with:
```bash
pre-commit run --all-files
```

> ✅ All commits must pass pre-commit checks; CI will block non-conforming PRs.

---

## 🔐 License

本项目采用 **MIT 协议** 开源发布。这意味着你可以自由地使用、修改并重新发布本仓库的内容，只需在分发时附上原始许可证声明。

---

## 📬 联系方式

* 联系人：张人大（Renda Zhang）
* 邮箱：[952402967@qq.com](mailto:952402967@qq.com)
* 个人网站：[https://rendazhang.com](https://rendazhang.com)

> ⏰ **Maintainer**：@Renda — 如果本项目对你有帮助，请不要忘了点亮 ⭐️ Star 支持我们！
