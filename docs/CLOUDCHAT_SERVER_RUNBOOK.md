<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [CloudChat 服务器配置运行手册（模板）](#cloudchat-%E6%9C%8D%E5%8A%A1%E5%99%A8%E9%85%8D%E7%BD%AE%E8%BF%90%E8%A1%8C%E6%89%8B%E5%86%8C%E6%A8%A1%E6%9D%BF)
  - [0. 概览（Overview）](#0-%E6%A6%82%E8%A7%88overview)
  - [1. 架构（现状 / 规划）](#1-%E6%9E%B6%E6%9E%84%E7%8E%B0%E7%8A%B6--%E8%A7%84%E5%88%92)
  - [2. 服务与资源预算（systemd + OOM）](#2-%E6%9C%8D%E5%8A%A1%E4%B8%8E%E8%B5%84%E6%BA%90%E9%A2%84%E7%AE%97systemd--oom)
  - [3. Nginx](#3-nginx)
  - [4. Redis](#4-redis)
  - [5. CloudChat（后端 API）](#5-cloudchat%E5%90%8E%E7%AB%AF-api)
  - [6. 数据库（已部署）](#6-%E6%95%B0%E6%8D%AE%E5%BA%93%E5%B7%B2%E9%83%A8%E7%BD%B2)
    - [6.1 PostgreSQL（精简配置）](#61-postgresql%E7%B2%BE%E7%AE%80%E9%85%8D%E7%BD%AE)
    - [6.2 PgBouncer（连接池）](#62-pgbouncer%E8%BF%9E%E6%8E%A5%E6%B1%A0)
    - [6.3 验收与检查（本次）](#63-%E9%AA%8C%E6%94%B6%E4%B8%8E%E6%A3%80%E6%9F%A5%E6%9C%AC%E6%AC%A1)
  - [7. 记录：Nginx 站点与 API 路由](#7-%E8%AE%B0%E5%BD%95nginx-%E7%AB%99%E7%82%B9%E4%B8%8E-api-%E8%B7%AF%E7%94%B1)
  - [8. 日志与监控](#8-%E6%97%A5%E5%BF%97%E4%B8%8E%E7%9B%91%E6%8E%A7)
  - [9. 安全基线](#9-%E5%AE%89%E5%85%A8%E5%9F%BA%E7%BA%BF)
  - [10. 备份与恢复](#10-%E5%A4%87%E4%BB%BD%E4%B8%8E%E6%81%A2%E5%A4%8D)
  - [11. 运维常用清单（Cheat Sheet）](#11-%E8%BF%90%E7%BB%B4%E5%B8%B8%E7%94%A8%E6%B8%85%E5%8D%95cheat-sheet)
  - [12. 变更记录（Changelog）](#12-%E5%8F%98%E6%9B%B4%E8%AE%B0%E5%BD%95changelog)
  - [13. 待办（Next Actions）](#13-%E5%BE%85%E5%8A%9Enext-actions)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# CloudChat 服务器配置运行手册（模板）

> 适用：Ubuntu 24.04（小内存 1 GiB 级别），Nginx + Flask（Gunicorn/ gevent）+ Redis；**规划**引入 PgBouncer + PostgreSQL。&#x20;
>
> 本文档用于**记录当前配置**、**目标配置**与**变更记录**，并作为运维 Runbook。

---

## 0. 概览（Overview）

* **主机名**：`iZj6c1i25mt610l0q2g2amZ`
* **云厂商 / 地域**：`阿里云 / cn-hongkong`
* **CPU / 内存 / 磁盘**：`2vCPU / 690M / 40G`
* **操作系统**：Ubuntu Server 24.04 LTS
* **时区 / NTP**：`<Asia/Shanghai>` / `chrony`
* **交换空间（Swap）**：启用，大小 **2 GiB**
* **当前内存快照**（引入 PgBouncer + PostgreSQL 前的执行时记录）：

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
┌─────┐     HTTPS      ┌──────────────────┐
│ Client   │ ──────▶ │ Nginx (reverse proxy, same domain) │
└─────┘                └─────┬────────────┘
                                          │ /cloudchat/
                          ┌───────▼──────────────┐
                          │ CloudChat API│  Flask + Gunicorn(gevent)  │
                          └───────┬──────────────┘
                                          │ sessions/limits
                          ┌───────▼─────────┐
                          │   Redis      │  (会话/限流/队列)│
                          └─────────────────┘

[已部署] 认证/业务数据： CloudChat → PgBouncer → PostgreSQL
```

* **域名 / 站点**：`https://www.rendazhang.com`
* **TLS 证书**：`issuer=C = US, O = Let's Encrypt, CN = E6`（自动续期工具：`certbot`）
* **认证模型**：同域 **Cookie 会话**（HttpOnly/ Secure/ SameSite=Lax）

---

## 2. 服务与资源预算（systemd + OOM）

> 目标：在 1 GiB 主机上保持稳定，数据库“保命”，应用可自愈。

| 服务                                | 当前 OOMScoreAdjust | 当前 MemoryMax | 目标 OOMScoreAdjust | 目标 MemoryMax | 备注        |   |
| --------------------------------- | ----------------- | ------------ | ----------------- | ------------ | --------- | - |
| **nginx**                         | **-200**          | *(未显式限制)*    | -200              | 128M（可选）     | 反代/静态     |   |
| **redis-server**                  | **-100**          | **160M**     | -200              | 160–192M     | 会话/限流/队列  |   |
| **cloudchat**（Gunicorn 2 workers） | **+100**          | **300M**     | +100（易被杀）         | 300M         | 无状态，可自动重启 |   |
| **pgbouncer**                     | **-200**          | **64M**      | -200              | 64M          | 事务级连接池    |   |
| **postgresql**                    | **-500**          | **260M**     | **-500**（保命）      | 260M         | 精简配置      |   |

> ✅ 上表“当前”列已根据 Step 1–3 生效配置更新；如与实际不符请以 `systemctl show` 与配置文件为准。

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
  MemoryMax=160M
  ```
* **配置文件**：`/etc/redis/redis.conf`

  * 建议：

    ```
    bind 127.0.0.1
    protected-mode yes
    requirepass <REDIS_PASSWORD>

    # 与 systemd MemoryMax 对齐
    maxmemory 160mb
    maxmemory-policy allkeys-lru

    # 关闭持久化（作为会话/限流用）
    save ""
    appendonly no
    activerehashing yes

    # 连接与空闲
    tcp-backlog 128
    timeout 0

    # 若需持久化：改用 appendonly yes + appendfsync everysec，并适当上调 maxmemory 与磁盘监控。
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
  EnvironmentFile=/etc/cloudchat/cloudchat.env
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

  OOMScoreAdjust=100
  MemoryMax=300M

  [Install]
  WantedBy=multi-user.target
  ```
* **环境变量文件**：`/etc/cloudchat/cloudchat.env`（**权限 600**）

  ```
  PATH=/opt/cloudchat/venv/bin
  OPENAI_API_KEY=***
  DEEPSEEK_API_KEY=***
  DASHSCOPE_API_KEY=***
  FLASK_SECRET_KEY=***
  REDIS_PASSWORD=***
  DATABASE_URL=postgresql+psycopg://cloudchat:***@127.0.0.1:6432/cloudchat
  ```

  > 注：实际环境文件已写入真实密码；文档中以 `***` 遮蔽。
* ⚠️ 已将密钥从 systemd 单元迁移至独立文件；建议轮换曾明文出现的旧密钥。
* **绑定端口**：`0.0.0.0:5000`（Nginx 反代）
* **健康检查**：`GET /cloudchat/healthz`（建议添加）

---

## 6. 数据库（已部署）

### 6.1 PostgreSQL（精简配置）

* **软件**：`postgresql` `postgresql-contrib`
* **配置**：`/etc/postgresql/16/main/postgresql.conf`

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
* **迁移策略**：SQLAlchemy Alembic（记录 versions/ 与 alembic.ini）

### 6.2 PgBouncer（连接池）

* **配置**：`/etc/pgbouncer/pgbouncer.ini`

  ```ini
  [databases]
  cloudchat = host=localhost port=5432 dbname=cloudchat user=cloudchat password=***

  [pgbouncer]
  logfile = /var/log/postgresql/pgbouncer.log
  listen_addr = localhost
  listen_port = 6432
  auth_type = md5
  auth_file = /etc/pgbouncer/userlist.txt
  pool_mode = transaction
  ignore_startup_parameters = extra_float_digits
  max_client_conn = 200
  default_pool_size = 10
  reserve_pool_size = 5
  ```

* **systemd override**：

  ```ini
  [Service]
  OOMScoreAdjust=-200
  MemoryMax=64M
  ```

* auth_file 提示：创建 /etc/pgbouncer/userlist.txt（权限 600），示例："cloudchat" "md5\<hashed\_password>"（或改用 auth_query 从数据库读取凭据）

* **应用连接串**：`postgresql+psycopg://cloudchat:***@127.0.0.1:6432/cloudchat`

* **SQLAlchemy 池参数**：`pool_size=5, max_overflow=0, pool_recycle=1800, pool_pre_ping=True`

* **认证文件与验证（已完成）**：

  * `auth_type = md5`，`userlist.txt` 由 `"md5" + md5(<密码><用户名>)` 生成；并设置 `admin_users = cloudchat`
  * `userlist.txt` 权限 600，属主 `postgres:postgres`
  * 验证：

    ```bash
    systemctl restart pgbouncer
    psql -h 127.0.0.1 -p 6432 -U cloudchat -d cloudchat -c "select 1;"
    psql -h 127.0.0.1 -p 6432 -U cloudchat pgbouncer -c "show pools;"
    # 期望：cloudchat 池为 transaction 模式，sv_idle >= 0，sv_used/active 正常
    ```

---

### 6.3 验收与检查（本次）

* 连接数（应小于 `max_connections=20`）：

  ```sql
  select count(*) from pg_stat_activity;  -- 结果示例：6
  ```
* 资源观察：`systemd-cgtop`、`journalctl -u *`、`free -h`、`vmstat 1`

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

| 日期         | 变更内容                                                          | 服务           | 版本/提交 | 操作人 | 回滚方式                |
| ---------- | ------------------------------------------------------------- | ------------ | ----- | --- | ------------------- |
| 2025-08-12 | Redis 限额至 160M，关闭 RDB/AOF；优化 conf（allkeys-lru 等）              | redis-server |       |     | 还原 conf 与 MemoryMax |
| 2025-08-12 | CloudChat 改用 EnvironmentFile，OOM=+100，MemoryMax=300M          | cloudchat    |       |     | 还原 systemd 单元并重启    |
| 2025-08-12 | 安装并配置 PostgreSQL（shared_buffers=96MB 等精简参数）                  | postgresql   | 16    |     | 停止服务/还原配置           |
| 2025-08-12 | 创建数据库与最小权限账号（cloudchat）                                       | postgresql   |       |     | 删除角色/库              |
| 2025-08-12 | 安装并配置 PgBouncer（transaction 池，MemoryMax=64M）                  | pgbouncer    |       |     | 停止服务/回退应用连接串        |
| 2025-08-12 | **写入 PgBouncer userlist（md5）并启用 admin_users；连通性与 pools 验证**  | pgbouncer    |       |     | 移除 userlist/还原配置    |
| 2025-08-12 | **新增 `DATABASE_URL` 到 EnvironmentFile**                       | cloudchat    |       |     | 移除该行并重启             |
| 2025-08-12 | **安装依赖：psycopg2-binary / SQLAlchemy / Alembic / argon2-cffi** | cloudchat    |       |     | 卸载依赖或回滚 venv        |
| 2025-08-12 | **创建 `db.py` 与 `models.py`（users/credentials/sessions）**      | cloudchat    |       |     | 删除文件/回滚提交           |

---

## 13. 待办（Next Actions）

* [ ] 初始化 Alembic 迁移仓库（`alembic init`）并生成首个迁移（基于 `models.py`）
* [ ] 执行 `alembic upgrade head` 建表（users / credentials / sessions）
* [ ] 实现后端认证路由：`POST /cloudchat/auth/register`、`POST /cloudchat/auth/login`、`POST /cloudchat/auth/logout`、`GET /cloudchat/me`
* [ ] 将注册/登录逻辑接入数据库（Argon2id 哈希；会话仍走 Redis）
* [ ] 前端登录/注册页面接入真实 API（同域、`credentials: include`）
* [ ] 为 API 暴露 `/cloudchat/healthz` 健康检查（含依赖探测：Redis/DB）
* [ ] 为 PostgreSQL 配置每日 `pg_dump` 备份与保留策略
* [ ] 监控：为 `pgbouncer.log` 与 PostgreSQL 日志添加告警阈值
* [ ] 轮换在会话中曾明文出现过的密钥（OPENAI/DEEPSEEK/DASHSCOPE/FLASK/REDIS）
* [ ] 更新本文档所有“<…>”占位信息并入库存档
