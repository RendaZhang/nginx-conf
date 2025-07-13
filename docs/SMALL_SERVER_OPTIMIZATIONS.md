<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [针对小内存服务器的优化和增强建议](#%E9%92%88%E5%AF%B9%E5%B0%8F%E5%86%85%E5%AD%98%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%9A%84%E4%BC%98%E5%8C%96%E5%92%8C%E5%A2%9E%E5%BC%BA%E5%BB%BA%E8%AE%AE)
  - [简介](#%E7%AE%80%E4%BB%8B)
  - [systemd 资源策略](#systemd-%E8%B5%84%E6%BA%90%E7%AD%96%E7%95%A5)
    - [不需额外配置的情况](#%E4%B8%8D%E9%9C%80%E9%A2%9D%E5%A4%96%E9%85%8D%E7%BD%AE%E7%9A%84%E6%83%85%E5%86%B5)
    - [OOMScoreAdjust](#oomscoreadjust)
    - [MemoryMax](#memorymax)
    - [Restart](#restart)
    - [服务如何配置](#%E6%9C%8D%E5%8A%A1%E5%A6%82%E4%BD%95%E9%85%8D%E7%BD%AE)
      - [Tier 0 守门低占用](#tier-0%E2%80%83%E5%AE%88%E9%97%A8%E4%BD%8E%E5%8D%A0%E7%94%A8)
      - [Tier 1 业务常驻](#tier-1%E2%80%83%E4%B8%9A%E5%8A%A1%E5%B8%B8%E9%A9%BB)
      - [Tier 2 短命/定时](#tier-2%E2%80%83%E7%9F%AD%E5%91%BD%E5%AE%9A%E6%97%B6)
  - [速率限制:](#%E9%80%9F%E7%8E%87%E9%99%90%E5%88%B6)
  - [使用轻量级 WSGI 服务器](#%E4%BD%BF%E7%94%A8%E8%BD%BB%E9%87%8F%E7%BA%A7-wsgi-%E6%9C%8D%E5%8A%A1%E5%99%A8)
  - [日志监控:](#%E6%97%A5%E5%BF%97%E7%9B%91%E6%8E%A7)
    - [简单的轻量级监控工具](#%E7%AE%80%E5%8D%95%E7%9A%84%E8%BD%BB%E9%87%8F%E7%BA%A7%E7%9B%91%E6%8E%A7%E5%B7%A5%E5%85%B7)
    - [功能全面的轻量级监控工具](#%E5%8A%9F%E8%83%BD%E5%85%A8%E9%9D%A2%E7%9A%84%E8%BD%BB%E9%87%8F%E7%BA%A7%E7%9B%91%E6%8E%A7%E5%B7%A5%E5%85%B7)
  - [设置交换空间](#%E8%AE%BE%E7%BD%AE%E4%BA%A4%E6%8D%A2%E7%A9%BA%E9%97%B4)
  - [后端服务相关的调整建议](#%E5%90%8E%E7%AB%AF%E6%9C%8D%E5%8A%A1%E7%9B%B8%E5%85%B3%E7%9A%84%E8%B0%83%E6%95%B4%E5%BB%BA%E8%AE%AE)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 针对小内存服务器的优化和增强建议

* **Last Updated:** July 13, 2025, 20:20 (UTC+8)
* **作者:** 张人大（Renda Zhang）

---

## 简介

本文档旨在为运行在 **小内存环境**（如 1GB 或更少内存）的服务器提供优化建议和增强措施，以确保服务的稳定性和性能。

文档以 Ubuntu 24 操作系统为例，详细介绍了从系统配置（如 systemd 资源控制）、服务部署（如轻量级 WSGI 服务器选择）到应用层优化（如会话管理）的全方位策略。

这些建议特别适用于以下场景：

- 个人项目或小型应用部署
- 预算有限的云服务器 / VPS 环境
- 资源受限的边缘计算节点
- 临时测试或开发环境

---

## systemd 资源策略

### 不需额外配置的情况

短命定时/批处理脚本（`certbot.service` 等 `Type=oneshot`）。

默认就够：它们只在 timer 触发时跑几分钟，平时不存在被 OOM 杀的风险。

### OOMScoreAdjust

作用：调整 Linux OOM-Killer 权重（-1000 最难杀，+1000 最先杀）。

何时要配：必须永远存活却占内存很小的守门进程（SSH、Nginx master、systemd-logind…）。

典型设置：`OOMScoreAdjust=-200 ~ -500`。

说明：`-999` 以上保留给内核关键进程，`-100` 以内有时保护力度不够。

### MemoryMax

作用：给服务所在 cgroup 设硬上限；超出即被 cgroup-OOM 杀掉。

何时要配：可能内存飙升、重启代价低的业务进程（Gunicorn、Redis、Node/Java worker…）。

典型设置：1 GiB 机器示例 `MemoryMax=600M`。

说明：先预留 ≈400 MiB 给系统 + Reids + Nginx，再给业务进程余量

### Restart

作用：出错或退出时自动拉起。

何时要配：所有长期后台守护进程。

典型设置：`Restart=always`（最稳）或 `on-failure`；配合 `RestartSec=3`

### 服务如何配置

守门进程要保护，业务进程要限额，脚本任务让它跑。

先把服务按 **重要性** × **内存波动** 分类，再决定 **protect**（调负值）还是 **limit**（设上限）。

这样配置后：
* OOM 先杀可重启的业务进程，站点入口 & SSH 通道几乎不会被误杀。
* 业务进程若内存泄漏会被 systemd 自动拉起，停机窗口 ≤ 几秒。

#### Tier 0 守门低占用

例子：`sshd`, `nginx master`

OOMScoreAdjust: -200 ~ -500

MemoryMax: 不设

Restart: on-failure

#### Tier 1 业务常驻

例子：`gunicorn-cloudchat`, `redis`

OOMScoreAdjust: -100 或 0 或 轻正值，让系统可杀

MemoryMax: 需设 (如 600 MiB)

Restart: always

#### Tier 2 短命/定时

例子：`certbot.service`, 备份脚本

OOMScoreAdjust: 默认 0

MemoryMax: 不设

Restart: 由 .timer 触发；无需

---

## 速率限制:

```nginx
# 在 nginx.conf 的 http 块添加
limit_req_zone $binary_remote_addr zone=flask_limit:10m rate=5r/s;

# 在 location /cloudchat/ 添加
limit_req zone=flask_limit burst=10 nodelay;
```

---

## 使用轻量级 WSGI 服务器

- 使用 Gunicorn + Gevent 作为 WSGI 服务器

部署示例：
```bash
pip install gunicorn
gunicorn -w 2 -k gevent your_app:app
```

---

## 日志监控:

### 简单的轻量级监控工具

安装 htop 步骤：

```bash
sudo apt update
sudo apt install htop
htop --version
# Run htop:
htop
```

使用 htop 简单地定期去手动检查内存使用情况。

### 功能全面的轻量级监控工具

安装 glances 步骤：

```bash
sudo apt update
sudo apt install glances
# Run glances:
glances
```

使用 glances 可以实现 Web-based 界面的远程监控，支持提醒功能和插件扩展。

---

## 设置交换空间

如果尚未设置，可以参考如下操作步骤：

具体可以参考文档：[Ubuntu 24 设置交换空间](https://github.com/RendaZhang/nginx-conf/blob/master/docs/MIGRATION_GUIDE.md#ubuntu-24-%E8%AE%BE%E7%BD%AE%E4%BA%A4%E6%8D%A2%E7%A9%BA%E9%97%B4)

---

## 后端服务相关的调整建议

- 限制对话历史长度
- 定期清理旧会话

具体可以参考 Python 后端项目的文档：[轻量级会话存储方案（针对小内存服务器）](https://github.com/RendaZhang/python-cloud-chat/blob/master/docs/lightweight_backend_development.md#%E8%BD%BB%E9%87%8F%E7%BA%A7%E4%BC%9A%E8%AF%9D%E5%AD%98%E5%82%A8%E6%96%B9%E6%A1%88%E9%92%88%E5%AF%B9%E5%B0%8F%E5%86%85%E5%AD%98%E6%9C%8D%E5%8A%A1%E5%99%A8)
