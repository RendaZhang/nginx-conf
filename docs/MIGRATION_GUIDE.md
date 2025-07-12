<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [🚚 迁移指南](#-%E8%BF%81%E7%A7%BB%E6%8C%87%E5%8D%97)
  - [简介](#%E7%AE%80%E4%BB%8B)
  - [示例服务器](#%E7%A4%BA%E4%BE%8B%E6%9C%8D%E5%8A%A1%E5%99%A8)
  - [迁移步骤](#%E8%BF%81%E7%A7%BB%E6%AD%A5%E9%AA%A4)
  - [验证迁移](#%E9%AA%8C%E8%AF%81%E8%BF%81%E7%A7%BB)

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
