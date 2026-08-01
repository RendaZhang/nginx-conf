<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [NGINX Troubleshooting Guide](#nginx-troubleshooting-guide)
  - [简介](#%E7%AE%80%E4%BB%8B)
    - [涵盖问题类型](#%E6%B6%B5%E7%9B%96%E9%97%AE%E9%A2%98%E7%B1%BB%E5%9E%8B)
    - [核心价值](#%E6%A0%B8%E5%BF%83%E4%BB%B7%E5%80%BC)
    - [使用建议](#%E4%BD%BF%E7%94%A8%E5%BB%BA%E8%AE%AE)
    - [BUG 记录格式要求](#bug-%E8%AE%B0%E5%BD%95%E6%A0%BC%E5%BC%8F%E8%A6%81%E6%B1%82)
    - [问题状态](#%E9%97%AE%E9%A2%98%E7%8A%B6%E6%80%81)
  - [[2026-06-12] TLS 1.2 在 ECDSA 证书下握手失败](#2026-06-12-tls-12-%E5%9C%A8-ecdsa-%E8%AF%81%E4%B9%A6%E4%B8%8B%E6%8F%A1%E6%89%8B%E5%A4%B1%E8%B4%A5)
  - [[2026-06-12] 静态页面和资源缺少安全响应头](#2026-06-12-%E9%9D%99%E6%80%81%E9%A1%B5%E9%9D%A2%E5%92%8C%E8%B5%84%E6%BA%90%E7%BC%BA%E5%B0%91%E5%AE%89%E5%85%A8%E5%93%8D%E5%BA%94%E5%A4%B4)
  - [[2026-06-12] Astro hydration inline scripts 被 CSP 拦截](#2026-06-12-astro-hydration-inline-scripts-%E8%A2%AB-csp-%E6%8B%A6%E6%88%AA)
  - [[2026-06-14] Chat Widget iframe 被 CSP frame-src 拦截](#2026-06-14-chat-widget-iframe-%E8%A2%AB-csp-frame-src-%E6%8B%A6%E6%88%AA)
  - [[2026-06-12] `/_astro/` 长缓存被通用静态资源规则覆盖](#2026-06-12-_astro-%E9%95%BF%E7%BC%93%E5%AD%98%E8%A2%AB%E9%80%9A%E7%94%A8%E9%9D%99%E6%80%81%E8%B5%84%E6%BA%90%E8%A7%84%E5%88%99%E8%A6%86%E7%9B%96)
  - [[2026-06-12] 隐藏敏感路径回退首页且 apex 域名未规范化](#2026-06-12-%E9%9A%90%E8%97%8F%E6%95%8F%E6%84%9F%E8%B7%AF%E5%BE%84%E5%9B%9E%E9%80%80%E9%A6%96%E9%A1%B5%E4%B8%94-apex-%E5%9F%9F%E5%90%8D%E6%9C%AA%E8%A7%84%E8%8C%83%E5%8C%96)
  - [[2025-07-07] HTTP/2 `net::ERR_HTTP2_PROTOCOL_ERROR` on `/chat` & `favicon.ico`](#2025-07-07-http2-neterr_http2_protocol_error-on-chat--faviconico)
  - [[2025-07-09] 缓存文件未生成与 "uninitialized variable" 警告](#2025-07-09-%E7%BC%93%E5%AD%98%E6%96%87%E4%BB%B6%E6%9C%AA%E7%94%9F%E6%88%90%E4%B8%8E-uninitialized-variable-%E8%AD%A6%E5%91%8A)
  - [[2025-07-09] 正则 `location` 中 `proxy_pass` 带 URI 导致启动失败](#2025-07-09-%E6%AD%A3%E5%88%99-location-%E4%B8%AD-proxy_pass-%E5%B8%A6-uri-%E5%AF%BC%E8%87%B4%E5%90%AF%E5%8A%A8%E5%A4%B1%E8%B4%A5)
  - [[2025-07-10] `proxy_cache_purge` 始终 404](#2025-07-10-proxy_cache_purge-%E5%A7%8B%E7%BB%88-404)
  - [[2025-07-13] `proxy_cache_purge` 返回 "Empty reply" 错误](#2025-07-13-proxy_cache_purge-%E8%BF%94%E5%9B%9E-empty-reply-%E9%94%99%E8%AF%AF)
  - [[2025-07-31] pre-commit 自动添加换行导致 Nginx 模块软链接损坏](#2025-07-31-pre-commit-%E8%87%AA%E5%8A%A8%E6%B7%BB%E5%8A%A0%E6%8D%A2%E8%A1%8C%E5%AF%BC%E8%87%B4-nginx-%E6%A8%A1%E5%9D%97%E8%BD%AF%E9%93%BE%E6%8E%A5%E6%8D%9F%E5%9D%8F)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# NGINX Troubleshooting Guide

- **作者**: 张人大 (Renda Zhang)
- **最后更新**: July 05, 2026, 14:48 (UTC+08:00)

---

## 简介

本指南系统记录了  **轻量级** 网站（🌐 [www.rendazhang.com](https://www.rendazhang.com)）技术栈中遇到的 NGINX 相关疑难问题及其解决方案。作为生产环境运维的重要知识库，它详细描述了各类问题的：

1. **故障现象** - 用户端表现与服务器日志特征
2. **排查过程** - 诊断思路与关键检查点
3. **根本原因** - 技术原理层面的深度分析
4. **解决方案** - 经过验证的有效修复方案
5. **经验总结** - 预防措施与最佳实践

### 涵盖问题类型

✅ HTTP/2 协议兼容性问题

✅ 代理缓存配置与调优

✅ 正则表达式位置块陷阱

✅ 动态模块兼容性故障

✅ 安全头策略优化

### 核心价值

- **快速排障**：提供已验证的诊断路径，避免重复踩坑
- **知识传承**：保存团队经验，降低新人学习曲线
- **预防参考**：识别常见反模式，优化架构设计
- **版本适配**：记录特定环境（OS/Nginx版本）的兼容方案

### 使用建议

1. 按时间线查看最新问题
2. 通过症状关键词搜索匹配案例
3. 参考"经验总结"优化新环境部署
4. 提交新问题请遵循现有格式

### BUG 记录格式要求

记录新 BUG 时请遵循以下模板：

1. **标题**：以 `[YYYY-MM-DD]` 开头概述问题
2. **环境**：列出 Nginx 版本、操作系统及相关模块
3. **症状**：描述用户端表现与日志信息
4. **排查过程**：概述关键诊断步骤
5. **根本原因**：说明导致问题的核心原因
6. **解决方案**：给出已验证的修复办法
7. **经验总结**：记录预防措施与最佳实践

状态跟踪通过在「问题状态」小节中的勾选框体现：`[ ]` 表示未解决，`[x]` 表示已修复。

### 问题状态

- [x] [2025-07-07] HTTP/2 `net::ERR_HTTP2_PROTOCOL_ERROR` on `/chat` & `favicon.ico`
- [x] [2025-07-09] 缓存文件未生成与 "uninitialized variable" 警告
- [x] [2025-07-09] 正则 `location` 中 `proxy_pass` 带 URI 导致启动失败
- [x] [2025-07-10] `proxy_cache_purge` 始终 404
- [x] [2025-07-13] `proxy_cache_purge` 返回 "Empty reply" 错误
- [x] [2025-07-31] pre-commit 添加换行导致 Nginx 模块软链接损坏
- [x] [2026-06-12] TLS 1.2 在 ECDSA 证书下握手失败
- [x] [2026-06-12] 静态页面和资源缺少安全响应头
- [x] [2026-06-12] Astro hydration inline scripts 被 CSP 拦截
- [x] [2026-06-14] Chat Widget iframe 被 CSP frame-src 拦截
- [x] [2026-06-12] `/_astro/` 长缓存被通用静态资源规则覆盖
- [x] [2026-06-12] 隐藏敏感路径回退首页且 apex 域名未规范化

---

## [2026-06-12] TLS 1.2 在 ECDSA 证书下握手失败

**环境**

- NGINX 版本：1.24.0
- 操作系统：Ubuntu 24.04
- 相关模块：OpenSSL 3.0、Certbot、TLS

**症状 (Symptoms)**

- `ssl_protocols` 已声明 `TLSv1.2 TLSv1.3`。
- `openssl s_client -tls1_3` 握手成功，`openssl s_client -tls1_2` 返回 handshake failure。

**排查过程 (Diagnosis)**

1. 检查证书发现 `Public Key Algorithm: id-ecPublicKey`，签名算法为 `ecdsa-with-SHA384`。
2. 检查旧 `ssl_ciphers`，仅包含 `ECDHE-RSA-*` TLS 1.2 套件。
3. TLS 1.3 不受 `ssl_ciphers` 控制，因此 TLS 1.3 正常，TLS 1.2 没有可用 ECDSA 套件。

**根因 (Root Cause)**

ECDSA 证书不能使用仅 RSA 的 TLS 1.2 cipher 列表完成协商。

**解决方案 (Fix)**

- 将证书、协议和 cipher 抽取到 `snippets/ssl-rendazhang.conf`。
- TLS 1.2 cipher 同时包含 `ECDHE-ECDSA-*` 与 `ECDHE-RSA-*`，保留 TLS 1.3 默认 cipher 行为。
- 变更后用以下命令验收：

```bash
echo | openssl s_client -connect 127.0.0.1:443 -servername www.rendazhang.com -tls1_2 -brief
echo | openssl s_client -connect 127.0.0.1:443 -servername www.rendazhang.com -tls1_3 -brief
```

---

## [2026-06-12] 静态页面和资源缺少安全响应头

**环境**

- NGINX 版本：1.24.0
- 操作系统：Ubuntu 24.04
- 相关模块：`add_header`

**症状 (Symptoms)**

- `/cloudchat/auth/healthz` 返回 HSTS/CSP/X-Frame-Options 等安全头。
- 首页、`/deepseek_chat/`、`/sitemap.xml`、`/_astro/*.css` 缺少部分安全头。

**排查过程 (Diagnosis)**

1. server 级配置已有安全头。
2. HTML/XML/JSON、`/_astro/`、通用静态资源 location 内部又声明了 `add_header Cache-Control` 或 `Last-Modified`。
3. Nginx 中子级 block 一旦声明 `add_header`，不会继续继承父级 `add_header`。

**根因 (Root Cause)**

安全头只在 server 级声明，带有自定义 `add_header` 的 location 覆盖了继承链。

**解决方案 (Fix)**

- 新增 `snippets/security-headers.conf`，集中维护 HSTS、CSP、X-Content-Type-Options、X-Frame-Options、Referrer-Policy。
- 所有带 `add_header` 的 public location 显式 `include snippets/security-headers.conf;`。
- 新增或调整 location 时必须检查是否声明了 `add_header`，若声明则同步 include 安全头 snippet。

---

## [2026-06-12] Astro hydration inline scripts 被 CSP 拦截

**环境**

- NGINX 版本：1.24.0
- 操作系统：Ubuntu 24.04
- 当时前端构建：Astro 6 + React，静态文件由 Nginx 提供
- 相关模块：`Content-Security-Policy`、Astro partial hydration

**症状 (Symptoms)**

- 浏览器访问 `https://rendazhang.com/` 或 `https://www.rendazhang.com/` 后，Console 报错：

```text
Executing inline script violates the following Content Security Policy directive 'script-src ...'
```

- 报错中出现 `sha256-QzWF...`、`sha256-SaCk...`、`sha256-Q2BP...` 等 inline script hash。
- 页面 HTML 可正常返回，但 React/Astro hydration 相关交互脚本被浏览器阻止执行。

**排查过程 (Diagnosis)**

1. 检查线上响应头，确认 `script-src` 仅允许 `'self'`、Credly、Sentry 等外部来源，没有 inline script hash、nonce 或 `unsafe-inline`。
2. 下载首页、`/deepseek_chat/`、`/login/`、`/docs/` HTML，计算所有可执行 inline script 的 SHA-256。
3. 报错 hash 与 Astro 自动注入的 hydration runtime inline scripts 匹配；`application/ld+json` 是结构化数据脚本，不是本次 console 报错来源。
4. 复核前端源码：`/js/base-layout-init.js` 已外置，但 Astro 6 仍会为 `client:load`、`client:visible` 等 hydration 指令注入 runtime inline scripts。

**根因 (Root Cause)**

Nginx CSP 收紧后，`script-src` 未包含当前 Astro 生产构建生成的 hydration inline script hash。浏览器按 CSP 阻止这些脚本执行。

**解决方案 (Fix)**

- 在 `snippets/security-headers.conf` 的单行 `Content-Security-Policy` 中为 `script-src` 增加当前生产构建所需的 SHA-256 hash allowlist：

```text
'sha256-QzWFZi+FLIx23tnm9SBU4aEgx4x8DsuASP07mfqol/c='
'sha256-SaCkFfPruIdTXT8/97JArQmGxiJAL2o4bBDvSgJ5y3Q='
'sha256-Q2BPg90ZMplYY+FSdApNErhpWafg2hcRRbndmvxuL/Q='
'sha256-mPc0DfitWGAMcDxTUukGOzm0aUEa/A67WnBDMh7FOHI='
'sha256-9PM+iIXt2xgJUXAwbq9LGlzgU9Wqrfd7/UpLbzfA+Tk='
```

- 不启用 `unsafe-inline`，避免扩大 CSP 执行面。
- 保持 CSP header 单行，避免再次触发 HTTP/2 header 编码问题。

**经验总结 (Lessons Learned)**

- 前端重新构建、升级 Astro、调整 hydration 指令或新增 inline script 后，应重新抓取生产 HTML 并复核 hash。
- 中长期可评估 Astro 的 `security.csp` 原生能力，减少手工维护 Nginx hash allowlist。
- CSP 变更上线后需用浏览器 Console 验收，`curl` 只能确认 header，不能证明页面脚本实际可执行。
- 当前状态（2026-07-05）：前端已升级到 Astro 7，`/deepseek_chat/` iframe 嵌入标记已外置为同源脚本 `/js/deepseek-embed.js`；当前 Nginx CSP hash allowlist 已覆盖已验证的可执行 inline scripts，未启用 `unsafe-inline`。
- 2026-08-01：前端 `astro@7.1.6` 安全补丁改变 Astro island hydration runtime，可执行 inline script 新增 hash `sha256-Ya0pUYrC7nM5Cn/056TyVuEiz6dFGrzmkWzgON0pF0U=`；本次仅追加该 hash，保留既有 hash 以兼容当前线上构建与回滚窗口。

---

## [2026-06-14] Chat Widget iframe 被 CSP frame-src 拦截

**环境**

- NGINX 版本：1.24.0
- 操作系统：Ubuntu 24.04
- 当时前端构建：Astro 6 + React，首页 `ChatWidget` 通过 iframe 加载 `/deepseek_chat/`
- 相关模块：`Content-Security-Policy`、`frame-src`

**症状 (Symptoms)**

- 首页点击右下角 `button.c-chat-widget-toggle` 后，面板出现但聊天 iframe 无法加载。
- 浏览器 Console 报错：

```text
Framing 'https://www.rendazhang.com/deepseek_chat/' violates the following Content Security Policy directive: "frame-src https://www.credly.com".
```

- 直接访问 `https://www.rendazhang.com/deepseek_chat/` 可正常使用。

**排查过程 (Diagnosis)**

1. 检查前端 `ChatWidget`，iframe 使用同源相对路径 `src={`${CHAT_PAGE_PATH}/`}`，实际加载 `/deepseek_chat/`。
2. 检查线上 CSP 响应头，`frame-src` 只包含 `https://www.credly.com`。
3. Credly 证书 iframe 需要保留外部来源，Chat Widget iframe 需要允许同源来源。
4. 浏览器点击验证后发现 `/deepseek_chat/` 页面自身的 `frame-ancestors 'none'` 仍会拒绝被首页嵌入。

**根因 (Root Cause)**

CSP `frame-src` 只放行 Credly，没有放行 `'self'`；同时 `frame-ancestors 'none'` 会禁止 `/deepseek_chat/` 被任何页面嵌入。二者共同导致本站首页不能嵌入本站同源聊天页。

**解决方案 (Fix)**

- 将 `snippets/security-headers.conf` 中的 `frame-src https://www.credly.com;` 改为 `frame-src 'self' https://www.credly.com;`。
- 将 `frame-ancestors 'none'` 改为 `frame-ancestors 'self'`，只允许同源页面嵌入本站页面。
- 保留 `X-Frame-Options: SAMEORIGIN`，允许同源页面之间 iframe 嵌入。

**经验总结 (Lessons Learned)**

- `frame-src` 控制当前页面可以嵌入哪些 iframe，`frame-ancestors` 控制当前页面允许被谁嵌入，二者方向不同。
- 新增 iframe 功能时要同步更新 CSP allowlist，并用浏览器 Console 验收。

---

## [2026-06-12] `/_astro/` 长缓存被通用静态资源规则覆盖

**环境**

- NGINX 版本：1.24.0
- 操作系统：Ubuntu 24.04
- 相关模块：location 匹配、静态缓存

**症状 (Symptoms)**

- 预期 `/_astro/` 指纹文件缓存 365 天。
- 实际 `/_astro/chat_widget...css` 返回 30 天缓存，并命中通用静态资源规则。

**排查过程 (Diagnosis)**

1. 配置中存在普通前缀 `location /_astro/`。
2. 同时存在通用正则 `location ~* \.(css|js|...)$`。
3. Nginx location 选择中，普通前缀匹配后仍会继续检查正则；正则命中后覆盖普通前缀。

**根因 (Root Cause)**

`/_astro/` 使用普通前缀 location，优先级低于后续命中的静态资源正则。

**解决方案 (Fix)**

- 将 `location /_astro/` 改为 `location ^~ /_astro/`。
- `/_astro/` 只返回 `Cache-Control: public, max-age=31536000, immutable`，避免和 `expires` 产生重复缓存头。

---

## [2026-06-12] 隐藏敏感路径回退首页且 apex 域名未规范化

**环境**

- NGINX 版本：1.24.0
- 操作系统：Ubuntu 24.04
- 相关模块：SPA fallback、server_name

**症状 (Symptoms)**

- `https://www.rendazhang.com/.env` 和 `/.env.local` 返回首页 200。
- `https://rendazhang.com/` 直接返回 200，但页面 canonical 指向 `https://www.rendazhang.com/`。

**排查过程 (Diagnosis)**

1. `location /` 使用 `try_files $uri $uri/ /index.html`，不存在的隐藏文件被回退到首页。
2. 旧 HTTPS server 同时声明 `www.rendazhang.com rendazhang.com`，apex 和 www 使用同一内容响应。

**根因 (Root Cause)**

隐藏路径没有统一拦截规则；apex host 未拆成独立 canonical redirect server。

**解决方案 (Fix)**

- 增加 `location ~ /\.(?!well-known/) { return 404; }`，默认阻断隐藏文件访问。
- 增加 `location ^~ /.well-known/`，保留标准验证/应用声明目录。
- 将 apex HTTPS server 拆出，并 `return 301 https://www.rendazhang.com$request_uri;`。
- HTTP 默认入口也统一跳转到 `https://www.rendazhang.com$request_uri`。

---

## [2026-06-28] 未知静态路径返回首页造成 soft-404

**环境**

- NGINX 版本：1.24.0
- 操作系统：Ubuntu 24.04
- 相关模块：静态 Astro 站点、SEO/GEO、`location /`

**症状 (Symptoms)**

- `https://www.rendazhang.com/definitely-not-real` 返回首页 HTML 和 HTTP 200。
- 未提供的公开资源，例如 `/manifest.webmanifest`，也被回退到首页 HTML。

**排查过程 (Diagnosis)**

1. 主站是静态 Astro 输出，不需要 SPA history fallback。
2. `location /` 使用 `try_files $uri $uri/ /index.html`，导致所有未知路径都返回首页。
3. 搜索引擎会把这类响应视为 soft-404 风险，降低不存在 URL、sitemap 和正文抓取结果的可信度。

**根因 (Root Cause)**

通用静态路径沿用了 SPA fallback，但当前站点路由已经由 Astro 构建为真实静态文件和目录。

**解决方案 (Fix)**

- 将 `location /` 改为 `try_files $uri $uri/ =404;`。
- 保留现有 `error_page 404 /404.html`，让未知路径返回真实 HTTP 404 并展示静态错误页。
- 部署后验证：

```bash
curl -I https://www.rendazhang.com/
curl -I https://www.rendazhang.com/llms.txt
curl -I https://www.rendazhang.com/definitely-not-real
curl -I https://www.rendazhang.com/manifest.webmanifest
```

预期：主页和 `llms.txt` 为 200，未知路径与未提供的 manifest 为 404。

---

## [2025-07-07] HTTP/2 `net::ERR_HTTP2_PROTOCOL_ERROR` on `/chat` & `favicon.ico`

**环境**

- NGINX 版本：1.22.1
- 操作系统：CentOS 7
- 相关模块 / 中间件：HTTP/2、proxy_pass

**症状 (Symptoms)**

- 在 `https://rendazhang.com` 使用 “Chat with AI” 功能时报：
  ```
  favicon.ico (failed) net::ERR_HTTP2_PROTOCOL_ERROR
  chat (failed)       net::ERR_HTTP2_PROTOCOL_ERROR
  ```
- 服务器本地 `curl -X POST 127.0.0.1:5000/chat …` 调用正常，说明后端服务 OK。

**排查过程 (Diagnosis)**

1. 确认前后端流量经由 HTTP/2。
2. 对比本地直连与经 NGINX 转发的差异 → 怀疑响应头。
3. 注意到 `Content-Security-Policy` 被写成多行字符串，HTTP/2 规范要求 header 值单行。
4. `net::ERR_HTTP2_PROTOCOL_ERROR` 多因 header 格式非法或被过早关闭引起。

**根因 (Root Cause)**

多行 `Content-Security-Policy` header 违反 HTTP/2 header 编码规则，导致 Chrome/HTTP2 连接直接复位。

**解决方案 (Fix)**

将多行 CSP 改为单行 —— commit `f15e126e`：

```diff
- add_header Content-Security-Policy "
-     default-src 'self';
-     img-src … ;
-     …
- " always;
+ add_header Content-Security-Policy "default-src 'self'; img-src … ; script-src … ; style-src … ; font-src … ; frame-src … ; object-src 'self'; media-src 'self'; connect-src 'self';" always;
```

**参考资料 (References)**

- Chrome `net::ERR_HTTP2_PROTOCOL_ERROR` 官方说明

---

## [2025-07-09] 缓存文件未生成与 "uninitialized variable" 警告

**环境**

- NGINX 版本：1.24.0
- 操作系统：CentOS 7
- 相关模块：proxy_cache、proxy_buffering

**症状 (Symptoms)**

- 多次访问 `/cloudchat/test` 仍然 `X-Cache-Status: MISS`，`/var/cache/nginx` 为空
- `error.log` 中出现 `using uninitialized "do_not_cache" variable` 警告

**排查过程 (Diagnosis)**

1. 确认目录权限及编译参数均正常
2. 检查配置发现变量 `$do_not_cache` 未默认赋值
3. 同时在 `/cloudchat/` 中启用了 `proxy_buffering off`

**根因 (Root Cause)**

未初始化变量导致 `proxy_cache_bypass` 始终生效；而关闭 `proxy_buffering` 时， `proxy_cache` 逻辑不会执行

**解决方案 (Fix)**

1. 在 `location /cloudchat/` 内添加 `set $do_not_cache 0;`
2. 仅在需要 SSE/WebSocket 的接口使用 `proxy_buffering off`

---

## [2025-07-09] 正则 `location` 中 `proxy_pass` 带 URI 导致启动失败

**环境**

- NGINX 版本：1.24.0
- 操作系统：CentOS 7
- 相关模块：proxy_pass

**症状 (Symptoms)**

- 执行 `nginx -t` 报错：
  ```
  nginx: [emerg] "proxy_pass" cannot have URI part in location given by regular expression
  ```
- 问题出现在需禁用缓存的 SSE/WebSocket 接口。

**排查过程 (Diagnosis)**

1. 这些接口位于正则 `location`，配置为 `proxy_pass http://127.0.0.1:5000/`。
2. 另一普通 `location` 使用同一后端但开启缓存。
3. 查阅官方文档得知，正则 `location` 的 `proxy_pass` 不允许包含 URI 部分。

**根因 (Root Cause)**

正则 `location` 搭配带 URI 的 `proxy_pass` 违反 NGINX 语法规则。

**解决方案 (Fix)**

1. 去掉 URI，改为 `proxy_pass http://127.0.0.1:5000;` —— commit `033f374`。
2. 仍在该 `location` 中保持 `proxy_buffering off` 以支持流式协议。

---

## [2025-07-10] `proxy_cache_purge` 始终 404

**环境**

- NGINX 版本：1.24.0
- 操作系统：CentOS 7
- 相关模块：ngx_cache_purge

**症状 (Symptoms)**

- 执行 `curl -X PURGE http://localhost/cloudchat/purge-cache/<cache_key>` 返回 404
- 日志无明显报错，缓存键确认无误

**排查过程 (Diagnosis)**

1. 查看配置发现 `location ~ /cloudchat/purge-cache(/.*)`，捕获组错误
2. 正则未正确匹配 `<cache_key>`，导致 `$1` 为空
3. 将规则改为 `location ~ /cloudchat/purge-cache/(.*)` 后重载 Nginx

**根因 (Root Cause)**

括号放置位置错误，`proxy_cache_purge` 未获取到待清理的 key

**解决方案 (Fix)**

1. 更新配置为 `location ~ /cloudchat/purge-cache/(.*) { ... }` —— commit `cac19e0`
2. 重载 Nginx 后再次执行 `curl -X PURGE ...`，终端返回 “Successful purge”

---

## [2025-07-13] `proxy_cache_purge` 返回 "Empty reply" 错误

**环境**

- NGINX 版本：1.24.0
- 操作系统：Ubuntu 24.04 LTS
- 相关模块：`ngx_http_cache_purge_module` (动态模块)

**症状 (Symptoms)**

- 执行缓存清除命令返回空响应：
  ```bash
  curl -X PURGE http://localhost/cloudchat/purge-cache/<key>
  curl: (52) Empty reply from server
  ```
- 错误日志中出现信号 11 (SIGSEGV) 核心转储：
  ```
  2025/07/13 05:59:31 [alert] 47149#47149: worker process 47151 exited on signal 11 (core dumped)
  ```
- 无其他明显错误信息，缓存键确认无误

**排查过程 (Diagnosis)**

1. 验证缓存键格式正确：
   ```bash
   # 检查配置的缓存键格式
   grep proxy_cache_key /etc/nginx/nginx.conf
   ```
2. 确认缓存文件实际存在：
   ```bash
   # 查找匹配的缓存文件
   grep -r ".*KEY_NAME*" /var/cache/nginx
   # 示例：
   grep -r ".*rendazhang.com.*" /var/cache/nginx
   ```
3. 检查模块加载状态：
   ```bash
   # 确认模块已加载
   grep cache_purge /etc/nginx/modules-enabled/*.conf
   ```
4. 测试不同环境发现：
   - 本地开发环境 (Ubuntu 22.04) 工作正常
   - 生产环境 (Ubuntu 24.04) 出现段错误

**根因 (Root Cause)**

- Ubuntu 24.04 官方仓库的 `libnginx-mod-http-cache-purge` 动态模块与 Nginx 1.24.0 存在二进制不兼容
- 动态模块 ABI 版本不匹配导致内存访问冲突 (SIGSEGV)
- 问题特定于 Ubuntu 24.04 + Nginx 1.24.0 组合

**解决方案 (Fix)**

重新从源码编译缓存清除模块：

```bash
# 获取匹配的 Nginx 版本
nginx_version=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+')

# 下载源码并编译模块
wget http://nginx.org/download/nginx-${nginx_version}.tar.gz
tar zxvf nginx-${nginx_version}.tar.gz
git clone https://github.com/nginx-modules/ngx_cache_purge.git
cd nginx-${nginx_version}
./configure --with-compat --add-dynamic-module=../ngx_cache_purge
make modules

# 替换不兼容模块
sudo cp objs/ngx_http_cache_purge_module.so /usr/lib/nginx/modules/
sudo systemctl restart nginx
```

**验证步骤**

1. 测试清除命令返回 200 状态码：
   ```bash
   curl -I -X PURGE http://localhost/cloudchat/purge-cache/example-key
   # 示例：
   curl -I -X PURGE http://localhost/cloudchat/purge-cache/www.rendazhang.com/cloudchat/test
   ```
2. 检查缓存文件是否被移除：
   ```bash
   grep -r ".*KEY_NAME.*" /var/cache/nginx
   ```
3. 确认缓存状态变为 MISS：
   ```bash
   curl -I https://www.rendazhang.com/cloudchat/test
   X-Cache-Status: MISS
   ```

**经验总结**

1. 优先从源码编译动态模块，确保与 Nginx 主版本完全兼容
2. 生产环境升级前应在相同 OS 版本测试关键功能
3. 使用 `apt-mark hold` 锁定关键包版本防止意外更新
4. 核心服务模块应纳入持续集成测试流程

**参考资料**

- 🌐 [Nginx 动态模块编译指南](https://nginx.org/en/docs/beginners_guide.html#dynamic)
- 🌐 [ngx_cache_purge 模块文档](https://github.com/nginx-modules/ngx_cache_purge)
- 🌐 [Linux 信号 11 (SIGSEGV) 说明](https://man7.org/linux/man-pages/man7/signal.7.html)

---

## [2025-07-31] pre-commit 自动添加换行导致 Nginx 模块软链接损坏

**环境**

- NGINX 版本：1.24.0
- 操作系统：Ubuntu 24.04 LTS
- 相关模块：`ngx_http_cache_purge_module` 等动态模块

**症状 (Symptoms)**

- `nginx -t` 报错：`open() "/etc/nginx/modules-enabled/50-mod-http-cache-purge.conf" failed (2: No such file or directory)`
- `ls -al` 显示软链接目标包含 `$'\n'`

**排查过程 (Diagnosis)**

1. 检查预提交钩子发现 `end-of-file-fixer` 对软链接生效
2. `readlink` 结果末尾存在 `\n`
3. 软链接路径无效导致模块加载失败

**根因 (Root Cause)**

- `end-of-file-fixer` 在软链接文件中插入换行符

**解决方案 (Fix)**

1. 重新创建正确的软链接
2. `.pre-commit-config.yaml` 排除 `modules-enabled` 与 `sites-enabled` 目录
3. `.gitattributes` 将 `modules-enabled/*` 与 `sites-enabled/*` 标记为 `-text`

**经验总结**

- 排除自动格式化钩子对软链接的影响
- 更新 pre-commit 后应检查特殊文件是否被修改
- 定期核查其他软链接目录，避免再次出现换行损坏
