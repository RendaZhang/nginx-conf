<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Nginx Configuration for rendazhang.com](#nginx-configuration-for-rendazhangcom)
  - [简介](#%E7%AE%80%E4%BB%8B)
  - [🚀 服务器环境信息示例](#-%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%8E%AF%E5%A2%83%E4%BF%A1%E6%81%AF%E7%A4%BA%E4%BE%8B)
    - [**后端服务**](#%E5%90%8E%E7%AB%AF%E6%9C%8D%E5%8A%A1)
    - [**前端项目**:](#%E5%89%8D%E7%AB%AF%E9%A1%B9%E7%9B%AE)
  - [📁 项目配置文件说明](#-%E9%A1%B9%E7%9B%AE%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%E8%AF%B4%E6%98%8E)
  - [🧭 关键配置功能 (`nginx.conf`)](#-%E5%85%B3%E9%94%AE%E9%85%8D%E7%BD%AE%E5%8A%9F%E8%83%BD-nginxconf)
  - [🔧 Nginx 配置](#-nginx-%E9%85%8D%E7%BD%AE)
  - [Nginx 缓存检查](#nginx-%E7%BC%93%E5%AD%98%E6%A3%80%E6%9F%A5)
  - [🔒 证书更新](#-%E8%AF%81%E4%B9%A6%E6%9B%B4%E6%96%B0)
  - [🛠️ 故障排查](#-%E6%95%85%E9%9A%9C%E6%8E%92%E6%9F%A5)
  - [📎 相关资源](#-%E7%9B%B8%E5%85%B3%E8%B5%84%E6%BA%90)
  - [🤝 Contributing Guide](#-contributing-guide)
  - [🔐 License](#-license)
  - [📬 联系方式](#-%E8%81%94%E7%B3%BB%E6%96%B9%E5%BC%8F)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Nginx Configuration for rendazhang.com

* **Last Updated:** July 13, 2025, 21:30 (UTC+8)
* **作者:** 张人大（Renda Zhang）

---

## 简介

本仓库存储了 **轻量级** 网站的 Nginx 服务器配置，主要面向小内存服务器。这些配置文件针对生产环境优化，支持 HTTPS、反向代理和安全防护措施，并具备较强的通用性，可在多种操作系统上使用。当前示例以 **Ubuntu 24.04 LTS** 为主，关于旧版 CentOS 7 的迁移细节请参阅 [迁移指南](docs/MIGRATION_GUIDE.md)。

> 重量级解决方案可参考我的云原生项目：[Renda Cloud LAB](https://github.com/RendaZhang/renda-cloud-lab)

---

## 🚀 服务器环境信息示例

- **服务器位置**: 香港
- **操作系统（示例）**: Ubuntu 24.04 LTS
- **服务器配置**:
  - 2 vCPUs
  - 1 GB RAM
  - 40 GB SSD
- **Web 服务器**: Nginx + Gunicorn(Gevent)
- **参考架构**：Web (Frontend (HTML + CSS + Bootstrap + JavaScript)) → Server (Ubuntu → Nginx → systemd → Gunicorn + Gevent → Backend (Flask APP))

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

> ⚠ **注意**: 证书文件 (`cert/`, `ssl/`) 和日志文件 (`logs/`) 等敏感 / 临时文件已通过 `.gitignore` 排除

---

## 🧭 关键配置功能 (`nginx.conf`)

- **HTTP → HTTPS 重定向**:
  - 所有 HTTP 请求 (端口 80) 自动重定向到 HTTPS (端口 443)
- **SSL 设置**:
  - 由 Certbot 自动管理
  - 证书: `/etc/letsencrypt/live/$DomainName/fullchain.pem`
  - 私钥: `/etc/letsencrypt/live/$DomainName/privkey.pem`
- **网站根目录**: `/var/www/$StaticFrontendPagesFolder`
- **反向代理**:
  - `/cloudchat/` 路径代理到 `http://$BackendIP:$Port/`
  - `proxy_buffering off` 等设置以支持流式传输（注意：关闭后 `proxy_cache` 将失效）
  - `proxy_read_timeout` 设置需要跟 Gunicorn 的 `timeout` 设置对齐
  - 仅当 `Referer` 头以 `https://$DomainName` 开头时才生效
- **安全措施**:
  - 阻止访问 `.git`, `.gitignore`, `package.json` 等敏感文件
- **自定义错误页面**:
  - `404.html`, `50x.html`
- [目录与用户约定](https://github.com/RendaZhang/nginx-conf/blob/master/docs/MIGRATION_GUIDE.md#%E7%9B%AE%E5%BD%95%E4%B8%8E%E7%94%A8%E6%88%B7%E7%BA%A6%E5%AE%9A)

---

## 🔧 Nginx 配置

具体步骤可以参考文档内容：[安装和配置 Nginx](https://github.com/RendaZhang/nginx-conf/blob/master/docs/MIGRATION_GUIDE.md#%E5%AE%89%E8%A3%85%E5%92%8C%E9%85%8D%E7%BD%AE-nginx)

---

## Nginx 缓存检查

具体步骤可以参考文档内容：[Nginx 缓存](https://github.com/RendaZhang/nginx-conf/blob/master/docs/MIGRATION_GUIDE.md#nginx-%E7%BC%93%E5%AD%98)

---


## 🔒 证书更新

证书需定期手动更新（建议使用 Certbot 自动化）：

具体步骤可以参考文档内容：[SSL 证书](https://github.com/RendaZhang/nginx-conf/blob/master/docs/MIGRATION_GUIDE.md#ssl-%E8%AF%81%E4%B9%A6)

---

## 🛠️ 故障排查

> **重要提示**: 每次修改配置后，请运行 `nginx -t` 验证配置有效性后再重启服务

具体步骤可以参考文档内容：[检查 Nginx](https://github.com/RendaZhang/nginx-conf/blob/master/docs/MIGRATION_GUIDE.md#%E6%A3%80%E6%9F%A5-nginx)

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
