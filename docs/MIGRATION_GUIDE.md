<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [迁移指南](#%E8%BF%81%E7%A7%BB%E6%8C%87%E5%8D%97)
  - [简介](#%E7%AE%80%E4%BB%8B)
    - [关键迁移变化](#%E5%85%B3%E9%94%AE%E8%BF%81%E7%A7%BB%E5%8F%98%E5%8C%96)
    - [示例目标服务器](#%E7%A4%BA%E4%BE%8B%E7%9B%AE%E6%A0%87%E6%9C%8D%E5%8A%A1%E5%99%A8)
      - [基础信息](#%E5%9F%BA%E7%A1%80%E4%BF%A1%E6%81%AF)
      - [服务矩阵](#%E6%9C%8D%E5%8A%A1%E7%9F%A9%E9%98%B5)
    - [关键目录结构和项目](#%E5%85%B3%E9%94%AE%E7%9B%AE%E5%BD%95%E7%BB%93%E6%9E%84%E5%92%8C%E9%A1%B9%E7%9B%AE)
      - [前端代码](#%E5%89%8D%E7%AB%AF%E4%BB%A3%E7%A0%81)
      - [后端代码](#%E5%90%8E%E7%AB%AF%E4%BB%A3%E7%A0%81)
      - [Nginx 配置](#nginx-%E9%85%8D%E7%BD%AE)
    - [迁移验证清单](#%E8%BF%81%E7%A7%BB%E9%AA%8C%E8%AF%81%E6%B8%85%E5%8D%95)
  - [迁移前准备](#%E8%BF%81%E7%A7%BB%E5%89%8D%E5%87%86%E5%A4%87)
    - [旧服务器（CentOS 7）备份](#%E6%97%A7%E6%9C%8D%E5%8A%A1%E5%99%A8centos-7%E5%A4%87%E4%BB%BD)
    - [新服务器准备](#%E6%96%B0%E6%9C%8D%E5%8A%A1%E5%99%A8%E5%87%86%E5%A4%87)
      - [基础配置](#%E5%9F%BA%E7%A1%80%E9%85%8D%E7%BD%AE)
      - [删除服务器的自带服务](#%E5%88%A0%E9%99%A4%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%9A%84%E8%87%AA%E5%B8%A6%E6%9C%8D%E5%8A%A1)
      - [检测其他不需要的后台程序](#%E6%A3%80%E6%B5%8B%E5%85%B6%E4%BB%96%E4%B8%8D%E9%9C%80%E8%A6%81%E7%9A%84%E5%90%8E%E5%8F%B0%E7%A8%8B%E5%BA%8F)
      - [安全建议](#%E5%AE%89%E5%85%A8%E5%BB%BA%E8%AE%AE)
      - [Ubuntu 24 设置交换空间](#ubuntu-24-%E8%AE%BE%E7%BD%AE%E4%BA%A4%E6%8D%A2%E7%A9%BA%E9%97%B4)
      - [精简系统服务（关键优化）](#%E7%B2%BE%E7%AE%80%E7%B3%BB%E7%BB%9F%E6%9C%8D%E5%8A%A1%E5%85%B3%E9%94%AE%E4%BC%98%E5%8C%96)
      - [优化内核参数](#%E4%BC%98%E5%8C%96%E5%86%85%E6%A0%B8%E5%8F%82%E6%95%B0)
      - [安装轻量化组件](#%E5%AE%89%E8%A3%85%E8%BD%BB%E9%87%8F%E5%8C%96%E7%BB%84%E4%BB%B6)
      - [配置 OOM Killer 优先级](#%E9%85%8D%E7%BD%AE-oom-killer-%E4%BC%98%E5%85%88%E7%BA%A7)
      - [维护建议](#%E7%BB%B4%E6%8A%A4%E5%BB%BA%E8%AE%AE)
  - [分模块迁移](#%E5%88%86%E6%A8%A1%E5%9D%97%E8%BF%81%E7%A7%BB)
    - [前端迁移](#%E5%89%8D%E7%AB%AF%E8%BF%81%E7%A7%BB)
    - [后端迁移](#%E5%90%8E%E7%AB%AF%E8%BF%81%E7%A7%BB)
      - [代码和环境](#%E4%BB%A3%E7%A0%81%E5%92%8C%E7%8E%AF%E5%A2%83)
      - [安装并配置 Redis](#%E5%AE%89%E8%A3%85%E5%B9%B6%E9%85%8D%E7%BD%AE-redis)
      - [配置 systemd 服务](#%E9%85%8D%E7%BD%AE-systemd-%E6%9C%8D%E5%8A%A1)
      - [验证和监控](#%E9%AA%8C%E8%AF%81%E5%92%8C%E7%9B%91%E6%8E%A7)
    - [Nginx 迁移](#nginx-%E8%BF%81%E7%A7%BB)
      - [安装和配置 Nginx](#%E5%AE%89%E8%A3%85%E5%92%8C%E9%85%8D%E7%BD%AE-nginx)
      - [目录与用户约定](#%E7%9B%AE%E5%BD%95%E4%B8%8E%E7%94%A8%E6%88%B7%E7%BA%A6%E5%AE%9A)
      - [SSL 证书证书自动化](#ssl-%E8%AF%81%E4%B9%A6%E8%AF%81%E4%B9%A6%E8%87%AA%E5%8A%A8%E5%8C%96)
      - [配置 OOM Killer 优先级](#%E9%85%8D%E7%BD%AE-oom-killer-%E4%BC%98%E5%85%88%E7%BA%A7-1)
  - [迁移完成后检查](#%E8%BF%81%E7%A7%BB%E5%AE%8C%E6%88%90%E5%90%8E%E6%A3%80%E6%9F%A5)
    - [检查 Nginx](#%E6%A3%80%E6%9F%A5-nginx)
      - [缓存管理](#%E7%BC%93%E5%AD%98%E7%AE%A1%E7%90%86)
    - [检查后端](#%E6%A3%80%E6%9F%A5%E5%90%8E%E7%AB%AF)
    - [检查前端](#%E6%A3%80%E6%9F%A5%E5%89%8D%E7%AB%AF)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 迁移指南

* **Last Updated:** July 14, 2025, 18:30 (UTC+8)
* **作者:** 张人大（Renda Zhang）

---

## 简介

本文档详细记录了从 **CentOS 7** 到 **Ubuntu 24.04 LTS** 的服务器迁移过程，特别针对轻量级个人网站 (www.rendazhang.com) 的优化部署。迁移核心目标是：

1. 保持服务零中断（通过 DNS TTL 调整实现平滑切换）
2. 适配 Ubuntu 24.04 新特性（systemd 资源限制、AppArmor 安全策略）
3. 优化 1GB 内存服务器的资源利用率
4. 解决 CentOS 到 Ubuntu 的配置差异问题（特别是 Nginx 动态模块）

### 关键迁移变化

| 组件         | CentOS 7 配置                 | Ubuntu 24.04 配置               | 注意事项                     |
|--------------|-------------------------------|--------------------------------|------------------------------|
| **运行用户** | `nginx`                       | `www-data`                      | 需检查文件权限               |
| **Nginx 路径** | `/usr/local/nginx`          | `/etc/nginx`                    | 配置目录结构变化             |
| **Python**   | 3.6 (系统自带)                | 3.12 (需 venv)                  | 虚拟环境必需                 |
| **服务管理** | `systemctl`                   | `systemd` with cgroup 限制      | 新增 MemoryMax 限制          |
| **防火墙**   | firewalld / ISP 自带的防火墙   | ufw / ISP 自带的防火墙           | 如果同一个 ISP 则不需要迁移   |
| **PURGE 模块**| 源码编译                      | `libnginx-mod-http-cache-purge` | 需版本匹配验证               |

### 示例目标服务器

#### 基础信息

* 操作系统: Ubuntu 24.04 LTS
* 地区: 香港
* ISP: 阿里云

参考命令：

```bash
# 系统信息
$ hostnamectl
  Operating System: Ubuntu 24.04 LTS
            Kernel: Linux 6.8.0-40-generic
      Architecture: x86-64

# 地区验证
$ curl -s ip-api.com/json | jq '.country + " - " + .isp'
"Hong Kong - Alibaba.com LLC"

# 云服务商验证
$ curl -s http://ip-api.com/json/$(curl -s ifconfig.me) | jq -r '.isp'
Alibaba.com LLC
```

#### 服务矩阵

| 服务        | 版本           | 端口     | 资源限制       |
|-------------|---------------|---------|----------------|
| Nginx       | 1.24.0        | 80/443  | 不设           |
| Redis       | 7.0.15        | 6379    | MemoryMax=256M |
| Python      | 3.12.3        | -       | -              |
| Flask       | 3.1.1         | -       | -              |
| Gunicorn    | 23.0.0        | 5000    | MemoryMax=600M |
| Gevent      | 25.5.1        | -       | -              |

> 资源规格推荐：**2 vCPU / 2GB RAM / 40GB 存储**（最小 1 vCPU / 1GB RAM / 20GB 存储）

参考命令：

```bash
# Nginx 版本
$ nginx -v
nginx version: nginx/1.24.0 (Ubuntu)

# Redis 版本
$ redis-cli --version
redis-cli 7.0.15

# Python 版本
$ python3 --version
Python 3.12.3

# Flask 框架
$ /opt/cloudchat/venv/bin/pip show flask | grep Version
Version: 3.1.1

# Gunicorn + Gevent
$ /opt/cloudchat/venv/bin/pip show Gunicorn | grep Version
Version: 23.0.0
$ /opt/cloudchat/venv/bin/pip show Gevent | grep Version
Version: 25.5.1

# 开放的端口
$ sudo nmap -sT -O localhost
...
PORT     STATE SERVICE
22/tcp   open  ssh
80/tcp   open  http
443/tcp  open  https
5000/tcp open  upnp
...
```

### 关键目录结构和项目

```tree
/
├── etc
│   ├── nginx/                   # Nginx 主配置
│   │   ├── sites-enabled/       # 虚拟主机配置
│   │   └── modules-enabled/     # 动态模块加载
│   └── redis/                   # Redis 配置
├── var
│   ├── www/rendazhang/          # 前端静态资源
│   └── cache/nginx/             # 代理缓存目录
└── opt
    └── cloudchat/               # 后端应用
        ├── venv/                # Python 虚拟环境
        └── app.py               # Flask 主程序
```

#### 前端代码

目录位置: `/var/www/rendazhang`

前端项目代码链接: 📁 [Renda Zhang Web](https://github.com/RendaZhang/rendazhang.github.io)

#### 后端代码

目录位置: `/opt/cloudchat`

后端项目代码链接: 📁 [Python Cloud Chat](https://github.com/RendaZhang/python-cloud-chat)

#### Nginx 配置

目录位置: `/etc/nginx`

Nginx 配置链接: 📁 [Nginx Conf](https://github.com/RendaZhang/nginx-conf)

### 迁移验证清单

1. [x] HTTPS 证书自动续期（Certbot）
2. [x] Redis 内存限制（maxmemory 64mb）
3. [x] Gunicorn 流式响应测试
4. [x] Nginx 缓存清除功能（PURGE）
5. [ ] 压力测试（siege -c 50）

---

## 迁移前准备

### 旧服务器（CentOS 7）备份

创建旧服务器的镜像和快照，作为备份。

对旧服务器相关信息进行备份

```bash
# 前端备份
tar -czvf frontend_backup.tar.gz /usr/local/nginx/RendaZhang

# 后端备份
tar -czvf backend_backup.tar.gz /opt/cloudchat

# Nginx 配置备份
tar -czvf nginx_conf_backup.tar.gz /usr/local/nginx/conf

# SSH 密钥备份
cp ~/.ssh/authorized_keys authorized_keys_backup
```

记录关键信息：
```bash
# 获取当前服务状态
systemctl status cloudchat.service
nginx -t && nginx -V
ps aux | grep gunicorn
free -h
df -h
```

### 新服务器准备

新服务器配置：2 vCPU / 1 GiB - ESSD 云盘 / 40 GiB - Ubuntu 24.04

#### 基础配置

配置远程 SSH 连接登录：

```bash
# 修改 存储 SSH 公钥的文件，加上从旧服务器备份的 SSH 密钥
vi ~/.ssh/authorized_keys
```

网络超时设置会导致 SSH 连接自动断开问题，可以按照下面的步骤进行设置修改。

1. SSH 服务端配置，打开 `/etc/ssh/sshd_config`，添加/修改以下参数：

    ```bash
    # 每 60 秒发送一次保活包
    ClientAliveInterval 60
    # 允许 3 次无响应才断开
    ClientAliveCountMax 3
    # 禁用 DNS 反查加速连接
    UseDNS no
    # 提高登录等待时间（小内存服务器响应慢）
    LoginGraceTime 120
    ```

2. 重启 SSH 服务：

    ```bash
    sudo systemctl restart ssh
    ```

3. 内核网络参数优化，打开 `/etc/sysctl.conf`，添加：

    ```bash
    # TCP 保活设置（单位：秒）
    net.ipv4.tcp_keepalive_time = 60
    net.ipv4.tcp_keepalive_intvl = 30
    net.ipv4.tcp_keepalive_probes = 3
    ```

4. 应用配置：

    ```bash
    sudo sysctl -p
    ```

如果端口是用云服务自带的防火墙管理的，比如阿里云的内置的虚拟防火墙功能，则直接修改即可，不需要额外配置比如 ufw 防火墙工具。如果使用了 ufw 防火墙工具，则需要做以下操作：

```bash
sudo ufw allow OpenSSH # 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 5000/tcp
sudo ufw --force enable
```

#### 删除服务器的自带服务

这里以阿里云服务为例子。

**重要提醒**：卸载后部分功能（如系统监控、安全告警）将不可用，确保你已通过其他方式（如自建监控）替代。

```bash
# 1. 卸载云监控插件

# 停止服务
sudo /usr/local/cloudmonitor/wrapper/bin/cloudmonitor.sh stop
# 卸载
sudo /usr/local/cloudmonitor/wrapper/bin/cloudmonitor.sh remove && \
sudo rm -rf /usr/local/cloudmonitor

# 2. 卸载安骑士（云安全中心）

# 下载卸载脚本
wget http://update.aegis.aliyun.com/download/uninstall.sh
# 执行卸载
chmod +x uninstall.sh
sudo ./uninstall.sh
# 清理残留
sudo rm -rf /usr/local/aegis*

# 3. 禁用阿里云默认监控服务（可选）

# 停止并禁用阿里云默认的监控服务
sudo systemctl stop CmsGoAgent.service
sudo systemctl disable CmsGoAgent.service
sudo rm -f /etc/systemd/system/CmsGoAgent.service

# 4. 深度清理

# 检查并删除如下的残留文件
/usr/local/cloudmonitor/  # 云监控残留
/usr/local/aegis/          # 安骑士残留
/etc/systemd/system/       # 检查是否有阿里云服务单元
# 清理安装包缓存：
sudo apt clean
# 自动删除不再需要的依赖包：
sudo apt autoremove

# 5. 卸载后重启，确认无异常进程
sudo reboot
```

#### 检测其他不需要的后台程序

```bash
# 1. 查看运行中的进程

# 按CPU排序
top
# 按内存排序（按 Shift+M）
htop

# 2. 检查系统服务

# 列出所有系统服务
systemctl list-unit-files --type=service --state=enabled
# 检查可疑服务
systemctl status <service-name>  # 替换为实际服务名

# 3. 检查定时任务

# 系统级定时任务
sudo ls /etc/cron.d/ /etc/cron.hourly/ /etc/cron.daily/
# 用户级定时任务
crontab -l  # 当前用户
sudo crontab -l -u root  # root用户

# 4. 检查网络连接

# 查看所有网络连接
sudo netstat -tulnp
# 检查外部连接（重点看ESTABLISHED状态）
sudo lsof -i -P -n | grep ESTABLISHED

# 5. 检查开机启动项

# 查看所有启动项
sudo systemctl list-unit-files --type=service | grep enabled
# 检查rc.local（老系统）
cat /etc/rc.local
```

#### 安全建议

```bash
# 若仍需监控，推荐轻量级方案：
# 安装Prometheus Node Exporter（监控基础指标）
docker run -d --name node-exporter -p 9100:9100 prom/node-exporter

# 可以根据实际情况，使用脚本定期检查新增进程：
# 保存当前进程快照
ps aux > /root/process_snapshot.txt
```

#### Ubuntu 24 设置交换空间

```bash
# 0. 如果目前使用的是 systemd-swap 服务管理交换，请先停止并禁用这个服务：
sudo systemctl status systemd-swap
sudo systemctl stop systemd-swap
sudo systemctl disable systemd-swap

# 1. 创建交换文件（推荐使用 dd 而非 fallocate，避免文件系统兼容问题）
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048  # 创建2GB交换文件

# 2. 设置权限（Ubuntu默认权限更严格）
sudo chmod 600 /swapfile

# 3. 格式化并启用（mkswap命令相同）
sudo mkswap /swapfile
sudo swapon /swapfile

# 4. 永久生效（fstab配置相同）
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 5. 优化 swappiness（记得删掉原来的 vm.swappiness）
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 6. 验证
sudo systemctl status swapfile.swap
free -h && swapon --show
```

#### 精简系统服务（关键优化）

禁用消耗内存的非必要服务：

```bash
sudo systemctl disable --now \
    apt-daily-upgrade.timer \
    apt-daily.timer \
    man-db.timer \
    fwupd-refresh.timer \
    apparmor \            # 仅当无安全合规要求时
    ModemManager \        # 服务器不需要调制解调器管理
    networkd-dispatcher   # 简单网络配置可禁用

# 检查状态
sudo systemctl status apt-daily-upgrade.timer apt-daily.timer man-db.timer fwupd-refresh.timer apparmor ModemManager networkd-dispatcher
```

如果你希望限制 `journald` 日志大小和存活时间（防止日志占满内存），

可以编辑 `/etc/systemd/journald.conf` 文件。

例如：

```bash
SystemMaxUse=100M  # 限制日志占用的最大磁盘空间为 100MB
MaxRetentionSec=7day  # 日志最多保留 7 天
```

修改后，重启 journald 服务：

```bash
sudo systemctl daemon-reload
sudo systemctl restart systemd-journald
```

#### 优化内核参数

编辑文件 `/etc/sysctl.conf`，修改以下配置:

```bash
# 减少内存开销
vm.dirty_ratio=10
vm.dirty_background_ratio=5
vm.overcommit_memory=1
# 减少TCP内存消耗
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.core.rmem_max=16777216
net.core.wmem_max=16777216
# 加快内存回收
vm.vfs_cache_pressure=50
```

生效命令：

```bash
sudo sysctl -p
```

#### 安装轻量化组件

替换内存消耗大的组件

```bash
# 替换 bash 作为系统脚本解释器
sudo apt install dash

# 轻量级 Unix 工具集
sudo apt install busybox

# 卸载非必要软件包
sudo apt purge --auto-remove snapd  # 占用大量内存
sudo apt purge --auto-remove unattended-upgrades
sudo apt purge --auto-remove command-not-found
```

#### 配置 OOM Killer 优先级

创建 `/etc/systemd/system/.include.conf`:

```bash
[Service]
OOMScoreAdjust=-100  # 保护关键服务不被优先杀死
```

应用配置（Redis 作为例子）：

```bash
sudo systemctl edit redis.service
```

新增内容：

```bash
# `.include.conf` 中已经定义了 `OOMScoreAdjust`，可以在服务的配置文件中引用它：
.include /etc/systemd/system/.include.conf
```

或者直接单独配置不使用引用的方式：

```bash
[Service]
OOMScoreAdjust=-100
```

载入新服务：

```bash
sudo systemctl daemon-reload
sudo systemctl restart redis
```

#### 维护建议

每周清理：

```bash
# 清理 journal 日志
sudo journalctl --vacuum-size=50M

# 清空 Nginx 的错误日志
sudo truncate -s 0 /var/log/nginx/error.log

# 清理安装包缓存
sudo apt clean && sudo rm -rf /var/cache/apt/*
# 自动删除不再需要的依赖包
sudo apt autoremove
```

如果有需要，可以使用内存限制器：

```bash
sudo apt install cgroup-tools
cgcreate -g memory:/limited_group
echo 500M > /sys/fs/cgroup/memory/limited_group/memory.limit_in_bytes

# 运行受限程序：
cgexec -g memory:limited_group your_command
```

---

## 分模块迁移

### 前端迁移

初始化静态站点 /var/www/rendazhang

```bash
sudo mkdir -p /var/www
cd /var/www/
git clone git@gitee.com:RendaZhang/RendaZhang.git
mv RendaZhang/ rendazhang/
```

### 后端迁移

#### 代码和环境

在对应的目录下，拉取最新的后端项目代码

```bash
cd /opt
git clone git@gitee.com:RendaZhang/python-cloud-chat.git
mv python-cloud-chat cloudchat
```

设置虚拟环境

```bash
cd /opt/cloudchat
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### 安装并配置 Redis

安装并启用 Redis

```bash
# 更新 apt 源 & 安装
sudo apt update && sudo apt install -y redis-server

# 启用并开机自启
sudo systemctl enable --now redis-server

# 先看版本（Ubuntu24.04 默认 7.x）
redis-server --version

# 检查 Redis 状态
sudo systemctl status redis
```

面向 1 GB RAM 的精简配置 - 编辑 `/etc/redis/redis.conf`（或 `/etc/redis/redis.conf.d/` 下的自定义文件），建议保留注释便于回溯：

```bash
############## 基础安全 ##############
# 仅本机访问，远程用 SSH 隧道
bind 127.0.0.1
protected-mode yes
requirepass YOUR_STRONG_PASSWORD

############## 内存占用 ##############
# 总内存 15-25%，可按需要调整
maxmemory 64mb
# 小内存下最优策略
maxmemory-policy allkeys-lru
# 可用 64 MB 起步；若后台模型占用大，可再降

############## 关闭持久化（极低内存/可丢数据场景） ##############
# 关闭 RDB 快照
save ""
# 关闭 AOF 日志
appendonly no
# 若仍想持久化，可改为 AOF everysec + 适当 maxmemory

############## 其他 ##############
# 碎片自动整理
activerehashing yes
# 连接少可再低
tcp-backlog 128
# 禁用空闲超时，长连接场景
timeout 0
```

为 redis-server 做 systemd 限制，防止占满内存

```bash
sudo systemctl edit redis.service

# 在弹出的 override.conf 中写入：

[Service]
# 虽然可杀，但是保护服务不被优先杀死
OOMScoreAdjust=-100
# 最多占 256 MB（含 fork 时的 copy-on-write）
MemoryMax=256M
```

重启并验证：

```bash
# 重启
sudo systemctl daemon-reload
sudo systemctl restart redis

# 如果没有设置密码可直接运行：
redis-cli info memory | grep maxmemory

# 如果设置了密码 (非安全示例)：
PWD=YOUR_STRONG_PASSWORD
redis-cli -a $PWD info memory | grep -E 'used_memory_human|maxmemory'

# 实时看内存 & 命中率
redis-cli -a $PWD info stats | grep -E '(instantaneous_ops_per_sec|keyspace_hits|keyspace_misses)'
redis-cli -a $PWD ping            # Pong
redis-cli -a $PWD monitor         # 实时监控
redis-cli -a $PWD flushdb         # 清空当前 DB
redis-cli -a $PWD dbsize          # 查看键数量
redis-cli -a $PWD memory stats    # 详细内存
```

#### 配置 systemd 服务

```bash
sudo tee /etc/systemd/system/cloudchat.service <<EOF
[Unit]
Description=CloudChat Flask App with Gunicorn
After=network.target redis-server.service

[Service]
User=root
WorkingDirectory=/opt/cloudchat
Environment="PATH=/opt/cloudchat/venv/bin"
Environment="DASHSCOPE_API_KEY=***"
Environment="DEEPSEEK_API_KEY=***"
Environment="OPENAI_API_KEY=***"
Environment="FLASK_SECRET_KEY=***"
Environment="REDIS_PASSWORD=YOUR_STRONG_PASSWORD"
ExecStart=/opt/cloudchat/venv/bin/gunicorn --worker-class gevent --workers 2 --worker-connections 50 --max-requests 1000 --max-requests-jitter 50 --timeout 300 --bind 0.0.0.0:5000 app:app

Restart=always
RestartSec=3
KillSignal=SIGINT
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=true
OOMScoreAdjust=-100
MemoryMax=600M

[Install]
WantedBy=multi-user.target
EOF
```

`OOMScoreAdjust=-100`: 跟 Redis 一个可杀优先级别。

`MemoryMax=600M`: 超过即 cgroup OOM, systemd 会重启。

启动服务

```
sudo systemctl daemon-reload
sudo systemctl enable cloudchat.service
sudo systemctl start cloudchat.service
```

#### 验证和监控

检查工作进程：

```bash
# 应该看到 1 个 master 进程和 2 个 worker 进程
ps aux | grep gunicorn
# 查看服务运行状态
sudo systemctl status cloudchat.service
sudo systemctl status cloudchat
# 查看应用动态日志
journalctl -u cloudchat.service -f
```

测试接口：

```bash
curl -X POST localhost:5000/chat \
      -H "Content-Type: application/json" \
      -d '{"message": "This is a Test from localhost"}'

# 预期输出（分段）：
{"text": "Hello"}
{"text": "!"}
{"text": " It"}
{"text": "'s"}
{"text": " great to hear from"}
{"text": " you. How can"}
{"text": " I assist you today"}
{"text": "? \ud83d\ude0a"}
```

压力测试（安装 `siege` 后）：

```bash
siege -c 10 -t 30s http://localhost:5000/deepseek_chat
```

内存监控：

```bash
htop
free -h
```

如果内存使用接近 90%：

- 减少 `--workers` 到 1
- 降低 `--worker-connections` 值

### Nginx 迁移

#### 安装和配置 Nginx

```bash
sudo apt update && sudo apt install -y \
  nginx            # 官方仓库自带 1.24+ 主程序
  nginx-core       # 基础模块
  libnginx-mod-http-cache-purge   # PURGE 动态模块 (= 旧源码里的 ngx_cache_purge)
  python3-certbot-nginx           # SSL 自动签发/续期
  ufw htop

# 启动 Nginx
sudo systemctl start nginx
```

因为 Ubuntu 24 安装 的 Nginx 会出现 PURGE 动态模块版本不一致问题，
所以需要额外重新编译相关模块才可以正常使用 PURGE 动态模块的功能。

如果需要重编译 ngx_cache_purge 模块，如下是可参考的操作步骤：

```bash
# 安装编译依赖
sudo apt update
sudo apt install -y build-essential libpcre3-dev zlib1g-dev libssl-dev git
sudo apt install -y libxslt-dev libgd-dev libgeoip-dev libperl-dev

# 获取当前 Nginx 版本和配置参数
NGINX_VERSION=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+')
NGINX_CONFIG=$(nginx -V 2>&1 | grep "configure arguments" | cut -d: -f2-)

echo "当前 Nginx 版本: $NGINX_VERSION"
echo "当前配置参数: $NGINX_CONFIG"

# 创建工作目录
mkdir ~/nginx-rebuild && cd ~/nginx-rebuild

# 下载匹配的 Nginx 源码
wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
tar zxvf nginx-$NGINX_VERSION.tar.gz

# 下载 cache_purge 模块
git clone https://github.com/nginx-modules/ngx_cache_purge.git

# 编译动态模块
cd nginx-$NGINX_VERSION
# 生成配置（添加 --with-compat 参数确保二进制兼容性）
eval "./configure $NGINX_CONFIG --with-compat --add-dynamic-module=../ngx_cache_purge"
# 因为 NGINX_CONFIG 的值的 --with-cc-opt 参数包含单引号，这里使用 eval 防止 -O2 选项被错误解析。

# 仅编译模块（不安装完整 Nginx）
make modules

# 确认生成的模块文件
find objs -name 'ngx_http_cache_purge_module.so'

# 备份旧模块
sudo cp /usr/lib/nginx/modules/ngx_http_cache_purge_module.so /usr/lib/nginx/modules/ngx_http_cache_purge_module.so.bak

# 复制新模块
sudo cp objs/ngx_http_cache_purge_module.so /usr/lib/nginx/modules/

# 设置正确权限
sudo chown root:root /usr/lib/nginx/modules/ngx_http_cache_purge_module.so
sudo chmod 644 /usr/lib/nginx/modules/ngx_http_cache_purge_module.so

# 测试配置
sudo nginx -t

# 查看加载的模块
sudo nginx -T 2>&1 | grep cache_purge

# 重启 Nginx
sudo systemctl daemon-reload
sudo systemctl restart nginx
```

* 备选方案：如果上述方法失败，可以尝试完整源码编译。

#### 目录与用户约定

配置 `user www-data` 后，需要确保 `/var/log/nginx`、`/var/www/rendazhang`、/`var/cache/nginx` 和 `/run/nginx.pid` 对 `www-data` 用户有足够的权限。

使用以下命令检查 Nginx 的关键目录的权限：

```bash
ls -ld /var/log/nginx /var/www/rendazhang /var/cache/nginx
```

检查日志文件目录：

```bash
# Nginx 需要写入日志文件。
# 确保 www-data 用户有写权限，如果没有，请执行如下操作：
sudo chown -R www-data:www-data /var/log/nginx
sudo chmod -R 755 /var/log/nginx
```

检查网站文件目录：

```bash
# Nginx 需要读取网站文件。
# 确保 www-data 用户有读权限，如果没有，请执行如下操作：
sudo chown -R www-data:www-data /var/www/rendazhang
sudo chmod -R 755 /var/www/rendazhang
```

检查缓存目录：

```bash
# Nginx 需要写入缓存文件。
# 启用缓存目录（如果不存在）：
sudo mkdir -p /var/cache/nginx
# 使用 Ubuntu 默认运行用户 www-data
sudo chown -R www-data:www-data /var/cache/nginx
```

#### SSL 证书证书自动化

Certbot 会自动改写 rendazhang.conf 中的 ssl_certificate 等行，且在 /etc/cron.d 添加续期任务。

```bash
# 暂停 Nginx
sudo systemctl stop nginx

# 申请证书（HTTP-01 验证，Certbot 自己监听 80）
sudo certbot certonly --standalone \
     --preferred-challenges http \
     -d rendazhang.com -d www.rendazhang.com

# 申请成功后，证书生成在：
#    /etc/letsencrypt/live/rendazhang.com/{fullchain.pem,privkey.pem}

# 查看 Certbot 的状态
sudo systemctl status certbot

# 查看 Certbot 日志
sudo tail -f /var/log/letsencrypt/letsencrypt.log
# 查找 Renewal 或 Cert not yet due for renewal 等关键词，确认证书续签是否成功。
# 如果有错误信息（如 Error 或 Failed），可以根据日志内容排查问题。

# 手动测试证书续签
sudo certbot renew --dry-run
# 如果需要立即续签证书，可以运行以下命令：
sudo certbot renew

# 查看已安装 SSL 证书的有效期：
sudo certbot certificates

# 检查 Certbot 定时任务
sudo systemctl list-timers

# 如果定时任务未启用，可以手动启用：
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# 通过 `certbot.timer` 服务，系统会定期尝试续签证书。
# 可使用以下命令检查状态：
sudo systemctl status certbot.timer

# 重新加载 Nginx 配置：
sudo systemctl reload nginx

# 查看 Nginx 状态：
sudo systemctl status nginx
```

#### 配置 OOM Killer 优先级

给 Nginx 一个适中保护值，让系统尽量保住入口服务，而不是提前杀掉。

```bash
sudo systemctl edit nginx.service

# 在弹出的 override.conf 中写入：

[Service]
OOMScoreAdjust=-200
```

这里 Nginx 的 优先级需要比 redis.service 和 cloudchat.service 要高，让 Nginx master 最后才被杀。

重启服务：

```bash
sudo systemctl daemon-reload
sudo systemctl restart nginx
```

---

## 迁移完成后检查

### 检查 Nginx

```bash
# 查看 Nginx 状态
sudo systemctl status nginx

# 检查
sudo nginx -t && curl -I https://www.rendazhang.com

# Nginx 配置检查
nginx -t

# 检查 Nginx 错误
tail -f /var/log/nginx/error.log

# 检查 Nginx 访问日志
tail -f /var/log/nginx/access.log

# 重启 Nginx
sudo systemctl daemon-reload
sudo systemctl restart nginx
```

#### 缓存管理

检查 Nginx 缓存是否生效：

```bash
# 检查 x-cache-status: 是 HIT 或 MISS
# 根据配置的 `proxy_cache_min_uses x` 的值，会在第 x + 1 次看到 HIT。
curl -I https://www.rendazhang.com/cloudchat/test

# 如果出现 `curl: (52) Empty reply from server` 错误，可能是版本不兼容问题，Nginx 需要重新编译 nginx-module-cache-purge 模块

# 在缓存生效后，测试 purge-cache 的清除缓存功能
curl -X PURGE http://localhost/cloudchat/purge-cache/www.rendazhang.com/cloudchat/test
# 再次检查 x-cache-status 会变为 MISS

# 手动查看缓存目录
ls -al /var/cache/nginx

# 直接手动清理缓存目录
rm -rf /var/cache/nginx/*

# 如果需要远程调用，可在 `location ~ /cloudchat/purge-cache/(.*)` 中增加 `allow <你的IP>;` 或配置 Basic Auth，再重新加载 Nginx。
```

### 检查后端

从另外一台设备远程验证后端服务：

```bash
curl -X POST https://www.rendazhang.com/cloudchat/chat \
      -H "Content-Type: application/json" \
      -d '{"message": "This is a Test from Remote Server"}'
```

检查：

```bash
# 查看服务运行状态
sudo systemctl status cloudchat.service
sudo systemctl status cloudchat

# 检查 Flask 日志
journalctl -u cloudchat.service -f
```

### 检查前端

* 访问 `http://www.rendazhang.com` 应自动跳转至 `https://www.rendazhang.com`
* 检查各功能页面，比如通过浏览器访问主页面，使用与 AI 聊天的功能看看有没有问题。
