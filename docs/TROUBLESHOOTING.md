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
  - [[2025-07-07] HTTP/2 `net::ERR_HTTP2_PROTOCOL_ERROR` on `/chat` & `favicon.ico`](#2025-07-07-http2-neterr_http2_protocol_error-on-chat--faviconico)
  - [[2025-07-09] 缓存文件未生成与 "uninitialized variable" 警告](#2025-07-09-%E7%BC%93%E5%AD%98%E6%96%87%E4%BB%B6%E6%9C%AA%E7%94%9F%E6%88%90%E4%B8%8E-uninitialized-variable-%E8%AD%A6%E5%91%8A)
  - [[2025-07-09] 正则 `location` 中 `proxy_pass` 带 URI 导致启动失败](#2025-07-09-%E6%AD%A3%E5%88%99-location-%E4%B8%AD-proxy_pass-%E5%B8%A6-uri-%E5%AF%BC%E8%87%B4%E5%90%AF%E5%8A%A8%E5%A4%B1%E8%B4%A5)
  - [[2025-07-10] `proxy_cache_purge` 始终 404](#2025-07-10-proxy_cache_purge-%E5%A7%8B%E7%BB%88-404)
  - [[2025-07-13] `proxy_cache_purge` 返回 "Empty reply" 错误](#2025-07-13-proxy_cache_purge-%E8%BF%94%E5%9B%9E-empty-reply-%E9%94%99%E8%AF%AF)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# NGINX Troubleshooting Guide

* **Last Updated:** July 18, 2025, 03:00 (UTC+8)
* **作者:** 张人大（Renda Zhang）

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
