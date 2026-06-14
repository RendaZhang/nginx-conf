<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [项目需求清单](#%E9%A1%B9%E7%9B%AE%E9%9C%80%E6%B1%82%E6%B8%85%E5%8D%95)
  - [简介](#%E7%AE%80%E4%BB%8B)
  - [🚀 核心功能](#-%E6%A0%B8%E5%BF%83%E5%8A%9F%E8%83%BD)
  - [🔧 技术需求](#-%E6%8A%80%E6%9C%AF%E9%9C%80%E6%B1%82)
  - [2026-06-12 线上巡检问题记录](#2026-06-12-%E7%BA%BF%E4%B8%8A%E5%B7%A1%E6%A3%80%E9%97%AE%E9%A2%98%E8%AE%B0%E5%BD%95)
    - [本次已修复](#%E6%9C%AC%E6%AC%A1%E5%B7%B2%E4%BF%AE%E5%A4%8D)
    - [后续加固](#%E5%90%8E%E7%BB%AD%E5%8A%A0%E5%9B%BA)
  - [🌱 未来计划](#-%E6%9C%AA%E6%9D%A5%E8%AE%A1%E5%88%92)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 项目需求清单

- **作者**: 张人大 (Renda Zhang)
- **最后更新**: June 14, 2026, 17:52 (UTC+08:00)

---

## 简介

该仓库维护 www.rendazhang.com 网站在轻量级服务器上的 Nginx 配置。

配置文件已在 Ubuntu 24.04 LTS 环境验证，兼顾 HTTPS、安全防护与缓存优化，适合 1GB 内存服务器部署。

---

## 🚀 核心功能

- 自动 HTTPS：使用 Certbot 管理证书，HTTP 请求全部重定向到 canonical HTTPS 主机 `https://www.rendazhang.com`
- 反向代理：将 `/cloudchat/` 流量转发到后端 Gunicorn + Flask 服务
- 动态缓存：`cloudchat_cache` 缓存区，支持缓存清理端点 `PURGE`
- 流式接口：SSE/WebSocket 接口关闭 `proxy_buffering`，支持实时响应
- 限流控制：`limit_req_zone` 配置每个客户端 5 r/s
- 安全头：通过 `snippets/security-headers.conf` 集中开启 `HSTS` 与单行版 `CSP`，并在会覆盖 `add_header` 继承的 location 中显式引入
- 安全：启用 Fail2Ban 自动封禁异常请求，并维护 `ip-blacklist.conf` 黑名单
- 静态文件缓存：常见静态资源设置 `expires 30d`
- 指纹目录 `/_astro/` 通过 `location ^~ /_astro/` 缓存 365 天，利用文件哈希（包含 PDF 等静态资源）实现长期有效缓存
- 自定义错误页：提供 404 与 50x 页面

---

## 🔧 技术需求

- [x] 配置动态模块 `ngx_cache_purge` 并通过自动化脚本保证版本兼容
- [x] 支持在 Ubuntu 24.04 系统下运行，兼容 CentOS 7 迁移流程
- [x] 通过 pre-commit 自动执行 `doctoc` 更新文档目录
- [x] 修复 ECDSA 证书下 TLS 1.2 握手失败：TLS 1.2 cipher 同时覆盖 `ECDHE-ECDSA-*` 与 `ECDHE-RSA-*`
- [x] 修复静态页面、XML/JSON 与静态资源缺少安全头：所有自定义 `add_header` 的 location 显式引入安全头 snippet
- [x] 修复 `/_astro/` 长缓存未命中：使用 `^~` 提升指纹目录 location 优先级
- [x] 修复 `/.env`、`/.env.local` 等隐藏敏感探测路径回退首页 200：隐藏文件默认 404，保留 `/.well-known/`
- [x] 修复 apex 域名直接 200：`https://rendazhang.com/*` 统一 301 到 `https://www.rendazhang.com/*`
- [x] 明确 `ip-blacklist.conf` 为服务器本地运行态配置：从 Git 索引移除并加入 `.gitignore`，避免 Git 发布覆盖黑名单
- [x] 修复 Astro hydration inline scripts 被 CSP 拦截：`script-src` 使用当前生产构建 SHA-256 hash allowlist，不启用 `unsafe-inline`
- [x] 修复首页 Chat Widget iframe 被 CSP 拦截：`frame-src` 显式允许 `'self'`，同时继续保留 Credly iframe 来源
- [ ] 集成压力测试场景（如 `siege -c 50`）到 CI 流程
- [ ] 文档内提供 Docker 化部署示例

---

## 2026-06-12 线上巡检问题记录

### 本次已修复

- [x] **TLS 1.2 配置与实际不一致**：证书为 ECDSA，但旧 `ssl_ciphers` 只覆盖 RSA TLS 1.2 套件，导致 TLS 1.2 握手失败；已抽取 `snippets/ssl-rendazhang.conf` 并补齐 ECDSA/RSA TLS 1.2 cipher。
- [x] **静态页面/资源缺少安全头**：Nginx `add_header` 在 location 内声明后不会继承 server 级安全头；已抽取 `snippets/security-headers.conf` 并在 HTML/XML/JSON、`/_astro/`、通用静态资源和隐藏路径拦截 location 中显式引入。
- [x] **`/_astro/` 长缓存未按预期生效**：普通 `location /_astro/` 被通用静态资源正则 location 抢先匹配；已改为 `location ^~ /_astro/` 并设置一年 immutable 缓存。
- [x] **敏感探测路径返回首页 200**：`/.env`、`/.env.local` 等隐藏路径被 SPA fallback 命中；已增加隐藏文件 404 规则，同时保留 `/.well-known/`。
- [x] **apex 域名未规范化**：`https://rendazhang.com/` 直接 200；已增加 apex HTTPS server，统一 301 到 www canonical host。
- [x] **`ip-blacklist.conf` 被 Git 跟踪且服务器存在大量本地变更**：黑名单属于服务器本地运行态配置；已改为 Git ignore，并要求 Nginx 配置发布走 commit/push + 服务器 `git pull --ff-only`。
- [x] **Astro hydration inline scripts 被 CSP 拦截**：首页、`/deepseek_chat/`、`/login/`、`/docs/` 的 Astro inline runtime hash 已加入 `script-src`，保持不使用 `unsafe-inline`。
- [x] **Chat Widget iframe 被 CSP 拦截**：首页右下角聊天浮标通过同源 iframe 加载 `/deepseek_chat/`；已在 `frame-src` 中加入 `'self'`，保留 `https://www.credly.com`。

### 后续加固

- [ ] SSH 当前允许 `PermitRootLogin yes` 与 `PasswordAuthentication yes`，需创建非 root 管理用户并切换为密钥登录。
- [ ] `cloudchat.service` 当前以 root 运行且 Gunicorn 绑定 `0.0.0.0:5000`，需迁移到低权限用户并绑定 `127.0.0.1:5000`。
- [ ] 主机防火墙 `ufw` 当前 inactive，虽云安全组阻断了部分公网端口，仍需在主机层限制非必要端口。
- [ ] 前端升级 Astro 或 GitHub Actions 重新构建后，需复核 inline script hash 是否变化；中长期可评估 Astro 6 `security.csp` 原生配置。
- [ ] 定期巡检证书有效期、`certbot.timer`、安全头覆盖、`/_astro/` 长缓存、敏感路径 404 和 `/cloudchat/auth/healthz`。

---

## 🌱 未来计划

- 新增自动化健康检查脚本，定期验证证书和缓存状态
- 引入更细粒度的访问日志分析工具
