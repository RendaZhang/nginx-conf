<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [NGINX Troubleshooting Guide](#nginx-troubleshooting-guide)
  - [简介](#%E7%AE%80%E4%BB%8B)
  - [[2025-07-07] HTTP/2 `net::ERR_HTTP2_PROTOCOL_ERROR` on `/chat` & `favicon.ico`](#2025-07-07-http2-neterr_http2_protocol_error-on-chat--faviconico)
  - [[2025-07-09] 缓存文件未生成与 "uninitialized variable" 警告](#2025-07-09-%E7%BC%93%E5%AD%98%E6%96%87%E4%BB%B6%E6%9C%AA%E7%94%9F%E6%88%90%E4%B8%8E-uninitialized-variable-%E8%AD%A6%E5%91%8A)
  - [[2025-07-09] 正则 `location` 中 `proxy_pass` 带 URI 导致启动失败](#2025-07-09-%E6%AD%A3%E5%88%99-location-%E4%B8%AD-proxy_pass-%E5%B8%A6-uri-%E5%AF%BC%E8%87%B4%E5%90%AF%E5%8A%A8%E5%A4%B1%E8%B4%A5)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# NGINX Troubleshooting Guide

* **Last Updated:** July 9, 2025, 16:40 (UTC+8)
* **作者:** 张人大（Renda Zhang）

---

## 简介

Common issues & resolutions encountered in the rendazhang.com stack

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
