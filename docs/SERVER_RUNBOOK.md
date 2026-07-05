<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [服务器配置运行手册](#%E6%9C%8D%E5%8A%A1%E5%99%A8%E9%85%8D%E7%BD%AE%E8%BF%90%E8%A1%8C%E6%89%8B%E5%86%8C)
  - [概览](#%E6%A6%82%E8%A7%88)
  - [架构](#%E6%9E%B6%E6%9E%84)
  - [服务与资源预算](#%E6%9C%8D%E5%8A%A1%E4%B8%8E%E8%B5%84%E6%BA%90%E9%A2%84%E7%AE%97)
  - [Nginx](#nginx)
  - [Redis](#redis)
  - [CloudChat 后端 API](#cloudchat-%E5%90%8E%E7%AB%AF-api)
  - [数据库](#%E6%95%B0%E6%8D%AE%E5%BA%93)
    - [PostgreSQL 精简配置](#postgresql-%E7%B2%BE%E7%AE%80%E9%85%8D%E7%BD%AE)
    - [PgBouncer 连接池](#pgbouncer-%E8%BF%9E%E6%8E%A5%E6%B1%A0)
    - [验收与检查](#%E9%AA%8C%E6%94%B6%E4%B8%8E%E6%A3%80%E6%9F%A5)
    - [建表](#%E5%BB%BA%E8%A1%A8)
    - [后端认证](#%E5%90%8E%E7%AB%AF%E8%AE%A4%E8%AF%81)
    - [密码找回与重置](#%E5%AF%86%E7%A0%81%E6%89%BE%E5%9B%9E%E4%B8%8E%E9%87%8D%E7%BD%AE)
    - [生产邮件发送](#%E7%94%9F%E4%BA%A7%E9%82%AE%E4%BB%B6%E5%8F%91%E9%80%81)
    - [后端接口清单与契约](#%E5%90%8E%E7%AB%AF%E6%8E%A5%E5%8F%A3%E6%B8%85%E5%8D%95%E4%B8%8E%E5%A5%91%E7%BA%A6)
  - [Nginx 站点与 API 路由](#nginx-%E7%AB%99%E7%82%B9%E4%B8%8E-api-%E8%B7%AF%E7%94%B1)
  - [日志与监控](#%E6%97%A5%E5%BF%97%E4%B8%8E%E7%9B%91%E6%8E%A7)
  - [安全基线](#%E5%AE%89%E5%85%A8%E5%9F%BA%E7%BA%BF)
  - [备份与恢复](#%E5%A4%87%E4%BB%BD%E4%B8%8E%E6%81%A2%E5%A4%8D)
  - [运维常用清单](#%E8%BF%90%E7%BB%B4%E5%B8%B8%E7%94%A8%E6%B8%85%E5%8D%95)
    - [Nginx 安全与缓存验收](#nginx-%E5%AE%89%E5%85%A8%E4%B8%8E%E7%BC%93%E5%AD%98%E9%AA%8C%E6%94%B6)
  - [变更记录](#%E5%8F%98%E6%9B%B4%E8%AE%B0%E5%BD%95)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 服务器配置运行手册

- **作者**: 张人大 (Renda Zhang)
- **最后更新**: July 05, 2026, 14:48 (UTC+08:00)

---

## 概览

> 适用：Ubuntu 24.04（小内存 1 GiB 级别），Nginx + Flask（Gunicorn/ gevent）+ Redis；**规划**引入 PgBouncer + PostgreSQL。&#x20;
>
> 本文档用于**记录当前配置**、**目标配置**与**变更记录**，并作为运维 Runbook。

- **主机名**：`iZj6c1i25mt610l0q2g2amZ`
- **云厂商 / 地域**：`阿里云 / cn-hongkong`
- **CPU / 内存 / 磁盘**：`2vCPU / 690M / 40G`
- **操作系统**：Ubuntu Server 24.04 LTS
- **时区 / NTP**：`<Asia/Shanghai>` / `chrony`
- **交换空间（Swap）**：启用，大小 **2 GiB**
- **内存快照**
  - 引入 PgBouncer + PostgreSQL 前的记录：
    ```bash
    Mem:  total 690Mi | used 357Mi | free 88Mi | buff/cache 362Mi | available 333Mi
    Swap: total 2.0Gi | used 198Mi | free 1.8Gi
    ```
  - 引入完成并调整了 systemd 配置后的记录：
    ```bash
    Mem:  total 690Mi | used 448Mi | free 47Mi | buff/cache 315Mi | available 242Mi
    Swap: total 2.0Gi | used 99Mi | free 1.9Gi
    ```
- **系统精简与优化**：
  - journald **日志大小/生存时间限制**
  - **内核参数**调优（sysctl）
  - **轻量化组件替换**以降低常驻内存

> ✅ 上述条目请在部署/变更后更新为**实值**；所有配置文件路径推荐附上 `ls -l` 的时间与权限。

---

## 架构

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

- **域名 / 站点**：`https://www.rendazhang.com`
- **TLS 证书**：Let's Encrypt ECDSA 证书（自动续期工具：`certbot`）
- **认证模型**：同域 **Cookie 会话**（HttpOnly/ Secure/ SameSite=Lax）

---

## 服务与资源预算

systemd + OOM

> 目标：在 1 GiB 主机上保持稳定，数据库“保命”，应用可自愈。

| 服务                                | 当前 OOMScoreAdjust | 当前 MemoryMax | 目标 OOMScoreAdjust | 目标 MemoryMax | 备注        |   |
| --------------------------------- | ----------------- | ------------ | ----------------- | ------------ | --------- | - |
| **nginx**                         | **-200**          | *(未显式限制)*    | -200              | 128M（可选）     | 反代/静态     |   |
| **redis-server**                  | **-100**          | **160M**     | -200              | 160–192M     | 会话/限流/队列  |   |
| **cloudchat**（Gunicorn 2 workers） | **+100**          | **300M**     | +100（易被杀）         | 300M         | 无状态，可自动重启 |   |
| **pgbouncer**                     | **-200**          | **64M**      | -200              | 64M          | 事务级连接池    |   |
| **postgresql**                    | **-500**          | **260M**     | **-500**（保命）      | 260M         | 精简配置      |   |

## Nginx

- **systemd override**：`/etc/systemd/system/nginx.service.d/override.conf`
  ```ini
  [Service]
  OOMScoreAdjust=-200
  ```
- **主配置**：`/etc/nginx/nginx.conf`
- **站点配置**：`/etc/nginx/sites-available/<site>`（链接至 `sites-enabled/`）
- **反代要点**：
  - 统一前缀：`/cloudchat/` → 后端 `127.0.0.1:5000`
  - 关闭对 API 的缓存；开启 `proxy_http_version 1.1` 与必要的头传递
- **TLS**：`/etc/letsencrypt/live/rendazhang.com/{fullchain.pem,privkey.pem}`；自动续期任务：`certbot.timer`
- **TLS 1.2 兼容性**：当前证书为 ECDSA，`ssl_ciphers` 必须包含 `ECDHE-ECDSA-*`；TLS 1.3 cipher 不由 `ssl_ciphers` 控制。
- **安全头**：通过 `snippets/security-headers.conf` 统一维护。凡是 location 内声明了 `add_header`，都要显式 include 该 snippet。
- **CSP inline hash**：当前 Astro 7 静态前端构建的可执行 inline scripts 由 `script-src` SHA-256 hash allowlist 放行，不启用 `unsafe-inline`；`/deepseek_chat/` iframe 嵌入标记由外部同源脚本 `/js/deepseek-embed.js` 处理。前端重新构建、升级 Astro、调整 hydration 指令或新增 inline script 后，要复核浏览器 CSP console 和 Nginx hash allowlist。
- **CSP frame policy**：首页 Chat Widget 依赖同源 iframe 加载 `/deepseek_chat/`，Credly 证书依赖 `https://www.credly.com`；`frame-src` 必须保留 `'self' https://www.credly.com`，`frame-ancestors` 必须保留 `'self'`。
- **Canonical host**：`rendazhang.com` 与所有 HTTP 请求统一 301 到 `https://www.rendazhang.com$request_uri`。
- **静态缓存**：`location ^~ /_astro/` 返回一年 immutable 缓存；通用静态资源返回 30 天 immutable 缓存。
- **敏感路径**：隐藏文件默认 404，保留 `/.well-known/` 标准路径。
- **黑名单文件**：`/etc/nginx/ip-blacklist.conf` 是服务器本地运行态配置，已加入 `.gitignore`，不得通过 Git 发布覆盖。
- **配置发布**：本地提交并 push 后，服务器在 `/etc/nginx` 执行 `git pull --ff-only`；禁止直接同步整个 `/etc/nginx`。
- **常用命令**：
  ```bash
  cd /etc/nginx && git pull --ff-only
  sudo nginx -t && sudo systemctl reload nginx
  journalctl -u nginx -e --no-pager
  ```

> 关键 `server {}` 段落示例（域名/IP 已脱敏）：
> ```nginx
> server {
>     listen 443 ssl http2;
>     server_name www.example.com example.com;
>
>     root /var/www/html;
>     index index.html;
>
>     include snippets/ssl-rendazhang.conf;
>     include snippets/security-headers.conf;
>
>     location /cloudchat/ { ... }  # 详见下文
> }
> ```
>
> 上述示例仅展示核心配置，完整文件位于 `/etc/nginx/sites-available/<site>`。

---

## Redis

- **systemd override**：`/etc/systemd/system/redis-server.service.d/override.conf`
  ```ini
  [Service]
  OOMScoreAdjust=-100
  MemoryMax=160M
  ```
- **配置文件**：`/etc/redis/redis.conf`
  - 建议：
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
- **用途**：会话、限流、短期队列
- **检查**：
  ```bash
  redis-cli INFO memory | egrep 'used_memory_human|maxmemory'
  ```

---

## CloudChat 后端 API

- **systemd 单元**：`/etc/systemd/system/cloudchat.service`
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
- **环境变量文件**：`/etc/cloudchat/cloudchat.env`（**权限 600**）
  ```
  PATH=/opt/cloudchat/venv/bin
  OPENAI_API_KEY=***
  DEEPSEEK_API_KEY=***
  DASHSCOPE_API_KEY=***
  FLASK_SECRET_KEY=***
  REDIS_PASSWORD=***
  DATABASE_URL=postgresql+psycopg2://cloudchat:***@127.0.0.1:6432/cloudchat
  AUTH_COOKIE_NAME=cc_auth
  APP_SESSION_COOKIE_NAME=cc_app

  # 密码找回/重置
  PWRESET_TOKEN_TTL=900
  DEBUG_RETURN_RESET_TOKEN=0
  PWRESET_REVOKE_SESSIONS=1

  # DirectMail SMTP（已启用）
  SMTP_HOST=smtpdm-ap-southeast-1.aliyuncs.com
  SMTP_PORT=80
  SMTP_USER=noreply@mail.rendazhang.com
  SMTP_PASS=***
  SMTP_TLS=1
  MAIL_FROM=noreply@mail.rendazhang.com
  MAIL_SENDER_NAME=CloudChat
  FRONTEND_BASE_URL=https://www.rendazhang.com
  ```
  > 注：实际环境文件已写入真实密码；文档中以 `***` 遮蔽。
- **绑定端口**：`0.0.0.0:5000`（Nginx 反代）
- **健康检查**：`GET /cloudchat/auth/healthz`（已实现，探测 Redis + PostgreSQL）

---

## 数据库

### PostgreSQL 精简配置

- **软件**：`postgresql` `postgresql-contrib`
- **配置**：`/etc/postgresql/16/main/postgresql.conf`
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
- **systemd override**（保命）：`systemctl edit postgresql`
  ```ini
  [Service]
  OOMScoreAdjust=-500
  MemoryMax=260M
  ```
- **网络访问**：仅本机（`pg_hba.conf` 允许 `local`/`127.0.0.1`）
- **账号/库**（最小权限）：
  ```sql
  CREATE ROLE cloudchat LOGIN PASSWORD '***' NOSUPERUSER NOCREATEDB NOCREATEROLE;
  CREATE DATABASE cloudchat OWNER cloudchat;
  ```
- **迁移策略**：SQLAlchemy Alembic（记录 versions/ 与 alembic.ini）

### PgBouncer 连接池

- **配置**：`/etc/pgbouncer/pgbouncer.ini`
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
- **systemd override**：
  ```ini
  [Service]
  OOMScoreAdjust=-200
  MemoryMax=64M
  ```
- auth_file 提示：创建 /etc/pgbouncer/userlist.txt（权限 600），示例："cloudchat" "md5\<hashed\_password>"（或改用 auth\_query 从数据库读取凭据）
- **应用连接串**：`postgresql+psycopg://cloudchat:***@127.0.0.1:6432/cloudchat`
- **SQLAlchemy 池参数**：`pool_size=5, max_overflow=0, pool_recycle=1800, pool_pre_ping=True`
- **认证文件与验证（已完成）**：
  - `auth_type = md5`，`userlist.txt` 由 `"md5" + md5(<密码><用户名>)` 生成；并设置 `admin_users = cloudchat`
  - `userlist.txt` 权限 600，属主 `postgres:postgres`
  - 验证：
    ```bash
    systemctl restart pgbouncer
    psql -h 127.0.0.1 -p 6432 -U cloudchat -d cloudchat -c "select 1;"
    psql -h 127.0.0.1 -p 6432 -U cloudchat pgbouncer -c "show pools;"
    # 期望：cloudchat 池为 transaction 模式，sv_idle >= 0，sv_used/active 正常
    ```

### 验收与检查

- 连接数（应小于 `max_connections=20`）：

  ```sql
  select count(*) from pg_stat_activity;  -- 结果示例：6
  ```
- 资源观察：`systemd-cgtop`、`journalctl -u *`、`free -h`、`vmstat 1`

### 建表

直接建表 - 无历史迁移

- **驱动与 DSN 对齐**：已将 `DATABASE_URL` 切换为 `postgresql+psycopg2://...` 并重启 `cloudchat`。
- **Schema 文件**：`/opt/cloudchat/schema.sql`
- **建表命令**：

  ```bash
  psql -h 127.0.0.1 -p 6432 -U cloudchat -d cloudchat -f /opt/cloudchat/schema.sql
  ```
- **结果**：已创建三张表 `users`、`credentials`、`sessions`。
- **关键索引/约束**：

  - `credentials`: `idx_credentials_user_type_one`（每用户本地凭据唯一）、`idx_credentials_oauth_unique`（第三方唯一）；`type` 检查约束；`user_id` 外键 `ON DELETE CASCADE`
  - `users`: `uid/email/phone` 唯一；`idx_users_email_ci`（lower(email) 检索）
  - `sessions`: `session_id` 唯一；`idx_sessions_user`、`idx_sessions_expires`
- **冒烟插入**：已插入 `users(uid='smoke-0001', email='smoke@test.local')` 并成功查询到记录。

### 后端认证

- **应用路由前缀**：`/auth`（Blueprint）；经 Nginx 统一前缀 `/cloudchat/` 反代后，对外为 **`/cloudchat/auth/*`**。
- **已实现端点**：
  - `POST /cloudchat/auth/register`
  - `POST /cloudchat/auth/login`
  - `POST /cloudchat/auth/logout`
  - `GET  /cloudchat/auth/me`
  - `GET  /cloudchat/auth/healthz`
- **会话 Cookie**：
  - 名称：`cc_auth`（可通过环境变量 `AUTH_COOKIE_NAME` 配置；默认 `cc_auth`）。
  - 属性：`HttpOnly; SameSite=Lax; Secure=<由 COOKIE_SECURE 控制>`，`Max-Age=<SESSION_TTL_SECONDS 默认 604800>`；`Path=/`。
- **限速**：：登录按 *IP* 与 *identifier* 双维度，`10/10min`（Redis 计数）。
- **依赖**：Redis（会话与限速）。
- **验证结果**：已完成端到端注册/登录/登出/鉴权，本地（Ubuntu）与外网域名均通过；重复注册返回 `409`。

### 密码找回与重置

- **端点**：
  - `POST /cloudchat/auth/password/forgot`（统一返回 200，防枚举；开发期可返回 `debug_token`）
  - `POST /cloudchat/auth/password/reset`（一次性 token 校验 + 更新密码）
- **实现**：Redis 存储一次性 token（键：`pwreset:<token>`），默认 **TTL 900s**；重置成功后可选**强制下线**。
- **会话强制下线（简单版）**：扫描 `sess:*`，删除属于该用户的所有会话；接口返回 `revoked_sessions` 计数（本次验证示例：`7`）。
- **限速**：`forgot` 按 IP **20/小时**、按 identifier **5/小时**。
- **配置**：

  - `PWRESET_TOKEN_TTL`（默认 `900`）
  - `DEBUG_RETURN_RESET_TOKEN`（开发 `1` / 生产 `0`）
  - `PWRESET_REVOKE_SESSIONS`（是否在重置后强制下线，默认 `1`）
- **邮件**：已提供 `mailer.py` 适配器；生产时将 `DEBUG_RETURN_RESET_TOKEN=0`，并配置 `SMTP_*`、`MAIL_FROM`、`FRONTEND_BASE_URL`（重置链接示例：`https://<域名>/cloudchat/reset-password?token=...`）。

### 生产邮件发送

已启用：Aliyun DirectMail

- **发送方式**：后端通过 `mailer.py` 使用 SMTP（推荐 STARTTLS/80，或 SSL/465）。
- **所需环境变量**（`/etc/cloudchat/cloudchat.env`）：
  - `SMTP_HOST`、`SMTP_PORT`、`SMTP_USER`、`SMTP_PASS`、`SMTP_TLS`
  - `MAIL_FROM`、`MAIL_SENDER_NAME`
  - `FRONTEND_BASE_URL`
  - `DEBUG_RETURN_RESET_TOKEN=0`（生产关闭返回 token）
- **DirectMail 区域入口**：
  - 新加坡：`smtpdm-ap-southeast-1.aliyuncs.com`（建议端口 **80** + STARTTLS）
  - 杭州（中国内地）：`smtpdm.aliyun.com`（若在内地网络）
- **DNS（已完成）**：TXT 所有权、SPF、MX、跟踪 CNAME、DKIM、DMARC 已配置并通过验证。
- **验证结果**：`/cloudchat/auth/password/forgot` 触发后，收件箱已收到带重置链接（15 分钟有效）的邮件。
- **回滚**：把 `DEBUG_RETURN_RESET_TOKEN=1`，注释 `SMTP_*`，重启 `cloudchat`。

### 后端接口清单与契约

> 统一前缀：对内 `/auth/*`；对外经 Nginx 为 `/cloudchat/auth/*`

| Endpoint                          | 方法   | 请求体（必填字段）                                     | 典型响应                                      | 可能状态码         | 备注                                               |
| --------------------------------- | ---- | --------------------------------------------- | ----------------------------------------- | ------------- | ------------------------------------------------ |
| `/cloudchat/auth/register`        | POST | `{ email?, phone?, password, display_name? }` | `{ ok:true }`                             | 201, 400, 409 | email/phone 至少一项；弱口令 400；重复 409                  |
| `/cloudchat/auth/login`           | POST | `{ identifier, password }`                    | `{ ok:true }` + `Set-Cookie: cc_auth=...` | 200, 401      | 防枚举：失败统一 401；限速 `10/10min`（IP+账号）                |
| `/cloudchat/auth/logout`          | POST | -                                             | `{ ok:true }` + 清空 `cc_auth`              | 200           | 幂等                                               |
| `/cloudchat/auth/me`              | GET  | Cookie `cc_auth`                              | `{ ok:true, user:{...} }`                 | 200, 401      | 用户字段：id/uid/email/phone/display\_name/is\_active |
| `/cloudchat/auth/password/forgot` | POST | `{ identifier }`                              | `{ ok:true }`                             | 200           | 生产不返回 token；限速：IP 20/h、identifier 5/h            |
| `/cloudchat/auth/password/reset`  | POST | `{ token, password }`                         | `{ ok:true, revoked_sessions:n }`         | 200, 400      | 一次性 token；重置后会话强制下线（简单版）                         |
| `/cloudchat/auth/healthz`         | GET  | -                                             | `{ ok:true }`                             | 200/503       | 依赖探测（Redis + PostgreSQL）                       |

- **Cookie**：`cc_auth`（认证，会话 Redis 保存 `sess:<sid> -> user_id`，`Max-Age=604800`，`HttpOnly; SameSite=Lax; Secure=<按环境>`）；`cc_app`（Flask-Session）。
- **错误格式**：`{ ok:false, error:"..." }`。
- **跨域/凭据**：同域部署，前端请求需携带 `credentials: 'include'`。

---

## Nginx 站点与 API 路由

- **前端前缀**：`/cloudchat/`
- **后端路由**（示例）：

  - `POST /cloudchat/auth/register`
  - `POST /cloudchat/auth/login`
  - `POST /cloudchat/auth/logout`
  - `GET  /cloudchat/auth/me`
  - `GET  /cloudchat/auth/healthz`
  - `POST /cloudchat/auth/password/forgot`
  - `POST /cloudchat/auth/password/reset`
- **静态/缓存策略**：`<static rules>`

> `location /cloudchat/` 核心反代配置示例：
> ```nginx
> location /cloudchat/ {
>     limit_req zone=flask_limit burst=10 nodelay;
>
>     proxy_cache cloudchat_cache;
>     proxy_cache_valid 200 302 10m;
>     proxy_cache_valid 404      1m;
>     proxy_cache_bypass $do_not_cache;
>     proxy_no_cache $do_not_cache;
>
>     proxy_pass http://127.0.0.1:5000/;
>     proxy_http_version 1.1;
>     proxy_set_header Host $host;
>     proxy_set_header X-Real-IP $remote_addr;
>     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
> }
> ```
>
> 可根据应用路径与缓存策略灵活调整以上参数。

---

## 日志与监控

- **journald**：大小与保留期限制：`<e.g. SystemMaxUse=..., MaxFileSec=...>`
- **Nginx**：`/var/log/nginx/access.log`, `error.log`
- **CloudChat**：`journalctl -u cloudchat`（或 `gunicorn` 文件日志）
- **Redis**：`/var/log/redis/redis-server.log`
- **PostgreSQL**（规划）：`/var/log/postgresql/postgresql-<ver>-main.log`
- **基础监控**：

  ```bash
  systemd-cgtop
  free -h; vmstat 1 5; iostat -xz 1 3
  ```

---

## 安全基线

- **防火墙**：开放 80/443/22；PostgreSQL/ PgBouncer 仅本机
- **SSH 加固**：禁用 root 直登（或强制密钥）、`PasswordAuthentication no`
- **Secrets 管理**：全部转至 `/etc/cloudchat/cloudchat.env`（0600）
- **TLS**：自动续期成功率监控与失败告警

---

## 备份与恢复

- **PostgreSQL**：每日 `pg_dump`（保留 7–14 天），每周全量，每日增量（如用 `wal-g` 可选）
- **配置备份**：`/etc`、`/opt/cloudchat` 关键文件纳入 Git/压缩包
- **恢复演练**：季度至少一次，从备份恢复到隔离环境并通过健康检查

---

## 运维常用清单

```bash
# 检查服务
systemctl status nginx redis-server cloudchat pgbouncer postgresql --no-pager

# 在线变更与重载
cd /etc/nginx && git pull --ff-only
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

### Nginx 安全与缓存验收

```bash
# TLS 1.2 / TLS 1.3 都应成功
echo | openssl s_client -connect 127.0.0.1:443 -servername www.rendazhang.com -tls1_2 -brief
echo | openssl s_client -connect 127.0.0.1:443 -servername www.rendazhang.com -tls1_3 -brief

# 静态页面、XML/JSON、指纹资源都应带安全头
curl -k -I --resolve www.rendazhang.com:443:127.0.0.1 https://www.rendazhang.com/
curl -k -I --resolve www.rendazhang.com:443:127.0.0.1 https://www.rendazhang.com/sitemap.xml
curl -k -I --resolve www.rendazhang.com:443:127.0.0.1 https://www.rendazhang.com/llms.txt
curl -k -I --resolve www.rendazhang.com:443:127.0.0.1 https://www.rendazhang.com/_astro/chat_widget.CudJCDys.css

# 敏感路径和未知静态路径应为 404；apex 应 301 到 www
curl -k -I --resolve www.rendazhang.com:443:127.0.0.1 https://www.rendazhang.com/.env
curl -k -I --resolve www.rendazhang.com:443:127.0.0.1 https://www.rendazhang.com/definitely-not-real
curl -k -I --resolve www.rendazhang.com:443:127.0.0.1 https://www.rendazhang.com/manifest.webmanifest
curl -k -I --resolve rendazhang.com:443:127.0.0.1 https://rendazhang.com/
```

---

## 变更记录

| 日期         | 变更内容                                                                                                          | 服务           | 版本/提交     | 操作人 | 回滚方式                |                     |
| ---------- | ------------------------------------------------------------------------------------------------------------- | ------------ | --------- | --- | ------------------- | ------------------- |
| 2025-08-12 | Redis 限额至 160M，关闭 RDB/AOF；优化 conf（allkeys-lru 等）                                                              | redis-server |           |     | 还原 conf 与 MemoryMax |                     |
| 2025-08-12 | CloudChat 改用 EnvironmentFile，OOM=+100，MemoryMax=300M                                                          | cloudchat    |           |     | 还原 systemd 单元并重启    |                     |
| 2025-08-12 | 安装并配置 PostgreSQL（shared\_buffers=96MB 等精简参数）                                                                  | postgresql   | 16        |     | 停止服务/还原配置           |                     |
| 2025-08-12 | 创建数据库与最小权限账号（cloudchat）                                                                                       | postgresql   |           |     | 删除角色/库              |                     |
| 2025-08-12 | 安装并配置 PgBouncer（transaction 池，MemoryMax=64M）                                                                  | pgbouncer    |           |     | 停止服务/回退应用连接串        |                     |
| 2025-08-12 | 写入 PgBouncer userlist（md5）并启用 admin\_users；连通性与 pools 验证                                                      | pgbouncer    |           |     | 移除 userlist/还原配置    |                     |
| 2025-08-12 | 新增 `DATABASE_URL` 到 EnvironmentFile（指向 PgBouncer 6432）                                                        | cloudchat    |           |     | 移除该行并重启             |                     |
| 2025-08-12 | 安装依赖：psycopg2-binary / SQLAlchemy / Alembic / argon2-cffi                                                     | cloudchat    |           |     | 卸载依赖或回滚 venv        |                     |
| 2025-08-12 | 创建 `db.py` 与 `models.py`（users/credentials/sessions）                                                          | cloudchat    |           |     | 删除文件/回滚提交           |                     |
| 2025-08-12 | 对齐驱动与 DSN（psycopg2）并重启 cloudchat                                                                              | cloudchat    |           |     | 还原 DSN 并重启          |                     |
| 2025-08-12 | 执行 schema.sql 建表并验证三表与索引；完成一次冒烟插入测试                                                                           | postgresql   |           |     | 回滚：DROP TABLE ...   |                     |
| 2025-08-12 | 部署认证 Blueprint（/auth 前缀；对外 /cloudchat/auth）并完成端到端注册/登录/登出/鉴权测试                                                | cloudchat    |           |     | 回滚：禁用蓝图路由/还原代码      |                     |
| 2025-08-12 | 为本地测试设置 COOKIE\_SECURE=0；线上保持 COOKIE\_SECURE=1（Secure Cookie）                                                 | cloudchat    |           |     | 还原/调整环境变量并重启        |                     |
| 2025-08-13 | Cookie 命名冲突消解：认证 Cookie 改为 `cc_auth`；Flask-Session Cookie `cc_app`                                            | cloudchat    |           |     | 恢复旧名并重启             |                     |
| 2025-08-13 | 部署密码找回与重置（Redis token，TTL=900s；接口 \`/auth/password/forgot                                                     | reset\`）     | cloudchat |     |                     | 移除路由/清理 Redis token |
| 2025-08-13 | 启用重置后会话强制下线（简单版）扫描 `sess:*`；本次验证 `revoked_sessions=7`                                                         | cloudchat    |           |     | 关闭功能位或恢复旧逻辑         |                     |
| 2025-08-13 | DirectMail SMTP 上线（新加坡入口 `smtpdm-ap-southeast-1.aliyuncs.com:80` + STARTTLS；`DEBUG_RETURN_RESET_TOKEN=0`） | cloudchat    |           |     | 关闭 SMTP 或回滚到调试模式    |                     |
| 2025-08-13 | 为 `/auth/register` 增加 IP(10/小时) 和 Email(3/小时) 限速，防止撞库滥用                                             | cloudchat    |           |     | 移除限速配置并重启服务      |                     |
| 2025-08-13 | 统一注册/重置密码复杂度校验（≥8 且至少 2 类字符：字母/数字/特殊）                                                     | cloudchat    |           |     | 恢复旧校验逻辑或删除代码     |                     |
| 2025-08-13 | `/auth/healthz` 接口新增 PostgreSQL 健康探测（`select 1`）                                                         | cloudchat    |           |     | 移除 PostgreSQL 检查并重启  |                     |
| 2025-08-13 | 登录成功后通过 `ph.check_needs_rehash()` 后台平滑升级 Argon2 哈希                                                   | cloudchat    |           |     | 停用后台更新或回滚代码       |                     |
| 2025-08-13 | 认证相关响应头增加 `Cache-Control: no-store`（或 Nginx 针对 `/cloudchat/auth/*` 配置）                             | cloudchat/Nginx |           |     | 移除响应头或还原 Nginx 配置  |                     |
| 2025-08-13 | 新增 `ENABLE_SCHEDULER` 环境变量，为 0 则 Gunicorn worker 的 APScheduler 关闭；生产环境为 0，避免多实例重复执行      | cloudchat    |           |     | 恢复 Gunicorn 调度器配置     |                     |
| 2025-08-13 | 修正 `models.Session.ip` 类型与 `schema.sql` 对齐（INET），时间戳默认改用 `func.now()` 或 UTC-aware 时间             | cloudchat    |           |     | 恢复旧字段类型和默认值       |                     |
| 2026-06-12 | 修复 TLS 1.2 ECDSA cipher、安全头继承、`/_astro/` 长缓存、隐藏敏感路径 404 与 apex 到 www 301，并改为 Git pull 发布流程 | nginx        |           |     | 回滚对应 Git commit 后 `nginx -t && systemctl reload nginx` | |
| 2026-06-12 | 为 Astro 5.12 hydration inline scripts 补齐 CSP `script-src` SHA-256 hash allowlist，恢复前端交互脚本执行 | nginx        |           |     | 回滚对应 Git commit 后 `nginx -t && systemctl reload nginx` | |
| 2026-06-14 | 为首页 Chat Widget 补齐 CSP `frame-src 'self'` 与 `frame-ancestors 'self'`，恢复同源 `/deepseek_chat/` iframe 加载 | nginx        |           |     | 回滚对应 Git commit 后 `nginx -t && systemctl reload nginx` | |
