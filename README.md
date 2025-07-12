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
    - [缓存规则说明](#%E7%BC%93%E5%AD%98%E8%A7%84%E5%88%99%E8%AF%B4%E6%98%8E)
    - [手动清理缓存](#%E6%89%8B%E5%8A%A8%E6%B8%85%E7%90%86%E7%BC%93%E5%AD%98)
  - [🧭 关键配置功能 (`nginx.conf`)](#-%E5%85%B3%E9%94%AE%E9%85%8D%E7%BD%AE%E5%8A%9F%E8%83%BD-nginxconf)
  - [🔒 证书更新指南](#-%E8%AF%81%E4%B9%A6%E6%9B%B4%E6%96%B0%E6%8C%87%E5%8D%97)
  - [🛠️ 故障排查](#-%E6%95%85%E9%9A%9C%E6%8E%92%E6%9F%A5)
  - [📎 相关资源](#-%E7%9B%B8%E5%85%B3%E8%B5%84%E6%BA%90)
  - [🤝 Contributing Guide](#-contributing-guide)
  - [🔐 License](#-license)
  - [📬 联系方式](#-%E8%81%94%E7%B3%BB%E6%96%B9%E5%BC%8F)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Nginx Configuration for rendazhang.com

* **Last Updated:** July 9, 2025, 18:35 (UTC+8)
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

1. 由于配置中 `proxy_cache_min_uses 2`，同一请求需要在第二次访问后才会被写入
   缓存，因此请连续发送 **三次** 完全相同的请求：缓存会在第二次请求后创建，并在
   第三次请求时从缓存中返回。
   - 若只想发送两次请求即可观察到 `HIT`，可将 `proxy_cache_min_uses` 暂时改为 `1`。
2. 或者查看响应头：
   ```bash
   curl -I https://YOUR_DOMAIN/cloudchat/test
   ```
   当看到 `X-Cache-Status: HIT` 表示缓存生效，`MISS` 则说明尚未命中。

### 缓存规则说明

- 缓存键由 `proxy_cache_key "$scheme$request_method$host$request_uri$is_args$args"` 拼接而成：
  - `$scheme`：协议
  - `$request_method`：HTTP 方法
  - `$host`：主机名
  - `$request_uri`：路径
  - `$is_args$args`：查询字符串

  示例：`httpsGETexample.com/index.html?foo=1`。

- 动态缓存目录：`/var/cache/nginx`，`proxy_cache_path` 设置 `inactive=60m`、`max_size=100m`，匹配 `/cloudchat/` 接口并通过 `proxy_cache_valid 200 302 10m` 和 `404 1m` 控制缓存时间。
- 静态缓存目录：`/tmp/nginx`（备用），当前配置主要使用 `expires 30d` 控制本地静态资源缓存。
- 缓存文件在指定 `inactive` 时间内未被访问会自动清理，目录超过 `max_size` 时也会淘汰旧文件。
- **动态缓存**：配置在 `/var/cache/nginx`，`proxy_cache_valid 200 302 10m`，`404` 缓存 1 分钟；若 60 分钟未再次访问会被自动清理。
- **静态缓存**：目录 `/tmp/nginx`，适用于代理到其他源的静态资源，30 天未访问即失效。

### 手动清理缓存

1. SSH 登录到部署 Nginx 的服务器上。
2. 执行 `curl -X PURGE http://localhost/cloudchat/purge-cache/<cache_key>`，其中 `<cache_key>` 为完整缓存键（如 `httpsHEADwww.rendazhang.com/cloudchat/test`）。
3. 如果需要远程调用，可在 `location ~ /cloudchat/purge-cache/(.*)` 中增加 `allow <你的IP>;` 或配置 Basic Auth，再重新加载 Nginx。
4. 使用 `curl -I https://www.rendazhang.com/cloudchat/test -H "Referer: https://www.rendazhang.com"` 检查缓存是否 HIT 或 MISS。
5. 通过 `tail -f /usr/local/nginx/logs/error.log` 查看日志，并确认 `/var/cache/nginx` 目录中的文件已被清除。
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
  - `proxy_buffering off` 等设置以支持流式传输（注意：关闭后 `proxy_cache` 将失效）
  - `proxy_read_timeout` 设置需要跟 Gunicorn 的 `timeout` 设置对齐
  - 仅当 `Referer` 头以 `https://$DomainName` 开头时才生效
  - 通过 `curl -X PURGE http://localhost/cloudchat/purge-cache/<cache_key>` 手动清除缓存，其中 `<cache_key>` 为完整的缓存键（示例：`httpsGETexample.com/index.html`）
- **安全措施**:
  - 阻止访问 `.git`, `.gitignore`, `package.json` 等敏感文件
- **自定义错误页面**:
  - `404.html`, `50x.html`

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

- 迁移指南：[Migration Guide](docs/MIGRATION_GUIDE.md)
- 针对小内存服务器的优化和增强建议：[Small Server Optimizations Guide](docs/SMALL_SERVER_OPTIMIZATIONS.md)
- 网站: [www.rendazhang.com](https://www.rendazhang.com)
- 前端仓库：[Renda Zhang Web Project](https://github.com/RendaZhang/rendazhang.github.io)
- 后端仓库：[Python Cloud Chat Project](https://github.com/RendaZhang/python-cloud-chat)
- 重量级解决方案：[renda-cloud-lab Project](https://github.com/RendaZhang/renda-cloud-lab)

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
