<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [NGINX Troubleshooting Guide](#nginx-troubleshooting-guide)
  - [\[2025-07-07\] HTTP/2 `net::ERR_HTTP2_PROTOCOL_ERROR` on `/chat` \& `favicon.ico`](#2025-07-07-http2-neterr_http2_protocol_error-on-chat--faviconico)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# NGINX Troubleshooting Guide

* **Last Updated:** July 7, 2025, 17:50 (UTC+8)
* **作者:** 张人大（Renda Zhang）

Common issues & resolutions encountered in the rendazhang.com stack

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
