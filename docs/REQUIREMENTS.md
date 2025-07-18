<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [项目需求清单](#%E9%A1%B9%E7%9B%AE%E9%9C%80%E6%B1%82%E6%B8%85%E5%8D%95)
  - [简介](#%E7%AE%80%E4%BB%8B)
  - [🚀 核心功能](#-%E6%A0%B8%E5%BF%83%E5%8A%9F%E8%83%BD)
  - [🔧 技术需求](#-%E6%8A%80%E6%9C%AF%E9%9C%80%E6%B1%82)
  - [🌱 未来计划](#-%E6%9C%AA%E6%9D%A5%E8%AE%A1%E5%88%92)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 项目需求清单

- **负责人**: 张人大（Renda Zhang）
- **最后更新**: July 18, 2025, 17:30 (UTC+8)
- **项目状态**: 稳定运行，持续开发中

---

## 简介

该仓库维护 www.rendazhang.com 网站在轻量级服务器上的 Nginx 配置。

配置文件已在 Ubuntu 24.04 LTS 环境验证，兼顾 HTTPS、安全防护与缓存优化，适合 1GB 内存服务器部署。

---

## 🚀 核心功能

- 自动 HTTPS：使用 Certbot 管理证书，HTTP 请求全部重定向到 HTTPS
- 反向代理：将 `/cloudchat/` 流量转发到后端 Gunicorn + Flask 服务
- 动态缓存：`cloudchat_cache` 缓存区，支持缓存清理端点 `PURGE`
- 流式接口：SSE/WebSocket 接口关闭 `proxy_buffering`，支持实时响应
- 限流控制：`limit_req_zone` 配置每个客户端 5 r/s
- 安全头：开启 `HSTS` 与单行版 `CSP`，阻断敏感文件访问
- 静态文件缓存：常见静态资源设置 `expires 30d`，PDF 单独缓存 7 天
- 自定义错误页：提供 404 与 50x 页面

---

## 🔧 技术需求

- [x] 配置动态模块 `ngx_cache_purge` 并通过自动化脚本保证版本兼容
- [x] 支持在 Ubuntu 24.04 系统下运行，兼容 CentOS 7 迁移流程
- [x] 通过 pre-commit 自动执行 `doctoc` 更新文档目录
- [ ] 集成压力测试场景（如 `siege -c 50`）到 CI 流程
- [ ] 文档内提供 Docker 化部署示例

---

## 🌱 未来计划

- 新增自动化健康检查脚本，定期验证证书和缓存状态
- 引入更细粒度的访问日志分析工具
