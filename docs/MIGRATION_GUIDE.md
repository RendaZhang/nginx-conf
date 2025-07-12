<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [🚚 迁移指南](#-%E8%BF%81%E7%A7%BB%E6%8C%87%E5%8D%97)
  - [简介](#%E7%AE%80%E4%BB%8B)
  - [示例服务器](#%E7%A4%BA%E4%BE%8B%E6%9C%8D%E5%8A%A1%E5%99%A8)
  - [迁移步骤](#%E8%BF%81%E7%A7%BB%E6%AD%A5%E9%AA%A4)
- [3. 安装证书 (手动操作，不上传至 Git)](#3-%E5%AE%89%E8%A3%85%E8%AF%81%E4%B9%A6-%E6%89%8B%E5%8A%A8%E6%93%8D%E4%BD%9C%E4%B8%8D%E4%B8%8A%E4%BC%A0%E8%87%B3-git)
- [将证书文件放入 /usr/local/nginx/conf/cert/](#%E5%B0%86%E8%AF%81%E4%B9%A6%E6%96%87%E4%BB%B6%E6%94%BE%E5%85%A5-usrlocalnginxconfcert)
- [确保文件名与配置中一致:](#%E7%A1%AE%E4%BF%9D%E6%96%87%E4%BB%B6%E5%90%8D%E4%B8%8E%E9%85%8D%E7%BD%AE%E4%B8%AD%E4%B8%80%E8%87%B4)
- [- rendazhang.com.pem](#--rendazhangcompem)
- [- rendazhang.com.key](#--rendazhangcomkey)
- [4. 部署静态网站](#4-%E9%83%A8%E7%BD%B2%E9%9D%99%E6%80%81%E7%BD%91%E7%AB%99)
- [5. 部署 Flask 后端 (Gunicorn + Gevent)](#5-%E9%83%A8%E7%BD%B2-flask-%E5%90%8E%E7%AB%AF-gunicorn--gevent)
- [假设 Flask 应用部署在 /opt/cloudchat](#%E5%81%87%E8%AE%BE-flask-%E5%BA%94%E7%94%A8%E9%83%A8%E7%BD%B2%E5%9C%A8-optcloudchat)
- [使用 systemd 管理服务:](#%E4%BD%BF%E7%94%A8-systemd-%E7%AE%A1%E7%90%86%E6%9C%8D%E5%8A%A1)
- [启动服务](#%E5%90%AF%E5%8A%A8%E6%9C%8D%E5%8A%A1)
- [6. 测试并重启 Nginx](#6-%E6%B5%8B%E8%AF%95%E5%B9%B6%E9%87%8D%E5%90%AF-nginx)
- [7. 快速检查内存使用](#7-%E5%BF%AB%E9%80%9F%E6%A3%80%E6%9F%A5%E5%86%85%E5%AD%98%E4%BD%BF%E7%94%A8)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 🚚 迁移指南

## 简介

本文的迁移目标服务器以 CentOS 7 为例。

## 示例服务器

1. **操作系统**:

- CentOS 7

2. **Nginx 版本**:

- 1.22+

3. **依赖组件**:

- Python 3.11+
- Flask 框架
- Gunicorn
- Gevent
- 开放的端口: 80 (HTTP), 443 (HTTPS)

4. **资源规格**:

- 最低: 1 vCPU, 1GB RAM, 20GB 存储
- 推荐: 2 vCPU, 2GB RAM, 40GB 存储

## 迁移步骤

```bash
# 1. 克隆配置仓库
git clone git@gitee.com:yourname/nginx-conf.git

# 2. 复制配置文件 (保留文件权限)
sudo cp -p nginx-conf/* /usr/local/nginx/conf/

## Debian/Ubuntu 目录结构
如果你在基于 Debian 或 Ubuntu 的系统上部署，请按如下方式处理配置：

```bash
sudo cp -p nginx-conf/nginx.conf /etc/nginx/nginx.conf
sudo cp -p nginx-conf/sites-available/rendazhang.conf /etc/nginx/sites-available/
sudo ln -s ../sites-available/rendazhang.conf /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
```


# 3. 安装证书 (手动操作，不上传至 Git)

# 将证书文件放入 /usr/local/nginx/conf/cert/

# 确保文件名与配置中一致:
#   - rendazhang.com.pem
#   - rendazhang.com.key

# 4. 部署静态网站
git clone git@gitee.com:yourname/rendazhang.git /usr/local/nginx/RendaZhang

# 5. 部署 Flask 后端 (Gunicorn + Gevent)

# 假设 Flask 应用部署在 /opt/cloudchat
sudo /opt/cloudchat/venv/bin/pip install gunicorn gevent

# 使用 systemd 管理服务:
sudo tee /etc/systemd/system/cloudchat.service > /dev/null <<EOF
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
Environment="REDIS_PASSWORD=***"
ExecStart=/opt/cloudchat/venv/bin/gunicorn --worker-class gevent --workers 2 --worker-connections 50 --max-requests 1000 --max-requests-jitter 50 --timeout 300 --bind 0.0.0.0:5000 app:app

Restart=always
RestartSec=3
KillSignal=SIGINT
ProtectSystem=full
PrivateTmp=true
NoNewPrivileges=true
OOMScoreAdjust=-100

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
sudo systemctl daemon-reload
sudo systemctl start cloudchat.service
sudo systemctl enable cloudchat.service

# 6. 测试并重启 Nginx
sudo nginx -t  # 验证配置
sudo systemctl restart nginx

# 7. 快速检查内存使用
free -h
```

## 验证迁移

1. 访问 `http://服务器IP` 应自动跳转至 `https://服务器IP`

2. 检查各功能页面:

- 主页面: `/index.html`
- 聊天功能: `/chat.html`

3. 验证后端服务:

```bash
curl -X POST https://DOMAIN_NAME/cloudchat/chat \
      -H "Content-Type: application/json" \
      -H "Referer: https://DOMAIN_NAME" \
      -d '{"message": "Hello from curl!"}'
```
