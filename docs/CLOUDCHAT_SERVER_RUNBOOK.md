<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [CloudChat 服务器配置运行手册](#cloudchat-%E6%9C%8D%E5%8A%A1%E5%99%A8%E9%85%8D%E7%BD%AE%E8%BF%90%E8%A1%8C%E6%89%8B%E5%86%8C)
  - [0. 概览（Overview）](#0-%E6%A6%82%E8%A7%88overview)
  - [1. 架构（现状 / 规划）](#1-%E6%9E%B6%E6%9E%84%E7%8E%B0%E7%8A%B6--%E8%A7%84%E5%88%92)
  - [2. 服务与资源预算（systemd + OOM）](#2-%E6%9C%8D%E5%8A%A1%E4%B8%8E%E8%B5%84%E6%BA%90%E9%A2%84%E7%AE%97systemd--oom)
  - [3. Nginx](#3-nginx)
  - [4. Redis](#4-redis)
  - [5. CloudChat（后端 API）](#5-cloudchat%E5%90%8E%E7%AB%AF-api)
  - [6. 数据库（规划）](#6-%E6%95%B0%E6%8D%AE%E5%BA%93%E8%A7%84%E5%88%92)
    - [6.1 PostgreSQL（精简配置）](#61-postgresql%E7%B2%BE%E7%AE%80%E9%85%8D%E7%BD%AE)
    - [6.2 PgBouncer（连接池）](#62-pgbouncer%E8%BF%9E%E6%8E%A5%E6%B1%A0)
  - [7. 记录：Nginx 站点与 API 路由](#7-%E8%AE%B0%E5%BD%95nginx-%E7%AB%99%E7%82%B9%E4%B8%8E-api-%E8%B7%AF%E7%94%B1)
  - [8. 日志与监控](#8-%E6%97%A5%E5%BF%97%E4%B8%8E%E7%9B%91%E6%8E%A7)
  - [9. 安全基线](#9-%E5%AE%89%E5%85%A8%E5%9F%BA%E7%BA%BF)
  - [10. 备份与恢复](#10-%E5%A4%87%E4%BB%BD%E4%B8%8E%E6%81%A2%E5%A4%8D)
  - [11. 运维常用清单（Cheat Sheet）](#11-%E8%BF%90%E7%BB%B4%E5%B8%B8%E7%94%A8%E6%B8%85%E5%8D%95cheat-sheet)
  - [12. 变更记录（Changelog）](#12-%E5%8F%98%E6%9B%B4%E8%AE%B0%E5%BD%95changelog)
  - [13. 待办（Next Actions）](#13-%E5%BE%85%E5%8A%9Enext-actions)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# CloudChat 服务器配置运行手册

> 适用：Ubuntu 24.04（小内存 1 GiB 级别），Nginx + Flask（Gunicorn/ gevent）+ Redis；**规划**引入 PgBouncer + PostgreSQL。 本文档用于**记录当前配置**、**目标配置**与**变更记录**，并作为运维 Runbook。

---

## 0. 概览（Overview）

* **主机名**：`<hostname>`
* **云厂商/地域**：`<provider>/<region>`
* **CPU / 内存 / 磁盘**：`<vCPU>x / 1 GiB / <disk>`
* **操作系统**：Ubuntu Server 24.04 LTS
* **时区/NTP**：`<timezone>` / `systemd-timesyncd`（或 `<ntp service>`）
* **交换空间（Swap）**：启用，大小 **2 GiB**
* **当前内存快照**（执行时记录）：

  ```
  Mem:  total 690Mi | used 357Mi | free 88Mi | buff/cache 362Mi | available 333Mi
  Swap: total 2.0Gi | used 198Mi | free 1.8Gi
  ```
* **系统精简与优化**（已实施）：

  * journald **日志大小/生存时间限制**（已配置）
  * **内核参数**调优（sysctl）
  * **轻量化组件替换**以降低常驻内存

> ✅ 上述条目请在部署/变更后更新为**实值**；所有配置文件路径推荐附上 `ls -l` 的时间与权限。

---

## 1. 架构（现状 / 规划）

```
┌────────┐     HTTPS      ┌───────────────────────────────┐
│ Client │ ─────────────▶ │ Nginx (reverse proxy, same domain) │
└────────┘                 └──────────────┬────────────────┘
                                          │ /cloudchat/
                                  ┌───────▼────────┐
                                  │ CloudChat API  │  Flask + Gunicorn(gevent)
                                  └───────┬────────┘
                                          │ sessions/limits
                                  ┌───────▼───────┐
                                  │   Redis      │  (会话/限流/队列)
                                  └──────────────┘

[规划] 认证/业务数据： CloudChat → PgBouncer → PostgreSQL
```

* **域名 / 站点**：`<domain(s)>`
* **TLS 证书**：`<issuer>`（自动续期工具：`<e.g. certbot/servbot>`）
* **认证模型**：同域 **Cookie 会话**（HttpOnly/ Secure/ SameSite=Lax）

---

## 2. 服务与资源预算（systemd + OOM）

> 目标：在 1 GiB 主机上保持稳定，数据库“保命”，应用可自愈。

| 服务                                | 当前 OOMScoreAdjust | 当前 MemoryMax | 目标 OOMScoreAdjust | 目标 MemoryMax | 备注        |
| --------------------------------- | ----------------- | ------------ | ----------------- | ------------ | --------- |
| **nginx**                         | **-200**          | *(未显式限制)*    | -200              | 128M（可选）     | 反代/静态     |
| **redis-server**                  | **-100**          | **256M**     | -200              | 160–192M     | 会话/限流/队列  |
| **cloudchat**（Gunicorn 2 workers） | **-100**          | **600M**     | +100（易被杀）         | 300M         | 无状态，可自动重启 |
| **pgbouncer**                     | *N/A*             | *N/A*        | -200              | 64M          | 事务级连接池    |
| **postgresql**                    | *未部署*             | *未部署*        | **-500**（保命）      | 260M         | 精简配置      |

> ✅ “目标”列为规划值；上线前请在「变更记录」落单并执行验证。

---

## 3. Nginx

* **systemd override**：`/etc/systemd/system/nginx.service.d/override.conf`

  ```ini
  [Service]
  OOMScoreAdjust=-200
  ```
* **主配置**：`/etc/nginx/nginx.conf`
* **站点配置**：`/etc/nginx/sites-available/<site>`（链接至 `sites-enabled/`）
* **反代要点**：

  * 统一前缀：`/cloudchat/` → 后端 `127.0.0.1:5000`
  * 关闭对 API 的缓存；开启 `proxy_http_version 1.1` 与必要的头传递
* **TLS**：`<证书与私钥路径>`；自动续期任务：`<cron/timer>`
* **常用命令**：

  ```bash
  sudo nginx -t && sudo systemctl reload nginx
  journalctl -u nginx -e --no-pager
  ```

> TODO：在此粘贴关键 `server {}` 片段（掩蔽敏感域名/IP）。

---

## 4. Redis

* **systemd override**：`/etc/systemd/system/redis-server.service.d/override.conf`

  ```ini
  [Service]
  OOMScoreAdjust=-100
  MemoryMax=256M   # （目标：160–192M）
  ```
* **配置文件**：`/etc/redis/redis.conf`

  * 建议：

    ```
    maxmemory 160mb
    maxmemory-policy allkeys-lru
    requirepass <REDIS_PASSWORD>
    bind 127.0.0.1
    protected-mode yes
    ```
* **用途**：会话、限流、短期队列
* **检查**：

  ```bash
  redis-cli INFO memory | egrep 'used_memory_human|maxmemory'
  ```

---

## 5. CloudChat（后端 API）

* **systemd 单元**：`/etc/systemd/system/cloudchat.service`

  ```ini
  [Unit]
  Description=CloudChat Flask App with Gunicorn
  After=network.target redis-server.service

  [Service]
  User=root
  WorkingDirectory=/opt/cloudchat
  EnvironmentFile=/etc/cloudchat/cloudchat.env   # ← 推荐，将密钥移至该文件（0600）
  ExecStart=/opt/cloudchat/venv/bin/gunicorn \
    --worker-class gevent --workers 2 \
    --worker-connections 50 --max-requests 1000 --max-requests-jitter 50 \
    --timeout 300 --bind 0.0.0.0:5000 app:app

  Restart=always
  RestartSec=3
  KillSignal=SIGINT
  ProtectSystem=full
  PrivateTmp=true
  NoNewPrivileges=true
  OOMScoreAdjust=-100        # 目标：+100
  MemoryMax=600M             # 目标：300M

  [Install]
  WantedBy=multi-user.target
  ```
* **环境变量文件**：`/etc/cloudchat/cloudchat.env`（**权限 600**）

  ```
  OPENAI_API_KEY=***
  DEEPSEEK_API_KEY=***
  DASHSCOPE_API_KEY=***
  FLASK_SECRET_KEY=***
  REDIS_PASSWORD=***
  ```
* **绑定端口**：`0.0.0.0:5000`（Nginx 反代）
* **健康检查**：`GET /cloudchat/healthz`（建议添加）

---

## 6. 数据库（规划）

### 6.1 PostgreSQL（精简配置）

* **软件**：`postgresql` `postgresql-contrib`
* **配置**：`/etc/postgresql/<ver>/main/postgresql.conf`

  ```
  shared_buffers = 96MB
  work_mem = 4MB
  maintenance_work_mem = 64MB
  effective_cache_size = 384MB
  max_connections = 20
  wal_compression = on
  checkpoint_timeout = 15min
  max_wal_size = 512MB
  min_wal_size = 64MB
  ```
* **systemd override**（保命）：`systemctl edit postgresql`

  ```ini
  [Service]
  OOMScoreAdjust=-500
  MemoryMax=260M
  ```
* **网络访问**：仅本机（`pg_hba.conf` 允许 `local`/`127.0.0.1`）
* **账号/库**（最小权限）：

  ```sql
  CREATE ROLE cloudchat LOGIN PASSWORD '***' NOSUPERUSER NOCREATEDB NOCREATEROLE;
  CREATE DATABASE cloudchat OWNER cloudchat;
  ```
* **迁移策略**：SQLAlchemy Alembic（记录 `versions/` 与 `alembic.ini`）

### 6.2 PgBouncer（连接池）

* **配置**：`/etc/pgbouncer/pgbouncer.ini`

  ```ini
  [databases]
  cloudchat = host=127.0.0.1 port=5432 dbname=cloudchat user=cloudchat password=***

  [pgbouncer]
  listen_addr = 127.0.0.1
  listen_port = 6432
  pool_mode = transaction
  default_pool_size = 10
  reserve_pool_size = 5
  max_client_conn = 200
  ignore_startup_parameters = extra_float_digits
  ```
* **systemd override**：

  ```ini
  [Service]
  OOMScoreAdjust=-200
  MemoryMax=64M
  ```
* **应用连接串**：`postgresql+psycopg://cloudchat:***@127.0.0.1:6432/cloudchat`
* **SQLAlchemy 池参数**：`pool_size=5, max_overflow=0, pool_recycle=1800, pool_pre_ping=True`

---

## 7. 记录：Nginx 站点与 API 路由

* **前端前缀**：`/cloudchat/`
* **后端路由**（示例）：

  * `POST /cloudchat/auth/register`
  * `POST /cloudchat/auth/login`
  * `POST /cloudchat/auth/logout`
  * `GET  /cloudchat/me`
* **静态/缓存策略**：`<static rules>`

> TODO：粘贴关键反代段（`location /cloudchat/ { ... }`）

---

## 8. 日志与监控

* **journald**：大小与保留期限制：`<e.g. SystemMaxUse=..., MaxFileSec=...>`
* **Nginx**：`/var/log/nginx/access.log`, `error.log`
* **CloudChat**：`journalctl -u cloudchat`（或 `gunicorn` 文件日志）
* **Redis**：`/var/log/redis/redis-server.log`
* **PostgreSQL**（规划）：`/var/log/postgresql/postgresql-<ver>-main.log`
* **基础监控**：

  ```bash
  systemd-cgtop
  free -h; vmstat 1 5; iostat -xz 1 3
  ```

---

## 9. 安全基线

* **防火墙**：开放 80/443/22；PostgreSQL/ PgBouncer 仅本机
* **SSH 加固**：禁用 root 直登（或强制密钥）、`PasswordAuthentication no`
* **Secrets 管理**：全部转至 `/etc/cloudchat/cloudchat.env`（0600）
* **TLS**：自动续期成功率监控与失败告警

---

## 10. 备份与恢复

* **PostgreSQL**：每日 `pg_dump`（保留 7–14 天），每周全量，每日增量（如用 `wal-g` 可选）
* **配置备份**：`/etc`、`/opt/cloudchat` 关键文件纳入 Git/压缩包
* **恢复演练**：季度至少一次，从备份恢复到隔离环境并通过健康检查

---

## 11. 运维常用清单（Cheat Sheet）

```bash
# 检查服务
systemctl status nginx redis-server cloudchat pgbouncer postgresql --no-pager

# 在线变更与重载
sudo nginx -t && sudo systemctl reload nginx
sudo systemctl restart cloudchat
sudo systemctl restart redis-server
sudo systemctl restart pgbouncer
sudo systemctl restart postgresql

# 连接/池化观察
psql -U cloudchat -h 127.0.0.1 -p 5432 -d cloudchat -c "select count(*) from pg_stat_activity;"
psql -h 127.0.0.1 -p 6432 pgbouncer -c "show pools;"

# 内存/CPU 快照
free -h; vmstat 1 5; systemd-cgtop
```

---

## 12. 变更记录（Changelog）

| 日期         | 变更内容                                  | 服务        | 版本/提交      | 操作人 | 回滚方式             |
| ---------- | ------------------------------------- | --------- | ---------- | --- | ---------------- |
| YYYY-MM-DD | 将密钥迁移至 `/etc/cloudchat/cloudchat.env` | cloudchat | commit:    |     | 还原 systemd 单元并重启 |
| YYYY-MM-DD | 部署 PostgreSQL + PgBouncer（按精简配置）      | db        | ver:\<x.y> |     | 关闭服务并回退连接串       |

---

## 13. 待办（Next Actions）

*
